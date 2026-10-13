pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Current weather from open-meteo. Location comes from ip-api.com once per
// session (same sources DMS used), so nothing is configured by hand.
Singleton {
    id: root

    property real lat: NaN
    property real lon: NaN
    property string city: ""
    property real temp: NaN
    property int code: -1
    property bool isDay: true
    property real windKmh: NaN
    property int humidity: -1
    property real tempMax: NaN
    property real tempMin: NaN
    readonly property bool ready: !isNaN(temp)

    // WMO weather code -> Material Symbols name
    readonly property string icon: {
        const c = code;
        if (c === 0) return isDay ? "clear_day" : "clear_night";
        if (c <= 2) return isDay ? "partly_cloudy_day" : "partly_cloudy_night";
        if (c === 3) return "cloud";
        if (c === 45 || c === 48) return "foggy";
        if (c >= 51 && c <= 67) return "rainy";
        if (c >= 71 && c <= 77) return "weather_snowy";
        if (c >= 80 && c <= 82) return "rainy";
        if (c >= 85 && c <= 86) return "weather_snowy";
        if (c >= 95) return "thunderstorm";
        return "cloud";
    }

    readonly property string description: {
        const c = code;
        if (c === 0) return "Açık";
        if (c <= 2) return "Parçalı bulutlu";
        if (c === 3) return "Kapalı";
        if (c === 45 || c === 48) return "Sisli";
        if (c >= 51 && c <= 57) return "Çisenti";
        if (c >= 61 && c <= 67) return "Yağmurlu";
        if (c >= 71 && c <= 77) return "Karlı";
        if (c >= 80 && c <= 82) return "Sağanak";
        if (c >= 85 && c <= 86) return "Kar sağanağı";
        if (c >= 95) return "Fırtına";
        return "";
    }

    function refresh() {
        if (isNaN(lat)) {
            if (!locProc.running) locProc.running = true;
        } else if (!wxProc.running) {
            wxProc.running = true;
        }
    }

    Timer {
        interval: 15 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // Network may not be up at login; retry until the first fetch succeeds.
    Timer {
        id: retry
        interval: 30000
        onTriggered: root.refresh()
    }

    Process {
        id: locProc
        command: ["curl", "-sf", "--max-time", "10", "http://ip-api.com/json/?fields=status,lat,lon,city"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const o = JSON.parse(text);
                    if (o.status !== "success") throw "status " + o.status;
                    root.lat = o.lat;
                    root.lon = o.lon;
                    root.city = o.city || "";
                    wxProc.running = true;
                } catch (e) {
                    retry.restart();
                }
            }
        }
    }

    Process {
        id: wxProc
        command: ["curl", "-sf", "--max-time", "10",
            "https://api.open-meteo.com/v1/forecast?latitude=" + root.lat + "&longitude=" + root.lon
            + "&current=temperature_2m,weather_code,is_day,wind_speed_10m,relative_humidity_2m"
            + "&daily=temperature_2m_max,temperature_2m_min&forecast_days=1&timezone=auto"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const o = JSON.parse(text);
                    root.temp = o.current.temperature_2m;
                    root.code = o.current.weather_code;
                    root.isDay = o.current.is_day === 1;
                    root.windKmh = o.current.wind_speed_10m;
                    root.humidity = o.current.relative_humidity_2m;
                    root.tempMax = o.daily.temperature_2m_max[0];
                    root.tempMin = o.daily.temperature_2m_min[0];
                } catch (e) {
                    retry.restart();
                }
            }
        }
    }
}
