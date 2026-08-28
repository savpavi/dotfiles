-- end-4/dots-hyprland'dan seçilerek alınan parçalar (28.08.2026).
-- Kaynak: dots/.config/hypr/hyprland/{keybinds,rules,env}.lua (commit 97c5bc6).
-- Quickshell kabuğu ALINMADI; yalnızca kabuktan bağımsız kurallar/bind'lar.

------------------------------------------------------------
-- Ortam
------------------------------------------------------------
-- Electron uygulamaları (Spotify, Discord flatpak vb.) XWayland yerine native Wayland.
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

------------------------------------------------------------
-- Pencere kuralları
------------------------------------------------------------
-- Dosya seçici / kaydet diyalogları: yüzer + ortada (tile'a düşmesin)
for _, t in ipairs({
    "^(Open File)(.*)$", "^(Select a File)(.*)$", "^(Open Folder)(.*)$",
    "^(Save As)(.*)$", "^(File Upload)(.*)$", "^(Library)(.*)$",
    "^(.*)(wants to save)$", "^(.*)(wants to open)$",
}) do
    hl.window_rule({ match = { title = t }, float = true, center = true })
end

-- Ses/ağ küçük araçları yüzer
for _, c in ipairs({ "^(pavucontrol)$", "^(org.pulseaudio.pavucontrol)$", "^(nm-connection-editor)$" }) do
    hl.window_rule({ match = { class = c }, float = true, center = true,
        size = { "(monitor_w*0.45)", "(monitor_h*0.45)" } })
end

-- "X is sharing your screen" çubuğu (Discord/Meet): yüzer, sabit, alt orta
hl.window_rule({
    name  = "screen-share-indicator",
    match = { title = ".*is sharing (a window|your screen).*" },
    float = true, pin = true,
    move  = { "(monitor_w*.5-window_w*.5)", "(monitor_h-window_h-12)" },
})

-- Oyunlar: tearing'e izin ver (general.allow_tearing = true ile birlikte çalışır)
hl.window_rule({ match = { class = "^(steam_app).*" }, immediate = true })
hl.window_rule({ match = { title = ".*\\.exe" },       immediate = true })

-- Tile pencerelere gölge gereksiz (yalnızca yüzenlerde kalsın)
hl.window_rule({ match = { float = 0 }, no_shadow = true })

------------------------------------------------------------
-- Kısayollar
------------------------------------------------------------
-- ALT+F4: Hyprland'de pencere kapatmaz; yanlışlıkla basınca hatırlat.
-- non_consuming: tuş uygulamaya da gider (Looking Glass içindeki Windows'ta çalışmaya devam eder).
hl.bind("ALT + F4", function()
    hl.exec_cmd("notify-send -a Hyprland 'ALT+F4 burada kapatmaz' 'SUPER+C ile kapat. ALT+F4 yalnızca Windows VM içinde.'")
end, { non_consuming = true })

hl.bind("SUPER + SHIFT + P", hl.dsp.window.pin(),                                            { description = "Pencere: sabitle (her workspace'te görünür)" })
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), { description = "Pencere: maximize (bar görünür kalır)" })

-- Bölme oranı. TR düzeninde ; ve ' keysym'i değiştiği için keycode kullanıldı
-- (code:47 = US ';' / TR 'ş', code:48 = US ''' / TR 'i').
hl.bind("SUPER + code:47", hl.dsp.layout("splitratio -0.1"), { repeating = true, description = "Bölme oranı -" })
hl.bind("SUPER + code:48", hl.dsp.layout("splitratio +0.1"), { repeating = true, description = "Bölme oranı +" })

-- Ekran yakınlaştırma (erişilebilirlik). Numpad -/+ (code:82/86), SUPER+KP_* sıfırlar.
local function zoom(delta)
    local z = hl.get_config("cursor:zoom_factor") + delta
    if z > 3.0 then z = 3.0 elseif z < 1.0 then z = 1.0 end
    hl.config({ cursor = { zoom_factor = z } })
end
hl.bind("SUPER + code:82", function() zoom(-0.3) end, { repeating = true, description = "Zoom -" })
hl.bind("SUPER + code:86", function() zoom(0.3)  end, { repeating = true, description = "Zoom +" })
hl.bind("SUPER + code:63", function() hl.config({ cursor = { zoom_factor = 1.0 } }) end, { description = "Zoom sıfırla" })

-- OCR ve ekran kaydı (scriptler ~/dotfiles/bin)
hl.bind("SUPER + SHIFT + X", hl.dsp.exec_cmd("$HOME/dotfiles/bin/dot-ocr"),                       { description = "OCR: bölge → metin panoya" })
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("$HOME/dotfiles/bin/dot-record"),                    { locked = true, description = "Kayıt: bölge (tekrar = durdur)" })
hl.bind("CTRL + ALT + R",    hl.dsp.exec_cmd("$HOME/dotfiles/bin/dot-record --fullscreen"),       { locked = true, description = "Kayıt: tam ekran" })
hl.bind("SUPER + SHIFT + ALT + R", hl.dsp.exec_cmd("$HOME/dotfiles/bin/dot-record --fullscreen --sound"), { locked = true, description = "Kayıt: tam ekran + ses" })
