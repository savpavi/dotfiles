#!/bin/sh
# Copied from the claudeUsage DMS plugin (MIT, (c) 2026 Bogdan Velicu).
# Query the Claude OAuth usage endpoint using whatever local Claude credentials
# are available, normalize the response, write it to the cache, and print it.
#
# Zero setup: reads the OAuth access token that a Claude client already keeps on
# disk. It checks every known client (Claude Code and OpenCode), prefers a token
# that has not expired, and tries the freshest first — so the widget stays fresh
# as long as you use ANY Claude client, not only Claude Code. (Each client
# refreshes only its own token, and only while it runs; relying on a single one
# meant the data froze whenever you switched tools.) Tokens never leave the
# machine except in the request to api.anthropic.com — the same place the
# clients themselves send them.
#
# Env:
#   CACHE_FILE                cache path (default $XDG_CACHE_HOME/dms-claude-usage.json)
#   CLAUDE_CREDS              Claude Code credentials (default ~/.claude/.credentials.json)
#   OPENCODE_AUTH             OpenCode auth (default $XDG_DATA_HOME/opencode/auth.json)
#   CLAUDE_USAGE_MOCK         file with a sample API response (skips network; for tests)
#   CLAUDE_USAGE_LIST_SOURCES print the credential try-order and exit (for tests)
#
# Exit: 0 ok, 1 no/invalid credentials, 2 network/parse error.
set -u

TAB=$(printf '\t')
cache="${CACHE_FILE:-${XDG_CACHE_HOME:-$HOME/.cache}/dms-claude-usage.json}"
mkdir -p "$(dirname "$cache")" 2>/dev/null
now=$(date +%s)
now_ms=$((now * 1000))

cc_cred="${CLAUDE_CREDS:-$HOME/.claude/.credentials.json}"
oc_cred="${OPENCODE_AUTH:-${XDG_DATA_HOME:-$HOME/.local/share}/opencode/auth.json}"

work=$(mktemp -d) || exit 2
trap 'rm -rf "$work"' EXIT INT TERM

# Append "expiry<TAB>token<TAB>label" for a source if it yields an access token.
# $1 file, $2 jq expr emitting "expiry\ttoken" (or nothing), $3 label.
emit() {
  [ -f "$1" ] || return 0
  pair=$(jq -r "$2" "$1" 2>/dev/null)
  [ -n "$pair" ] || return 0
  printf '%s\t%s\n' "$pair" "$3" >> "$work/cands"
}

# Collect candidates, then order them: non-expired first (freshest expiry first),
# expired ones after as a best-effort fallback. Writes $work/ordered.
collect() {
  : > "$work/cands"
  emit "$cc_cred" \
    'if .claudeAiOauth.accessToken then "\(.claudeAiOauth.expiresAt // 0)\t\(.claudeAiOauth.accessToken)" else empty end' \
    claude-code
  emit "$oc_cred" \
    'if (.anthropic.type == "oauth" and .anthropic.access) then "\(.anthropic.expires // 0)\t\(.anthropic.access)" else empty end' \
    opencode
  awk -F"$TAB" -v now="$now_ms" '{v=($1+0>now)?0:1; print v FS $0}' "$work/cands" \
    | sort -t"$TAB" -k1,1n -k2,2nr \
    | cut -f2- > "$work/ordered"
}

if [ -n "${CLAUDE_USAGE_MOCK:-}" ]; then
  resp=$(cat "$CLAUDE_USAGE_MOCK")
else
  collect

  # Diagnostic: print "<label>\t<valid|expired>" per candidate, in try-order.
  if [ -n "${CLAUDE_USAGE_LIST_SOURCES:-}" ]; then
    [ -s "$work/ordered" ] || exit 1
    while IFS="$TAB" read -r exp tok label; do
      case "$exp" in ''|*[!0-9]*) exp=0 ;; esac
      [ "$exp" -gt "$now_ms" ] && state=valid || state=expired
      printf '%s\t%s\n' "$label" "$state"
    done < "$work/ordered"
    exit 0
  fi

  # Reuse a recent cache so multiple monitors don't each hit the rate-limited endpoint.
  if [ -s "$cache" ]; then
    prev=$(jq -r '.captured_at // 0' "$cache" 2>/dev/null)
    case "$prev" in ''|*[!0-9]*) prev=0 ;; esac
    if [ "$prev" -gt 0 ] && [ $((now - prev)) -lt 150 ]; then
      cat "$cache"
      exit 0
    fi
  fi

  [ -s "$work/ordered" ] || exit 1   # no usable credentials anywhere

  ver=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  resp=""
  while IFS="$TAB" read -r exp tok label; do
    [ -n "$tok" ] || continue
    body=$(curl -s -m 10 \
      -H "Authorization: Bearer $tok" \
      -H "anthropic-beta: oauth-2025-04-20" \
      -H "User-Agent: claude-code/${ver:-2.1.0}" \
      https://api.anthropic.com/api/oauth/usage 2>/dev/null)
    if echo "$body" | jq -e 'type == "object" and has("five_hour")' >/dev/null 2>&1; then
      resp=$body
      break
    fi
  done < "$work/ordered"
  [ -n "$resp" ] || exit 2          # had credentials, but every token was rejected
fi

# A valid usage response is an object with a five_hour block (error bodies aren't).
echo "$resp" | jq -e 'type == "object" and has("five_hour")' >/dev/null 2>&1 || exit 2

out=$(echo "$resp" | jq --argjson now "$now" '
  def epoch(s): s | sub("\\.[0-9]+"; "") | sub("(Z|[+-][0-9]{2}:?[0-9]{2})$"; "")
                  | strptime("%Y-%m-%dT%H:%M:%S") | mktime;
  def norm(b): if b == null then null
               else {used_percentage: (b.utilization | floor), resets_at: epoch(b.resets_at)} end;
  {captured_at: $now, five_hour: norm(.five_hour), seven_day: norm(.seven_day)}
') || exit 2

tmp="$cache.tmp.$$"
printf '%s' "$out" > "$tmp" && mv -f "$tmp" "$cache"
printf '%s' "$out"
