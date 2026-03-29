import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import Qt5Compat.GraphicalEffects

Rectangle {
    id: pill
    required property var panelRoot

    property real xOff: 0

    // CPU
    property int cpuPct: 0
    property int prevTotal: 0
    property int prevIdle: 0
    property var corePcts: []
    property var _corePrevTotals: []
    property var _corePrevIdles: []
    property var _coreBuf: []
    property var topProcs: []
    property var _procBuf: []

    // RAM
    property int ramPct: 0
    property string ramInfo: ""

    // Disk
    property int drivePct: 0
    property string driveInfo: ""
    property real readSpeed: 0
    property real writeSpeed: 0
    property real prevRead: 0
    property real prevWrite: 0
    property bool firstIO: true

    // Network
    property real rxSpeed: 0
    property real txSpeed: 0
    property real prevRx: 0
    property real prevTx: 0
    property real totalRx: 0
    property real totalTx: 0
    property bool firstNet: true
    property string iface: ""
    property string ip: ""
    property string ssid: ""
    property var _infoBuf: []

    opacity: 1
    transform: Translate { x: pill.xOff }
    color: panelRoot.colPill
    radius: 12
    height: iconRow.height + 10
    width: iconRow.width + 20

    function formatSpeed(bps) {
        if (bps >= 1048576) return (bps / 1048576).toFixed(1) + " M/s"
        if (bps >= 1024)    return Math.round(bps / 1024) + " K/s"
        return bps + " B/s"
    }

    function formatBytes(b) {
        if (b >= 1073741824) return (b / 1073741824).toFixed(1) + " GB"
        if (b >= 1048576)    return (b / 1048576).toFixed(1) + " MB"
        if (b >= 1024)       return Math.round(b / 1024) + " KB"
        return b + " B"
    }

    Row {
        id: iconRow
        anchors.centerIn: parent
        spacing: 8

        // CPU: 6 core dots (3×2 grid)
        Canvas {
            id: coreGrid
            width: 13; height: 13
            anchors.verticalCenter: parent.verticalCenter
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var xs = [2, 6, 10]
                var ys = [3, 9]
                for (var row = 0; row < 2; row++) {
                    for (var col = 0; col < 3; col++) {
                        var idx = row * 3 + col
                        var pct = pill.corePcts[idx] || 0
                        var color = pct >= 95 ? panelRoot.colHigh.toString() : pct >= 80 ? panelRoot.colWarn.toString() : "#4ae09a"
                        ctx.beginPath()
                        ctx.arc(xs[col], ys[row], 1.8, 0, Math.PI * 2)
                        ctx.fillStyle = color
                        ctx.globalAlpha = 0.15 + (pct / 100) * 0.85
                        ctx.fill()
                    }
                }
                ctx.globalAlpha = 1.0
            }
        }

        // RAM icon with fill rising from bottom
        Item {
            width: 13; height: 13
            anchors.verticalCenter: parent.verticalCenter
            Image {
                id: ramIconMask
                anchors.fill: parent
                source: "icons/ram.svg"
                smooth: true; mipmap: true
                sourceSize.width: 13; sourceSize.height: 13
                visible: false; layer.enabled: true
            }
            ColorOverlay {
                anchors.fill: ramIconMask
                source: ramIconMask
                color: panelRoot.colWsEmpty
            }
            Item {
                anchors.fill: parent
                layer.enabled: true
                layer.effect: OpacityMask { maskSource: ramIconMask }
                Rectangle {
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                    height: parent.height * (pill.ramPct / 100)
                    color: pill.ramPct >= 95 ? panelRoot.colHigh : pill.ramPct >= 80 ? panelRoot.colWarn : "#4aa6e0"
                    Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                }
            }
        }

        // Disk icon with fill rising from bottom
        Item {
            width: 13; height: 13
            anchors.verticalCenter: parent.verticalCenter
            Image {
                id: driveIconMask
                anchors.fill: parent
                source: "icons/drive.svg"
                smooth: true; mipmap: true
                sourceSize.width: 13; sourceSize.height: 13
                visible: false; layer.enabled: true
            }
            ColorOverlay {
                anchors.fill: driveIconMask
                source: driveIconMask
                color: panelRoot.colWsEmpty
            }
            Item {
                anchors.fill: parent
                layer.enabled: true
                layer.effect: OpacityMask { maskSource: driveIconMask }
                Rectangle {
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                    height: parent.height * (pill.drivePct / 100)
                    color: pill.drivePct >= 95 ? panelRoot.colHigh : pill.drivePct >= 80 ? panelRoot.colWarn : "#4ae09a"
                }
            }
        }

        // Network: ↑/↓ arrows lit by activity
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: "↑"
                font { family: panelRoot.fontFamily; pixelSize: 11 }
                anchors.verticalCenter: parent.verticalCenter
                color: {
                    var pct = pill.txSpeed / 10485760 * 100
                    if (pct >= 80) return panelRoot.colHigh
                    if (pct >= 40) return panelRoot.colWarn
                    if (pill.txSpeed >= 1024) return "#e07840"
                    return Qt.rgba(1, 1, 1, 0.25)
                }
                Behavior on color { ColorAnimation { duration: 300 } }
            }

            Text {
                text: "↓"
                font { family: panelRoot.fontFamily; pixelSize: 11 }
                anchors.verticalCenter: parent.verticalCenter
                color: {
                    var pct = pill.rxSpeed / 10485760 * 100
                    if (pct >= 80) return panelRoot.colHigh
                    if (pct >= 40) return panelRoot.colWarn
                    if (pill.rxSpeed >= 1024) return "#4ac4e0"
                    return Qt.rgba(1, 1, 1, 0.25)
                }
                Behavior on color { ColorAnimation { duration: 300 } }
            }
        }
    }

    // ── Data sources ──────────────────────────────────────────────────────────

    // CPU overall
    Process {
        id: cpuProc
        command: ["sh", "-c", "awk '/^cpu /{print $2+$3+$4+$5+$6+$7+$8, $5}' /proc/stat"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var p = data.trim().split(" ")
                var total = parseInt(p[0]), idle = parseInt(p[1])
                if (pill.prevTotal !== 0) {
                    var dt = total - pill.prevTotal, di = idle - pill.prevIdle
                    if (dt > 0) pill.cpuPct = Math.round((1 - di / dt) * 100)
                }
                pill.prevTotal = total; pill.prevIdle = idle
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: cpuProc.running = true }

    // CPU per-core
    Process {
        id: coreProc
        command: ["sh", "-c", "awk '/^cpu[0-9]/{print $1, $2+$3+$4+$5+$6+$7+$8, $5}' /proc/stat"]
        running: true
        onRunningChanged: if (running) pill._coreBuf = []
        stdout: SplitParser {
            onRead: data => {
                var p = data.trim().split(" ")
                var idx = parseInt(p[0].substring(3))
                var total = parseInt(p[1]), idle = parseInt(p[2])
                var pt = pill._corePrevTotals[idx] || 0, pi = pill._corePrevIdles[idx] || 0
                var pct = 0
                if (pt !== 0) { var dt = total - pt, di = idle - pi; if (dt > 0) pct = Math.round((1 - di / dt) * 100) }
                pill._corePrevTotals[idx] = total; pill._corePrevIdles[idx] = idle
                var buf = pill._coreBuf.slice(); buf[idx] = pct; pill._coreBuf = buf
            }
        }
        onExited: { pill.corePcts = pill._coreBuf.slice(); coreGrid.requestPaint() }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: coreProc.running = true }

    // Top processes
    Process {
        id: topProcsProc
        command: ["sh", "-c", "ps -eo comm,%cpu --sort=-%cpu | awk 'NR>1 && $2+0>0 {c++; printf \"%s\\t%s\\n\", $1, $2; if(c>=8) exit}'"]
        running: true
        onRunningChanged: if (running) pill._procBuf = []
        stdout: SplitParser {
            onRead: data => { var p = data.trim().split("\t"); if (p.length >= 2) pill._procBuf.push({name: p[0], pct: p[1] + "%"}) }
        }
        onExited: pill.topProcs = pill._procBuf.slice()
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: topProcsProc.running = true }

    // RAM
    Process {
        id: ramProc
        command: ["sh", "-c", "awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf \"%.0f\", (t-a)/t*100}' /proc/meminfo"]
        running: true
        stdout: SplitParser { onRead: data => { var n = parseInt(data.trim()); if (!isNaN(n)) pill.ramPct = n } }
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: ramProc.running = true }

    Process {
        id: ramInfoProc
        command: ["sh", "-c", "free -h | awk '/^Mem:/{print $3\" / \"$2}'"]
        running: true
        stdout: SplitParser { onRead: data => pill.ramInfo = data.trim() }
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: ramInfoProc.running = true }

    // Disk usage
    Process {
        id: driveProc
        command: ["sh", "-c", "df --output=pcent / | tail -1 | tr -d ' %'"]
        running: true
        stdout: SplitParser { onRead: data => { var n = parseInt(data.trim()); if (!isNaN(n)) pill.drivePct = n } }
    }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: driveProc.running = true }

    Process {
        id: driveInfoProc
        command: ["sh", "-c", "df -h / | awk 'NR==2{print $3\" / \"$2}'"]
        running: true
        stdout: SplitParser { onRead: data => pill.driveInfo = data.trim() }
    }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: driveInfoProc.running = true }

    // Disk I/O
    Process {
        id: diskIOProc
        command: ["sh", "-c", "awk '$3~/^(sd[a-z]$|nvme[0-9]n[0-9]$|vd[a-z]$)/{r+=$6; w+=$10} END{print r+0, w+0}' /proc/diskstats"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var p = data.trim().split(" "); if (p.length < 2) return
                var r = parseFloat(p[0]), w = parseFloat(p[1])
                if (!pill.firstIO) { pill.readSpeed = Math.max(0, r - pill.prevRead); pill.writeSpeed = Math.max(0, w - pill.prevWrite) }
                pill.firstIO = false; pill.prevRead = r; pill.prevWrite = w
            }
        }
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: diskIOProc.running = true }

    // Network stats
    Process {
        id: netStatsProc
        command: ["sh", "-c", "iface=$(ip route show default | awk '/default/{print $5; exit}'); awk -v i=\"${iface}:\" '$1==i{print $2, $10}' /proc/net/dev"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var p = data.trim().split(" "); if (p.length < 2) return
                var rx = parseFloat(p[0]), tx = parseFloat(p[1])
                if (!pill.firstNet) { pill.rxSpeed = Math.max(0, (rx - pill.prevRx) / 2); pill.txSpeed = Math.max(0, (tx - pill.prevTx) / 2) }
                pill.firstNet = false; pill.prevRx = rx; pill.prevTx = tx; pill.totalRx = rx; pill.totalTx = tx
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: netStatsProc.running = true }

    Process {
        id: netInfoProc
        command: ["sh", "-c", "iface=$(ip route show default | awk '/default/{print $5; exit}'); printf '%s\\n' \"$iface\"; ip -4 addr show dev \"$iface\" 2>/dev/null | awk '/inet /{split($2, a, \"/\"); print a[1]; exit}'; iwgetid -r \"$iface\" 2>/dev/null"]
        running: true
        onRunningChanged: if (running) pill._infoBuf = []
        stdout: SplitParser { onRead: data => pill._infoBuf.push(data.trim()) }
        onExited: {
            if (pill._infoBuf.length >= 1) pill.iface = pill._infoBuf[0] || ""
            if (pill._infoBuf.length >= 2) pill.ip   = pill._infoBuf[1] || ""
            pill.ssid = pill._infoBuf.length >= 3 ? pill._infoBuf[2] : ""
        }
    }
    Timer { interval: 15000; running: true; repeat: true; onTriggered: netInfoProc.running = true }

    // ── Popup ─────────────────────────────────────────────────────────────────

    MouseArea { id: pillHover; anchors.fill: parent; hoverEnabled: true }

    PopupWindow {
        visible: panelRoot.pillsVisible && pillHover.containsMouse
        implicitWidth: 220
        implicitHeight: popupRect.height + 8
        color: "transparent"
        anchor.window: panelRoot
        anchor.item: pill
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        Rectangle {
            id: popupRect
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 8 }
            height: popupCol.implicitHeight + 20
            color: panelRoot.colPill
            radius: 10
            clip: true
            layer.enabled: true

            Column {
                id: popupCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 5

                // ── CPU ──────────────────────────────────────────────────────
                Row {
                    width: popupCol.width
                    Text {
                        text: "CPU"
                        color: panelRoot.colWsOccupied
                        font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                        width: 40
                    }
                    Text {
                        text: pill.cpuPct + "%"
                        color: pill.cpuPct >= 95 ? panelRoot.colHigh : pill.cpuPct >= 80 ? panelRoot.colWarn : panelRoot.colWsActive
                        font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2; bold: true }
                    }
                }

                Repeater {
                    model: pill.corePcts
                    delegate: Row {
                        width: popupCol.width
                        spacing: 4
                        Text {
                            text: "C" + index
                            color: panelRoot.colWsOccupied
                            font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 3 }
                            width: 18
                        }
                        Rectangle {
                            width: popupCol.width - 18 - 36 - 8
                            height: 3; radius: 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: panelRoot.colBarTrack
                            Rectangle {
                                width: parent.width * (modelData / 100)
                                height: parent.height; radius: 2
                                color: modelData >= 95 ? panelRoot.colHigh : modelData >= 80 ? panelRoot.colWarn : panelRoot.colWsActive
                            }
                        }
                        Text {
                            text: modelData + "%"
                            color: panelRoot.colWsOccupied
                            font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 3 }
                            width: 36; horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                Repeater {
                    model: pill.topProcs
                    delegate: Row {
                        width: popupCol.width
                        Text {
                            text: modelData.name
                            color: panelRoot.colWsOccupied
                            font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 3 }
                            width: parent.width - 40; elide: Text.ElideRight
                        }
                        Text {
                            text: modelData.pct
                            color: panelRoot.colWsOccupied
                            font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 3 }
                            width: 40; horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                // ── Divider ──────────────────────────────────────────────────
                Rectangle { width: popupCol.width; height: 1; color: panelRoot.colBarTrack }

                // ── RAM ──────────────────────────────────────────────────────
                Row {
                    width: popupCol.width
                    Text {
                        text: "RAM"
                        color: panelRoot.colWsOccupied
                        font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                        width: 40
                    }
                    Text {
                        text: pill.ramPct + "%"
                        color: pill.ramPct >= 95 ? panelRoot.colHigh : pill.ramPct >= 80 ? panelRoot.colWarn : panelRoot.colWsActive
                        font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2; bold: true }
                        width: 40
                    }
                    Text {
                        text: pill.ramInfo
                        color: panelRoot.colWsOccupied
                        font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                    }
                }

                Rectangle {
                    width: popupCol.width
                    height: 4; radius: 2
                    color: panelRoot.colBarTrack
                    Rectangle {
                        width: parent.width * (pill.ramPct / 100)
                        height: parent.height; radius: 2
                        color: pill.ramPct >= 95 ? panelRoot.colHigh : pill.ramPct >= 80 ? panelRoot.colWarn : "#4aa6e0"
                    }
                }

                // ── Divider ──────────────────────────────────────────────────
                Rectangle { width: popupCol.width; height: 1; color: panelRoot.colBarTrack }

                // ── Disk ─────────────────────────────────────────────────────
                Row {
                    width: popupCol.width
                    Text {
                        text: "Disk"
                        color: panelRoot.colWsOccupied
                        font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                        width: 40
                    }
                    Text {
                        text: pill.drivePct + "%"
                        color: pill.drivePct >= 95 ? panelRoot.colHigh : pill.drivePct >= 80 ? panelRoot.colWarn : panelRoot.colWsActive
                        font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2; bold: true }
                        width: 40
                    }
                    Text {
                        text: pill.driveInfo
                        color: panelRoot.colWsOccupied
                        font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                    }
                }

                Rectangle {
                    width: popupCol.width
                    height: 4; radius: 2
                    color: panelRoot.colBarTrack
                    Rectangle {
                        width: parent.width * (pill.drivePct / 100)
                        height: parent.height; radius: 2
                        color: pill.drivePct >= 95 ? panelRoot.colHigh : pill.drivePct >= 80 ? panelRoot.colWarn : "#4ae09a"
                    }
                }

                Row {
                    width: popupCol.width
                    spacing: 8
                    Text {
                        text: "↓ " + pill.formatSpeed(pill.readSpeed * 512)
                        color: panelRoot.colWsOccupied
                        font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 3 }
                    }
                    Text {
                        text: "↑ " + pill.formatSpeed(pill.writeSpeed * 512)
                        color: panelRoot.colWsOccupied
                        font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 3 }
                    }
                }

                // ── Divider ──────────────────────────────────────────────────
                Rectangle { width: popupCol.width; height: 1; color: panelRoot.colBarTrack }

                // ── Network ──────────────────────────────────────────────────
                Row {
                    width: popupCol.width
                    spacing: 8
                    Text {
                        text: "↓ " + pill.formatSpeed(pill.rxSpeed)
                        color: panelRoot.colWsActive
                        font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                        width: popupCol.width / 2 - 4
                    }
                    Text {
                        text: "↑ " + pill.formatSpeed(pill.txSpeed)
                        color: panelRoot.colWsActive
                        font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                    }
                }

                Repeater {
                    model: [
                        { label: "Interface", value: pill.iface },
                        { label: "IP",        value: pill.ip },
                        { label: "SSID",      value: pill.ssid },
                        { label: "Total ↓",   value: pill.formatBytes(pill.totalRx) },
                        { label: "Total ↑",   value: pill.formatBytes(pill.totalTx) },
                    ].filter(r => r.value !== "")
                    delegate: Row {
                        width: popupCol.width
                        Text {
                            text: modelData.label
                            color: panelRoot.colWsOccupied
                            font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                            width: 76
                        }
                        Text {
                            text: modelData.value
                            color: panelRoot.colWsActive
                            font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                            width: popupCol.width - 76; elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
