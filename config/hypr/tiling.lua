-- Pencere/calisma alani kisayollari — omarchy quattro `bindings/tiling.lua`
-- uyarlamasi. **Yalnizca mevcut bind'lerle CAKISMAYAN** kisim alindi.
--
-- Alinmayanlar ve nedeni:
--   SUPER+W (kapat)      -> sende Windows VM
--   SUPER+T (float)      -> sende Telegram
--   SUPER+S (scratchpad) -> sende Spotify; yerine SUPER+grave kullaniliyor
--   SUPER+L (layout)     -> sende ekran kilidi (savpavi-shell)
--   SUPER+O (pop out)    -> sende Obsidian
--   SUPER+F/J/P          -> sende zaten ayni islevde
--   SUPER+CTRL+ok        -> sende 40px boyutlandirma
--   omarchy-hyprland-* cagiran 8 satir (tiled fullscreen, pencere genisligi
--   kaydet/geri yukle, monitor olcekleme, tumunu kapat) -> script yok

------------------------------------------------------------
-- Pencere gruplari (sekmeli pencere)
------------------------------------------------------------

hl.bind("SUPER + G",       hl.dsp.group.toggle())  -- Pencere grubu (sekme) aç/kapat
hl.bind("SUPER + ALT + G", hl.dsp.window.move({ out_of_group = true }))  -- Pencereyi gruptan çıkar

-- Pencereyi komsu gruba tasi
hl.bind("SUPER + ALT + left",  hl.dsp.window.move({ into_group = "l" }))  -- Pencereyi soldaki gruba kat
hl.bind("SUPER + ALT + right", hl.dsp.window.move({ into_group = "r" }))  -- Pencereyi sağdaki gruba kat
hl.bind("SUPER + ALT + up",    hl.dsp.window.move({ into_group = "u" }))  -- Pencereyi üstteki gruba kat
hl.bind("SUPER + ALT + down",  hl.dsp.window.move({ into_group = "d" }))  -- Pencereyi alttaki gruba kat

-- Grup icinde gezinme
hl.bind("SUPER + ALT + TAB",         hl.dsp.group.next())  -- Gruptaki sonraki sekme
hl.bind("SUPER + ALT + SHIFT + TAB", hl.dsp.group.prev())  -- Gruptaki önceki sekme
hl.bind("SUPER + ALT + mouse_down",  hl.dsp.group.next())  -- Gruptaki sonraki sekme
hl.bind("SUPER + ALT + mouse_up",    hl.dsp.group.prev())  -- Gruptaki önceki sekme

-- Dogrudan sekmeye atla (SUPER+ALT+1..5)
for index = 1, 5 do
    hl.bind("SUPER + ALT + code:" .. tostring(index + 9), hl.dsp.group.active({ index = index }))  -- Gruptaki sekmeye atla (1-5)
end

------------------------------------------------------------
-- Scratchpad
------------------------------------------------------------
-- Ozel calisma alani: hep acik duran yardimci pencere icin.
-- Sendeki special:minimized'dan ayri, o "pencereyi kaldir" icin.

hl.bind("SUPER + grave",         hl.dsp.workspace.toggle_special("scratchpad"))  -- Scratchpad göster/gizle
hl.bind("SUPER + SHIFT + grave", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))  -- Pencereyi scratchpad'e at

------------------------------------------------------------
-- Pencere dongusu
------------------------------------------------------------

hl.bind("ALT + TAB",         hl.dsp.window.cycle_next())  -- Sonraki pencere
hl.bind("ALT + TAB",         hl.dsp.window.bring_to_top())  -- Sonraki pencere
hl.bind("ALT + SHIFT + TAB", hl.dsp.window.cycle_next({ next = false }))  -- Önceki pencere
hl.bind("ALT + SHIFT + TAB", hl.dsp.window.bring_to_top())  -- Önceki pencere

------------------------------------------------------------
-- Calisma alani ve monitor
------------------------------------------------------------

hl.bind("SUPER + TAB",         hl.dsp.focus({ workspace = "e+1" }))  -- Sonraki dolu çalışma alanı
hl.bind("SUPER + SHIFT + TAB", hl.dsp.focus({ workspace = "e-1" }))  -- Önceki dolu çalışma alanı
hl.bind("SUPER + CTRL + TAB",  hl.dsp.focus({ workspace = "previous" }))  -- Son çalışma alanına dön

hl.bind("CTRL + ALT + TAB",         hl.dsp.focus({ monitor = "+1" }))  -- Sonraki ekrana odaklan
hl.bind("CTRL + ALT + SHIFT + TAB", hl.dsp.focus({ monitor = "-1" }))  -- Önceki ekrana odaklan

-- Calisma alanini komsu monitore tasi (cift monitorde ise yarar)
hl.bind("SUPER + SHIFT + ALT + left",  hl.dsp.workspace.move({ monitor = "l" }))  -- Çalışma alanını sol ekrana taşı
hl.bind("SUPER + SHIFT + ALT + right", hl.dsp.workspace.move({ monitor = "r" }))  -- Çalışma alanını sağ ekrana taşı
hl.bind("SUPER + SHIFT + ALT + up",    hl.dsp.workspace.move({ monitor = "u" }))  -- Çalışma alanını üst ekrana taşı
hl.bind("SUPER + SHIFT + ALT + down",  hl.dsp.workspace.move({ monitor = "d" }))  -- Çalışma alanını alt ekrana taşı

------------------------------------------------------------
-- Klavyeyle boyutlandirma, 3 kademe
------------------------------------------------------------
-- code:20 = "-", code:21 = "="  (mevcut SUPER+CTRL+ok 40px'e dokunulmadi)
--   duz        : 100 px
--   ALT        :  25 px
--   CTRL       : 300 px
--   +SHIFT     : dikey eksen

hl.bind("SUPER + code:20", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))  -- Pencereyi daralt
hl.bind("SUPER + code:21", hl.dsp.window.resize({ x =  100, y = 0, relative = true }))  -- Pencereyi genişlet
hl.bind("SUPER + SHIFT + code:20", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))  -- Pencereyi kısalt
hl.bind("SUPER + SHIFT + code:21", hl.dsp.window.resize({ x = 0, y =  100, relative = true }))  -- Pencereyi uzat

hl.bind("SUPER + ALT + code:20", hl.dsp.window.resize({ x = -25, y = 0, relative = true }))  -- Pencereyi biraz daralt
hl.bind("SUPER + ALT + code:21", hl.dsp.window.resize({ x =  25, y = 0, relative = true }))  -- Pencereyi biraz genişlet
hl.bind("SUPER + SHIFT + ALT + code:20", hl.dsp.window.resize({ x = 0, y = -25, relative = true }))  -- Pencereyi biraz kısalt
hl.bind("SUPER + SHIFT + ALT + code:21", hl.dsp.window.resize({ x = 0, y =  25, relative = true }))  -- Pencereyi biraz uzat

hl.bind("SUPER + CTRL + code:20", hl.dsp.window.resize({ x = -300, y = 0, relative = true }))  -- Pencereyi çok daralt
hl.bind("SUPER + CTRL + code:21", hl.dsp.window.resize({ x =  300, y = 0, relative = true }))  -- Pencereyi çok genişlet
hl.bind("SUPER + CTRL + SHIFT + code:20", hl.dsp.window.resize({ x = 0, y = -300, relative = true }))  -- Pencereyi çok kısalt
hl.bind("SUPER + CTRL + SHIFT + code:21", hl.dsp.window.resize({ x = 0, y =  300, relative = true }))  -- Pencereyi çok uzat
