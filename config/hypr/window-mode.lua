-- Varsayilan: serbest pencereler. Super+M: yalniz etkin alani dose/serbest birak.
-- Hyprland 0.56 Lua API; harici eklenti veya arka plan sureci gerektirmez.
local tiled = {}

local function usable(w)
    return w.mapped and not w.hidden and not w.pinned and w.class ~= "xwaylandvideobridge"
end

local function active_workspace()
    return hl.get_active_special_workspace() or hl.get_active_workspace()
end

local function apply_mode(w, ws)
    if not ws or ws.special or not usable(w) then return end
    local should_float = not tiled[ws.id]
    if w.floating ~= should_float then
        hl.dispatch(hl.dsp.window.float({ window = w, action = should_float and "set" or "unset" }))
    end
end

hl.window_rule({ name = "personal-default-floating", match = { class = ".*" }, float = true })

-- Yeni pencere ve diger ekrandan gelen pencere hedef alanin duzenine uyar.
hl.on("window.open", function(w) apply_mode(w, w.workspace) end)
hl.on("window.move_to_workspace", function(w, ws) apply_mode(w, ws) end)

-- Config reload sirasinda dolu alanlarin mevcut duzenini koru.
hl.on("config.reloaded", function()
    for _, ws in ipairs(hl.get_workspaces()) do
        for _, w in ipairs(ws:get_windows()) do
            if usable(w) and not w.floating then tiled[ws.id] = true end
        end
    end
end)

hl.bind("SUPER + M", function()
    local ws = active_workspace()
    if not ws then return end
    tiled[ws.id] = not tiled[ws.id]
    for _, w in ipairs(ws:get_windows()) do
        if usable(w) then
            -- Buyutulmus pencere digerlerini kapatmasin; sonra hepsini dose.
            if w.fullscreen ~= 0 then
                hl.dispatch(hl.dsp.window.fullscreen_state({ window = w, internal = 0, client = 0, action = "set" }))
            end
            hl.dispatch(hl.dsp.window.float({ window = w, action = tiled[ws.id] and "unset" or "set" }))
        end
    end
end)

local function workspace_base()
    local ws = hl.get_active_workspace()
    local monitor = ws and ws.monitor
    if monitor and (monitor.name == "DP-3" or monitor.description:find("LG ULTRAGEAR", 1, true)) then
        return 10
    end
    return 0
end

for i = 1, 9 do
    local index = i
    hl.bind("SUPER + " .. index, function()
        hl.dispatch(hl.dsp.focus({ workspace = workspace_base() + index }))
    end)
    hl.bind("SUPER + SHIFT + " .. index, function()
        hl.dispatch(hl.dsp.window.move({ workspace = workspace_base() + index, follow = false }))
    end)
end

local function cycle_workspace(delta)
    local ws = hl.get_active_workspace()
    if not ws then return end
    local base = workspace_base()
    local index = ((ws.id - base - 1 + delta) % 9) + 1
    hl.dispatch(hl.dsp.focus({ workspace = base + index }))
end

hl.bind("SUPER + mouse_down", function() cycle_workspace(1) end)
hl.bind("SUPER + mouse_up", function() cycle_workspace(-1) end)
