.pragma library

// Fuzzy-ish score of `query` against `text` (both lowercase). 0 = no match.
function score(query, text) {
    if (!text) return 0;
    if (text === query) return 1000;
    if (text.startsWith(query)) return 800 - text.length;
    const words = text.split(/[\s\-_.]+/);
    if (words.some(w => w.startsWith(query))) return 600 - text.length;
    const i = text.indexOf(query);
    if (i >= 0) return 400 - i;
    // subsequence: every query char appears in order (too noisy for short queries)
    if (query.length < 4) return 0;
    let pos = -1, gaps = 0;
    for (const c of query) {
        const n = text.indexOf(c, pos + 1);
        if (n < 0) return 0;
        gaps += n - pos - 1;
        pos = n;
    }
    return Math.max(1, 200 - gaps * 4);
}

// Turkish-aware lowercase so "İ"/"I" match "i"/"ı" typed either way.
function fold(s) {
    return (s || "").toLocaleLowerCase("tr-TR")
        .replace(/ı/g, "i").replace(/ş/g, "s").replace(/ğ/g, "g")
        .replace(/ü/g, "u").replace(/ö/g, "o").replace(/ç/g, "c");
}

function fileIcon(path) {
    const ext = (path.split(".").pop() || "").toLowerCase();
    if (["png", "jpg", "jpeg", "webp", "gif", "svg", "avif", "heic"].includes(ext)) return "image";
    if (["mp4", "mkv", "webm", "mov", "avi"].includes(ext)) return "movie";
    if (["mp3", "flac", "ogg", "wav", "m4a", "opus"].includes(ext)) return "music_note";
    if (ext === "pdf") return "picture_as_pdf";
    if (["zip", "tar", "gz", "xz", "7z", "rar", "zst"].includes(ext)) return "folder_zip";
    if (["md", "txt", "doc", "docx", "odt", "rtf"].includes(ext)) return "description";
    if (["xls", "xlsx", "ods", "csv"].includes(ext)) return "table";
    return "draft";
}

function clock(seconds) {
    const s = Math.floor(seconds);
    const h = Math.floor(s / 3600), m = Math.floor(s / 60) % 60, r = s % 60;
    return (h > 0 ? h + ":" + String(m).padStart(2, "0") : m) + ":" + String(r).padStart(2, "0");
}
