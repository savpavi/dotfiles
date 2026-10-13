import QtQuick
import qs.common
import qs.services

Column {
    readonly property var cfg: ShellState.settings
    spacing: 0

    Toggle { title: "Odaktaki pencere"; hint: "Başlık ve uygulama ikonu"; checked: cfg.showFocusedWindow; onToggled: v => cfg.showFocusedWindow = v }
    Toggle { title: "Müzik"; checked: cfg.showMedia; onToggled: v => cfg.showMedia = v }
    Toggle { title: "Ses görselleştirme (cava)"; hint: "Müzik çalarken"; checked: cfg.showCava; onToggled: v => cfg.showCava = v }
    Toggle { title: "Hava durumu"; checked: cfg.showWeather; onToggled: v => cfg.showWeather = v }
    Toggle { title: "Telefona gönder"; checked: cfg.showSend; onToggled: v => cfg.showSend = v }
    Toggle { title: "CPU / RAM"; checked: cfg.showStats; onToggled: v => cfg.showStats = v }
    Toggle { title: "Claude kullanımı"; checked: cfg.showClaude; onToggled: v => cfg.showClaude = v }
    Toggle { title: "Tailscale"; checked: cfg.showTailscale; onToggled: v => cfg.showTailscale = v }
    Toggle { title: "Saatte saniye"; checked: cfg.clockSeconds; onToggled: v => cfg.clockSeconds = v }
    Toggle { title: "Bar iki ekranda"; hint: "Kapalıyken yalnız ASUS (DP-1)"; checked: cfg.barOnAllScreens; onToggled: v => cfg.barOnAllScreens = v }
}
