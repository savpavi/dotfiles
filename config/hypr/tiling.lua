-- Pencere/calisma alani kisayollari — omarchy quattro `bindings/tiling.lua`
-- uyarlamasi. **Yalnizca mevcut bind'lerle CAKISMAYAN** kisim alindi.
--
-- Alinmayanlar ve nedeni:
--   SUPER+W (kapat)      -> sende Windows VM
--   SUPER+T (float)      -> sende Telegram
--   SUPER+S (scratchpad) -> sende Spotify; yerine SUPER+grave kullaniliyor
--   SUPER+L (layout)     -> sende ekran kilidi (Noctalia)
--   SUPER+O (pop out)    -> sende Obsidian
--   SUPER+F/J/P          -> sende zaten ayni islevde
--   SUPER+CTRL+ok        -> sende 40px boyutlandirma
--   omarchy-hyprland-* cagiran 8 satir (tiled fullscreen, pencere genisligi
--   kaydet/geri yukle, monitor olcekleme, tumunu kapat) -> script yok

------------------------------------------------------------
-- Pencere gruplari (sekmeli pencere)
------------------------------------------------------------

hl.bind("SUPER + G",       hl.dsp.group.toggle())
hl.bind("SUPER + ALT + G", hl.dsp.window.move({ out_of_group = true }))

-- Pencereyi komsu gruba tasi
hl.bind("SUPER + ALT + left",  hl.dsp.window.move({ into_group = "l" }))
hl.bind("SUPER + ALT + right", hl.dsp.window.move({ into_group = "r" }))
hl.bind("SUPER + ALT + up",    hl.dsp.window.move({ into_group = "u" }))
hl.bind("SUPER + ALT + down",  hl.dsp.window.move({ into_group = "d" }))

-- Grup icinde gezinme
hl.bind("SUPER + ALT + TAB",         hl.dsp.group.next())
hl.bind("SUPER + ALT + SHIFT + TAB", hl.dsp.group.prev())
hl.bind("SUPER + ALT + mouse_down",  hl.dsp.group.next())
hl.bind("SUPER + ALT + mouse_up",    hl.dsp.group.prev())

-- Dogrudan sekmeye atla (SUPER+ALT+1..5)
for index = 1, 5 do
    hl.bind("SUPER + ALT + code:" .. tostring(index + 9), hl.dsp.group.active({ index = index }))
end

------------------------------------------------------------
-- Scratchpad
------------------------------------------------------------
-- Ozel calisma alani: hep acik duran yardimci pencere icin.
-- Sendeki special:minimized'dan ayri, o "pencereyi kaldir" icin.

hl.bind("SUPER + grave",         hl.dsp.workspace.toggle_special("scratchpad"))
hl.bind("SUPER + SHIFT + grave", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))

------------------------------------------------------------
-- Pencere dongusu
------------------------------------------------------------

hl.bind("ALT + TAB",         hl.dsp.window.cycle_next())
hl.bind("ALT + TAB",         hl.dsp.window.bring_to_top())
hl.bind("ALT + SHIFT + TAB", hl.dsp.window.cycle_next({ next = false }))
hl.bind("ALT + SHIFT + TAB", hl.dsp.window.bring_to_top())

------------------------------------------------------------
-- Calisma alani ve monitor
------------------------------------------------------------

hl.bind("SUPER + TAB",         hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + SHIFT + TAB", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + CTRL + TAB",  hl.dsp.focus({ workspace = "previous" }))

hl.bind("CTRL + ALT + TAB",         hl.dsp.focus({ monitor = "+1" }))
hl.bind("CTRL + ALT + SHIFT + TAB", hl.dsp.focus({ monitor = "-1" }))

-- Calisma alanini komsu monitore tasi (cift monitorde ise yarar)
hl.bind("SUPER + SHIFT + ALT + left",  hl.dsp.workspace.move({ monitor = "l" }))
hl.bind("SUPER + SHIFT + ALT + right", hl.dsp.workspace.move({ monitor = "r" }))
hl.bind("SUPER + SHIFT + ALT + up",    hl.dsp.workspace.move({ monitor = "u" }))
hl.bind("SUPER + SHIFT + ALT + down",  hl.dsp.workspace.move({ monitor = "d" }))

------------------------------------------------------------
-- Klavyeyle boyutlandirma, 3 kademe
------------------------------------------------------------
-- code:20 = "-", code:21 = "="  (mevcut SUPER+CTRL+ok 40px'e dokunulmadi)
--   duz        : 100 px
--   ALT        :  25 px
--   CTRL       : 300 px
--   +SHIFT     : dikey eksen

hl.bind("SUPER + code:20", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
hl.bind("SUPER + code:21", hl.dsp.window.resize({ x =  100, y = 0, relative = true }))
hl.bind("SUPER + SHIFT + code:20", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
hl.bind("SUPER + SHIFT + code:21", hl.dsp.window.resize({ x = 0, y =  100, relative = true }))

hl.bind("SUPER + ALT + code:20", hl.dsp.window.resize({ x = -25, y = 0, relative = true }))
hl.bind("SUPER + ALT + code:21", hl.dsp.window.resize({ x =  25, y = 0, relative = true }))
hl.bind("SUPER + SHIFT + ALT + code:20", hl.dsp.window.resize({ x = 0, y = -25, relative = true }))
hl.bind("SUPER + SHIFT + ALT + code:21", hl.dsp.window.resize({ x = 0, y =  25, relative = true }))

hl.bind("SUPER + CTRL + code:20", hl.dsp.window.resize({ x = -300, y = 0, relative = true }))
hl.bind("SUPER + CTRL + code:21", hl.dsp.window.resize({ x =  300, y = 0, relative = true }))
hl.bind("SUPER + CTRL + SHIFT + code:20", hl.dsp.window.resize({ x = 0, y = -300, relative = true }))
hl.bind("SUPER + CTRL + SHIFT + code:21", hl.dsp.window.resize({ x = 0, y =  300, relative = true }))
