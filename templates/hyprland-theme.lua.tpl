-- dot-theme tarafından üretildi — elle düzenleme.
-- hyprland.lua'nın sonundaki require("hyprland-theme") ile yüklenir ve
-- yukarıdaki general.col ayarlarını ezer.
local active_border_color = { colors = { "rgba({{ accent_strip }}ff)", "rgba({{ magenta_strip }}ff)" }, angle = 45 }
local inactive_border_color = "rgba({{ selection_strip }}cc)"

hl.config({
  general = {
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },
  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },
})
