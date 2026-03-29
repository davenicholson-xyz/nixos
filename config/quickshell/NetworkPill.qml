import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import Qt5Compat.GraphicalEffects

Rectangle {
    id: pill
    required property var panelRoot

    property real xOff: 0
    property real rxSpeed: 0
    property real txSpeed: 0
    property real totalRx: 0
    property real totalTx: 0
    property real prevRx: 0
    property real prevTx: 0
    property bool firstRead: true
    property string iface: ""
    property string ip: ""
    property string ssid: ""
    property var _infoBuf: []
    property real maxSpeed: 10485760
    property var rxHistory: []
    property var txHistory: []
    property int historyMax: 80

    Timer {
        interval: 80
        running: panelRoot.pillsVisible
        repeat: true
        onTriggered: {
            pill.rxHistory.push(pill.rxSpeed); if (pill.rxHistory.length > pill.historyMax) pill.rxHistory.shift()
            pill.txHistory.push(pill.txSpeed); if (pill.txHistory.length > pill.historyMax) pill.txHistory.shift()
            netCanvas.requestPaint()
        }
    }

    opacity: 1
    transform: Translate { x: pill.xOff }
    color: panelRoot.colPill
    radius: 12
    width: 100
    height: 23

    function formatSpeed(bps) {
        if (bps >= 1048576) return (bps / 1048576).toFixed(1) + "M/s"
        if (bps >= 1024) return Math.round(bps / 1024) + "K/s"
        return bps + "B/s"
    }

    function formatSpeedShort(bps) {
        if (bps >= 1048576) return (bps / 1048576).toFixed(1) + "M"
        if (bps >= 1024) return Math.round(bps / 1024) + "K"
        return bps + "B"
    }

    function dotColor(bps) {
        if (bps >= 1048576) return panelRoot.colWsActive
        if (bps >= 10240)   return panelRoot.colWsOccupied
        return panelRoot.colWsEmpty
    }

    function formatBytes(b) {
        if (b >= 1073741824) return (b / 1073741824).toFixed(1) + " GB"
        if (b >= 1048576) return (b / 1048576).toFixed(1) + " MB"
        if (b >= 1024) return Math.round(b / 1024) + " KB"
        return b + " B"
    }

    Row {
        anchors.centerIn: parent
        spacing: 5

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Text {
                text: "↑"
                font { family: panelRoot.fontFamily; pixelSize: 7 }
                color: {
                    var pct = pill.txSpeed / pill.maxSpeed * 100
                    if (pct >= 80) return panelRoot.colHigh
                    if (pct >= 40) return panelRoot.colWarn
                    if (pill.txSpeed >= 1024) return "#e07840"
                    return Qt.rgba(1, 1, 1, 0.25)
                }
            }

            Text {
                text: "↓"
                font { family: panelRoot.fontFamily; pixelSize: 7 }
                color: {
                    var pct = pill.rxSpeed / pill.maxSpeed * 100
                    if (pct >= 80) return panelRoot.colHigh
                    if (pct >= 40) return panelRoot.colWarn
                    if (pill.rxSpeed >= 1024) return "#4ac4e0"
                    return Qt.rgba(1, 1, 1, 0.25)
                }
            }
        }

        Canvas {
            id: netCanvas
            width: 66
            height: 13
            anchors.verticalCenter: parent.verticalCenter

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var logMax = Math.log1p(pill.maxSpeed)
                var half   = (height - 1) / 2  // ~6px per channel
                var midY   = height / 2
                var n      = pill.historyMax

                function norm(spd) {
                    return Math.log1p(spd) / logMax * (half - 1)
                }

                function sparkColor(spd, baseColor) {
                    var pct = spd / pill.maxSpeed * 100
                    return pct >= 80 ? panelRoot.colHigh.toString() : pct >= 40 ? panelRoot.colWarn.toString() : baseColor
                }

                function drawSparkline(history, baseY, up, color) {
                    if (history.length < 2) return

                    // Filled area under the line
                    ctx.beginPath()
                    ctx.moveTo(0, baseY)
                    for (var i = 0; i < history.length; i++) {
                        var x = (i / (n - 1)) * width
                        var h = norm(history[i])
                        ctx.lineTo(x, up ? baseY - h : baseY + h)
                    }
                    ctx.lineTo(width, baseY)
                    ctx.closePath()
                    var grad = ctx.createLinearGradient(0, up ? baseY - half : baseY, 0, baseY)
                    grad.addColorStop(0, Qt.rgba(
                        parseInt(color.slice(1,3),16)/255,
                        parseInt(color.slice(3,5),16)/255,
                        parseInt(color.slice(5,7),16)/255,
                        0.25))
                    grad.addColorStop(1, Qt.rgba(0,0,0,0))
                    ctx.fillStyle = grad
                    ctx.fill()

                    // Line on top
                    ctx.beginPath()
                    for (var j = 0; j < history.length; j++) {
                        var lx = (j / (n - 1)) * width
                        var lh = norm(history[j])
                        var ly = up ? baseY - lh : baseY + lh
                        if (j === 0) ctx.moveTo(lx, ly)
                        else         ctx.lineTo(lx, ly)
                    }
                    ctx.strokeStyle = color
                    ctx.lineWidth   = 1.2
                    ctx.lineJoin    = "round"
                    ctx.stroke()
                }

                // Faint centre divider
                ctx.beginPath()
                ctx.moveTo(0, midY); ctx.lineTo(width, midY)
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.07)
                ctx.lineWidth = 1
                ctx.stroke()

                drawSparkline(pill.rxHistory, midY, true,  sparkColor(pill.rxSpeed, "#4ac4e0"))
                drawSparkline(pill.txHistory, midY, false, sparkColor(pill.txSpeed, "#e07840"))

                // ↓ ↑ labels on right edge
                ctx.font = "6px monospace"
                ctx.textAlign = "right"
                ctx.fillStyle = Qt.rgba(
                    parseInt(sparkColor(pill.rxSpeed,"#4ac4e0").slice(1,3),16)/255,
                    parseInt(sparkColor(pill.rxSpeed,"#4ac4e0").slice(3,5),16)/255,
                    parseInt(sparkColor(pill.rxSpeed,"#4ac4e0").slice(5,7),16)/255, 0.7)
                ctx.fillText("↓", width - 1, midY - 1)
                ctx.fillStyle = Qt.rgba(
                    parseInt(sparkColor(pill.txSpeed,"#e07840").slice(1,3),16)/255,
                    parseInt(sparkColor(pill.txSpeed,"#e07840").slice(3,5),16)/255,
                    parseInt(sparkColor(pill.txSpeed,"#e07840").slice(5,7),16)/255, 0.7)
                ctx.fillText("↑", width - 1, midY + 7)

                // Left-edge fade
                var fade = ctx.createLinearGradient(0, 0, width * 0.18, 0)
                fade.addColorStop(0, Qt.rgba(0, 0, 0, 0.9))
                fade.addColorStop(1, Qt.rgba(0, 0, 0, 0))
                ctx.fillStyle = fade
                ctx.fillRect(0, 0, width * 0.18, height)
            }
        }
    }

    Process {
        id: netStatsProc
        command: ["sh", "-c", "iface=$(ip route show default | awk '/default/{print $5; exit}'); awk -v i=\"${iface}:\" '$1==i{print $2, $10}' /proc/net/dev"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(" ")
                if (parts.length < 2) return
                var rx = parseFloat(parts[0])
                var tx = parseFloat(parts[1])
                if (!pill.firstRead) {
                    pill.rxSpeed = Math.max(0, (rx - pill.prevRx) / 2)
                    pill.txSpeed = Math.max(0, (tx - pill.prevTx) / 2)
                }
                pill.firstRead = false
                pill.prevRx = rx
                pill.prevTx = tx
                pill.totalRx = rx
                pill.totalTx = tx
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: netStatsProc.running = true }

    Process {
        id: netInfoProc
        command: ["sh", "-c", "iface=$(ip route show default | awk '/default/{print $5; exit}'); printf '%s\\n' \"$iface\"; ip -4 addr show dev \"$iface\" 2>/dev/null | awk '/inet /{split($2, a, \"/\"); print a[1]; exit}'; iwgetid -r \"$iface\" 2>/dev/null"]
        running: true
        onRunningChanged: if (running) pill._infoBuf = []
        stdout: SplitParser {
            onRead: data => { pill._infoBuf.push(data.trim()) }
        }
        onExited: {
            if (pill._infoBuf.length >= 1) pill.iface = pill._infoBuf[0] || ""
            if (pill._infoBuf.length >= 2) pill.ip   = pill._infoBuf[1] || ""
            pill.ssid = pill._infoBuf.length >= 3 ? pill._infoBuf[2] : ""
        }
    }
    Timer { interval: 15000; running: true; repeat: true; onTriggered: netInfoProc.running = true }

    MouseArea { id: netHover; anchors.fill: parent; hoverEnabled: true }

    PopupWindow {
        visible: panelRoot.pillsVisible && netHover.containsMouse
        implicitWidth: 200
        implicitHeight: netPopupRect.height + 8
        color: "transparent"
        anchor.window: panelRoot
        anchor.item: pill
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        Rectangle {
            id: netPopupRect
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 8 }
            height: netPopupCol.implicitHeight + 20
            color: panelRoot.colPill
            radius: 10

            Column {
                id: netPopupCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                spacing: 4

                Row {
                    width: netPopupCol.width
                    Text {
                        text: "↓  " + pill.formatSpeed(pill.rxSpeed)
                        color: panelRoot.colWsActive
                        font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                        width: parent.width / 2
                    }
                    Text {
                        text: "↑  " + pill.formatSpeed(pill.txSpeed)
                        color: panelRoot.colWsActive
                        font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                    }
                }

                Rectangle {
                    width: netPopupCol.width
                    height: 1
                    color: panelRoot.colBarTrack
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
                        width: netPopupCol.width
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
                            width: netPopupCol.width - 76
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
