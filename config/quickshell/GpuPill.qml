import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import Qt5Compat.GraphicalEffects

Rectangle {
    id: pill
    required property var panelRoot

    property real xOff: 0
    property int  gpuPct: 0
    property int  gpuFreqMhz: 0
    property int  gpuMaxFreqMhz: 1100

    property real prevRc6Ms:  -1
    property real prevWallMs: -1
    property real wavePhase:   0.0

    function gpuColor() {
        return gpuPct >= 95 ? "#e05252"
             : gpuPct >= 80 ? "#e0c94a"
             : "#a07de0"
    }

    opacity: 1
    transform: Translate { x: pill.xOff }
    color: panelRoot.colPill
    radius: 12
    width: 80
    height: gpuRow.height + 10

    Timer {
        interval: 80
        running: panelRoot.pillsVisible
        repeat: true
        onTriggered: {
            var speed = 0.04 + (pill.gpuFreqMhz / Math.max(1, pill.gpuMaxFreqMhz)) * 0.22
            pill.wavePhase += speed
            waveCanvas.requestPaint()
            chipCanvas.requestPaint()
        }
    }

    Row {
        id: gpuRow
        anchors.centerIn: parent
        spacing: 6

        // IC chip icon: box + pins, filled from bottom by GPU%
        Canvas {
            id: chipCanvas
            width: 13; height: 13
            anchors.verticalCenter: parent.verticalCenter

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var pct   = pill.gpuPct / 100
                var color = pill.gpuColor()

                // Body outline
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.20)
                ctx.lineWidth   = 1
                ctx.strokeRect(2.5, 2.5, 8, 8)

                // Fill rising from bottom
                var fillH = 8 * pct
                ctx.fillStyle   = color
                ctx.globalAlpha = 0.15 + pct * 0.75
                ctx.fillRect(3, 2.5 + 8 - fillH, 7.5, fillH)
                ctx.globalAlpha = 1.0

                // Pins: 2 per side
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.18)
                ctx.lineWidth   = 0.8
                var pinYs = [5, 8]
                for (var i = 0; i < pinYs.length; i++) {
                    ctx.beginPath(); ctx.moveTo(0, pinYs[i]); ctx.lineTo(2.5, pinYs[i]); ctx.stroke()
                    ctx.beginPath(); ctx.moveTo(10.5, pinYs[i]); ctx.lineTo(13, pinYs[i]); ctx.stroke()
                }
            }
        }

        // Wave canvas — faster/sharper than RAM to feel GPU-like
        Canvas {
            id: waveCanvas
            width: 52
            height: 13
            anchors.verticalCenter: parent.verticalCenter

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var pct   = pill.gpuPct / 100
                var phase = pill.wavePhase
                var cr, cg, cb, color

                if (pill.gpuPct >= 95)      { cr=0.878; cg=0.322; cb=0.322; color="#e05252" }
                else if (pill.gpuPct >= 80) { cr=0.878; cg=0.788; cb=0.290; color="#e0c94a" }
                else                        { cr=0.627; cg=0.490; cb=0.878; color="#a07de0" }

                var fillHeight = Math.max(2, pct * height)
                var baseY      = height - fillHeight

                // Two-frequency wave: sharper/more angular than the RAM lava
                var pts = []
                for (var x = 0; x <= width; x++) {
                    var wave = Math.sin(x * 0.40 + phase * 2.4) * 1.3
                            + Math.sin(x * 0.15 - phase * 1.5) * 0.7
                    pts.push(baseY + wave)
                }

                // Filled body
                ctx.beginPath()
                ctx.moveTo(0, pts[0])
                for (var i = 1; i < pts.length; i++) ctx.lineTo(i, pts[i])
                ctx.lineTo(width, height)
                ctx.lineTo(0, height)
                ctx.closePath()
                var grad = ctx.createLinearGradient(0, baseY - 3, 0, height)
                grad.addColorStop(0, Qt.rgba(cr, cg, cb, 0.65))
                grad.addColorStop(1, Qt.rgba(cr, cg, cb, 0.18))
                ctx.fillStyle = grad
                ctx.fill()

                // Glowing surface line
                ctx.beginPath()
                ctx.moveTo(0, pts[0])
                for (var j = 1; j < pts.length; j++) ctx.lineTo(j, pts[j])
                ctx.strokeStyle = color
                ctx.lineWidth   = 1.5
                ctx.lineJoin    = "round"
                ctx.stroke()

                // Fade-out left edge
                var fade = ctx.createLinearGradient(0, 0, width * 0.22, 0)
                fade.addColorStop(0, Qt.rgba(0, 0, 0, 0.8))
                fade.addColorStop(1, Qt.rgba(0, 0, 0, 0))
                ctx.fillStyle = fade
                ctx.fillRect(0, 0, width * 0.22, height)
            }
        }
    }

    // RC6 residency → GPU busy%
    // rc6_residency_ms increments only while GPU is in deep-idle (RC6).
    // busy% = 1 − (Δrc6 / Δwall_time)
    Process {
        id: gpuRc6Proc
        command: ["sh", "-c", "cat /sys/class/drm/card1/gt/gt0/rc6_residency_ms"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var rc6 = parseFloat(data.trim())
                if (isNaN(rc6)) return
                var now = Date.now()
                if (pill.prevRc6Ms >= 0) {
                    var dRc6  = rc6 - pill.prevRc6Ms
                    var dWall = now - pill.prevWallMs
                    if (dWall > 0) {
                        var idlePct = Math.min(100, (dRc6 / dWall) * 100)
                        pill.gpuPct = Math.max(0, Math.round(100 - idlePct))
                    }
                }
                pill.prevRc6Ms  = rc6
                pill.prevWallMs = now
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: gpuRc6Proc.running = true }

    // Current active frequency
    Process {
        id: gpuFreqProc
        command: ["sh", "-c", "cat /sys/class/drm/card1/gt/gt0/rps_act_freq_mhz"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var f = parseInt(data.trim())
                if (!isNaN(f)) pill.gpuFreqMhz = f
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: gpuFreqProc.running = true }

    // Max frequency (read infrequently — rarely changes)
    Process {
        id: gpuMaxFreqProc
        command: ["sh", "-c", "cat /sys/class/drm/card1/gt/gt0/rps_max_freq_mhz"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var f = parseInt(data.trim())
                if (!isNaN(f) && f > 0) pill.gpuMaxFreqMhz = f
            }
        }
    }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: gpuMaxFreqProc.running = true }

    MouseArea { id: gpuHover; anchors.fill: parent; hoverEnabled: true }

    PopupWindow {
        visible: panelRoot.pillsVisible && gpuHover.containsMouse
        implicitWidth: 160
        implicitHeight: 72
        color: "transparent"
        anchor.window: panelRoot
        anchor.item: pill
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 8
            color: panelRoot.colPill
            radius: 10
            Column {
                anchors.centerIn: parent
                spacing: 4
                Text {
                    text: "GPU   " + pill.gpuPct + "%"
                    color: panelRoot.colWsActive
                    font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                }
                Text {
                    text: "Freq  " + pill.gpuFreqMhz + " MHz"
                    color: panelRoot.colWsOccupied
                    font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                }
                Text {
                    text: "Max   " + pill.gpuMaxFreqMhz + " MHz"
                    color: panelRoot.colWsOccupied
                    font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                }
            }
        }
    }
}
