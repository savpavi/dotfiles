-- Pencere kuralları — omarchy quattro `default/hypr/windows.lua` uyarlaması.
-- omarchy'nin `o.window()` yardımcısı `hl.window_rule()` üzerine ince bir sarmalayıcı;
-- burada doğrudan `hl.window_rule` kullanıldı.
--
-- Not: omarchy'deki "suppress maximize" ve "XWayland sürükleme düzeltmesi"
-- kuralları hyprland.lua'da zaten vardı, tekrarlanmadı.

------------------------------------------------------------
-- Varsayılan saydamlık
------------------------------------------------------------
-- Her pencere önce etiketlenir; saydam istemeyen uygulamalar aşağıda
-- etiketi bırakır; en sonda etiketi kalanlara opaklık uygulanır.
-- Sıra önemli: etiket kaldırma kuralları opaklık kuralından ÖNCE gelmeli.

hl.window_rule({
    name  = "default-opacity-tag",
    match = { class = ".*" },
    tag   = "+default-opacity",
})

-- Saydamlık istemeyenler: piksel doğruluğu ya da video önemli olanlar
for _, class in ipairs({
    "looking-glass-client",   -- Win11 VM, birebir görüntü şart
    "mpv",                    -- video
    "steam.*",                -- oyun kütüphanesi ve oyunlar
    "vlc",
    "org.kde.gwenview",
    "com.obsproject.Studio",
}) do
    hl.window_rule({
        match   = { class = class },
        tag     = "-default-opacity",
        opacity = "1 1",
    })
end

-- Tam ekran hiçbir zaman kısılmasın
hl.window_rule({
    name    = "fullscreen-opaque",
    match   = { fullscreen = true },
    tag     = "-default-opacity",
    opacity = "1 1",
})

hl.window_rule({
    name    = "default-opacity",
    match   = { tag = "default-opacity" },
    opacity = "0.985 0.96",
})

------------------------------------------------------------
-- Picture-in-Picture (omarchy default/hypr/apps/pip.lua)
------------------------------------------------------------
-- Tarayıcı PiP penceresi: yüzer, sabitlenir, sağ üste oturur.

hl.window_rule({
    name  = "pip-tag",
    match = { title = "(Picture.?in.?[Pp]icture)" },
    tag   = "+pip",
})

hl.window_rule({
    name              = "pip",
    match             = { tag = "pip" },
    tag               = "-default-opacity",
    float             = true,
    pin               = true,
    size              = { 600, 338 },
    keep_aspect_ratio = true,
    border_size       = 0,
    opacity           = "1 1",
    move              = { "(monitor_w-window_w-40)", "(monitor_h*0.04)" },
})
