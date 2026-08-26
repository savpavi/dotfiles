/* dot-theme tarafından üretildi — elle düzenleme.
   Seçiciler SwayOSD 0.3.2'nin /etc/xdg/swayosd/style.css dosyasından alındı. */

window#osd {
  border-radius: 24px;
  border: 1px solid {{ selection }};
  background: rgba({{ background_rgb }}, 0.82);
}

window#osd #container {
  margin: 16px;
}

window#osd image,
window#osd label {
  color: {{ foreground }};
}

window#osd progressbar:disabled,
window#osd image:disabled {
  opacity: 0.5;
}

window#osd progressbar,
window#osd segmentedprogress {
  min-height: 8px;
  border-radius: 999px;
  background: transparent;
  border: none;
}

window#osd trough,
window#osd segment {
  min-height: inherit;
  border-radius: inherit;
  border: none;
  background: {{ selection }};
}

window#osd progress,
window#osd segment.active {
  min-height: inherit;
  border-radius: inherit;
  border: none;
  background: {{ accent }};
}

window#osd segment {
  margin-left: 8px;
}

window#osd segment:first-child {
  margin-left: 0;
}
