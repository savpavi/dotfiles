# App colour templates

Templates that `bin/dot-shell-theme` fills from the active theme's palette and
writes to each app's config (GTK 3/4, Qt5/6ct, KDE colour schemes, kitty,
Vesktop/Vencord, Zed, Zen, Hyprland borders, dgop).

They are copied from DankMaterialShell's matugen templates
(`/usr/share/quickshell/dms/matugen/templates`, DMS 1.6.2), MIT licensed —
see `LICENSE-dms`. `dot-shell-theme` renames the DMS names in the output
(theme/scheme names, header comments). `btop.theme` is ours, not from DMS. Placeholders are `{{colors.<role>.<default|dark|light>.<hex|hex_stripped|red|green|blue>}}`
and `{{dank16.colorN.<variant>.<hex|hex_stripped>}}`.
