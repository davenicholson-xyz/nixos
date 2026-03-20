import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import Qt5Compat.GraphicalEffects

Rectangle {
    id: pill
    required property var panelRoot

    property real xOff: 24
    property int prevTotal: 0
    property int prevIdle: 0
    property int cpuPct: 0
    property int tempC: 0
    property var topProcs: []
    property var _procBuf: []
    property var corePcts: []
    property var _corePrevTotals: []
    property var _corePrevIdles: []
    property var _coreBuf: []

    property real beatPhase: 0.0
    property var ecgSamples: []
    property int ecgMaxSamples: 80

    function ecgSample(phase) {
        var t
        if (phase >= 0.08 && phase < 0.18) {
            t = (phase - 0.08) / 0.10
            return 0.18 * Math.sin(Math.PI * t)
        }
        if (phase >= 0.26 && phase < 0.30) {
            t = (phase - 0.26) / 0.04
            return -0.12 * Math.sin(Math.PI * t)
        }
        if (phase >= 0.30 && phase < 0.38) {
            t = (phase - 0.30) / 0.08
            return Math.sin(Math.PI * t)
        }
        if (phase >= 0.38 && phase < 0.43) {
            t = (phase - 0.38) / 0.05
            return -0.18 * Math.sin(Math.PI * t)
        }
        if (phase >= 0.48 && phase < 0.68) {
            t = (phase - 0.48) / 0.20
            return 0.28 * Math.sin(Math.PI * t)
        }
        return 0.0
    }

    Timer {
        interval: 40
        running: true
        repeat: true
        onTriggered: {
            var bpm = 50 + (pill.cpuPct / 100) * 110
            pill.beatPhase = (pill.beatPhase + (bpm / 60) * 0.04) % 1.0
            var arr = pill.ecgSamples.slice()
            arr.push(pill.ecgSample(pill.beatPhase))
            if (arr.length > pill.ecgMaxSamples) arr.shift()
            pill.ecgSamples = arr
            ecgCanvas.requestPaint()
        }
    }

    opacity: 0
    transform: Translate { x: pill.xOff }
    color: panelRoot.colPill
    radius: 12
    width: 96
    height: cpuRow.height + 10

    Row {
        id: cpuRow
        anchors.centerIn: parent
        spacing: 6

        Item {
            width: 13; height: 13
            anchors.verticalCenter: parent.verticalCenter

            Image {
                id: cpuIcon
                anchors.fill: parent
                source: "icons/cpu.svg"
                smooth: true
                mipmap: true
                sourceSize.width: 13
                sourceSize.height: 13
                visible: false
                layer.enabled: true
            }

            ColorOverlay {
                anchors.fill: cpuIcon
                source: cpuIcon
                color: panelRoot.colClock
            }
        }

        Canvas {
            id: ecgCanvas
            width: 64
            height: 13
            anchors.verticalCenter: parent.verticalCenter

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var s = pill.ecgSamples
                if (s.length < 2) return

                var midY = height / 2
                var amp  = height * 0.44

                var lineColor = pill.cpuPct >= 95 ? "#e05252"
                              : pill.cpuPct >= 80 ? "#e0c94a"
                              : "#4ae09a"

                ctx.strokeStyle = lineColor
                ctx.lineWidth = 1.5
                ctx.lineJoin = "round"
                ctx.shadowColor = lineColor
                ctx.shadowBlur = 5

                ctx.beginPath()
                for (var i = 0; i < s.length; i++) {
                    var x = (i / (pill.ecgMaxSamples - 1)) * width
                    var y = midY - s[i] * amp
                    if (i === 0) ctx.moveTo(x, y)
                    else ctx.lineTo(x, y)
                }
                ctx.stroke()

                var grad = ctx.createLinearGradient(0, 0, width * 0.25, 0)
                grad.addColorStop(0, Qt.rgba(0, 0, 0, 0.8))
                grad.addColorStop(1, Qt.rgba(0, 0, 0, 0))
                ctx.fillStyle = grad
                ctx.fillRect(0, 0, width * 0.25, height)
            }
        }
    }

    Process {
        id: cpuProc
        command: ["sh", "-c", "awk '/^cpu /{print $2+$3+$4+$5+$6+$7+$8, $5}' /proc/stat"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(" ")
                var total = parseInt(parts[0])
                var idle = parseInt(parts[1])
                if (pill.prevTotal !== 0) {
                    var dt = total - pill.prevTotal
                    var di = idle - pill.prevIdle
                    if (dt > 0) pill.cpuPct = Math.round((1 - di / dt) * 100)
                }
                pill.prevTotal = total
                pill.prevIdle = idle
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: cpuProc.running = true }

    Process {
        id: tempProc
        command: ["sh", "-c", "cat /sys/class/thermal/thermal_zone1/temp"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var num = parseInt(data.trim())
                if (!isNaN(num)) pill.tempC = Math.round(num / 1000)
            }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: tempProc.running = true }

    Process {
        id: topProcsProc
        command: ["sh", "-c", "ps -eo comm,%cpu --sort=-%cpu | awk 'NR>1 && $2+0>0 {c++; printf \"%s\\t%s\\n\", $1, $2; if(c>=10) exit}'"]
        running: true
        onRunningChanged: if (running) pill._procBuf = []
        stdout: SplitParser {
            onRead: data => {
                var p = data.trim().split("\t")
                if (p.length >= 2) pill._procBuf.push({name: p[0], pct: p[1] + "%"})
            }
        }
        onExited: pill.topProcs = pill._procBuf.slice()
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: topProcsProc.running = true }

    Process {
        id: coreProc
        command: ["sh", "-c", "awk '/^cpu[0-9]/{print $1, $2+$3+$4+$5+$6+$7+$8, $5}' /proc/stat"]
        running: true
        onRunningChanged: if (running) pill._coreBuf = []
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(" ")
                var coreIdx = parseInt(parts[0].substring(3))
                var total = parseInt(parts[1])
                var idle = parseInt(parts[2])
                var prevTotal = pill._corePrevTotals[coreIdx] || 0
                var prevIdle = pill._corePrevIdles[coreIdx] || 0
                var pct = 0
                if (prevTotal !== 0) {
                    var dt = total - prevTotal
                    var di = idle - prevIdle
                    if (dt > 0) pct = Math.round((1 - di / dt) * 100)
                }
                pill._corePrevTotals[coreIdx] = total
                pill._corePrevIdles[coreIdx] = idle
                var buf = pill._coreBuf.slice()
                buf[coreIdx] = pct
                pill._coreBuf = buf
            }
        }
        onExited: pill.corePcts = pill._coreBuf.slice()
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: coreProc.running = true }

    MouseArea { id: cpuHover; anchors.fill: parent; hoverEnabled: true }

    PopupWindow {
        visible: panelRoot.pillsVisible && cpuHover.containsMouse
        implicitWidth: 200
        implicitHeight: cpuPopupRect.height + 8
        color: "transparent"
        anchor.window: panelRoot
        anchor.item: pill
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        Rectangle {
            id: cpuPopupRect
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 8 }
            height: cpuPopupCol.implicitHeight + 20
            color: panelRoot.colPill
            radius: 10

            Column {
                id: cpuPopupCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                spacing: 4

                Text {
                    text: "CPU   " + pill.cpuPct + "%"
                    color: panelRoot.colWsActive
                    font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                }
                Text {
                    text: "Temp  " + pill.tempC + "°C"
                    color: pill.tempC >= 90 ? "#e05252" : pill.tempC >= 75 ? "#e0c94a" : panelRoot.colWsActive
                    font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                }
                Rectangle {
                    width: cpuPopupCol.width
                    height: 1
                    color: panelRoot.colBarTrack
                    visible: pill.corePcts.length > 0
                }
                Repeater {
                    model: pill.corePcts
                    delegate: Row {
                        width: cpuPopupCol.width
                        spacing: 4
                        Text {
                            text: "C" + index
                            color: panelRoot.colWsOccupied
                            font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 3 }
                            width: 18
                        }
                        Rectangle {
                            width: cpuPopupCol.width - 18 - 36 - 8
                            height: 3
                            radius: 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: panelRoot.colBarTrack
                            Rectangle {
                                width: parent.width * (modelData / 100)
                                height: parent.height
                                radius: 2
                                color: modelData >= 95 ? "#e05252" : modelData >= 80 ? "#e0c94a" : panelRoot.colWsActive
                            }
                        }
                        Text {
                            text: modelData + "%"
                            color: panelRoot.colWsOccupied
                            font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 3 }
                            width: 36
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
                Rectangle {
                    width: cpuPopupCol.width
                    height: 1
                    color: panelRoot.colBarTrack
                    visible: pill.topProcs.length > 0
                }
                Repeater {
                    model: pill.topProcs
                    delegate: Row {
                        width: cpuPopupCol.width
                        Text {
                            text: modelData.name
                            color: panelRoot.colWsOccupied
                            font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                            width: parent.width - 44
                            elide: Text.ElideRight
                        }
                        Text {
                            text: modelData.pct
                            color: panelRoot.colWsOccupied
                            font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                            width: 44
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }
        }
    }
}
