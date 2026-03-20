import Quickshell
import Quickshell.Io
import QtQuick

Rectangle {
    id: pill
    required property var panelRoot

    property int cpuPct: 0
    property int prevTotal: 0
    property int prevIdle: 0
    property real beatPhase: 0.0
    property var samples: []
    property int maxSamples: 80

    color: panelRoot.colPill
    radius: 12
    width: 90
    height: ecgCanvas.height + 10

    // CPU polling — reuse same interval as CpuPill
    Process {
        id: cpuProc
        command: ["sh", "-c", "awk '/^cpu /{print $2+$3+$4+$5+$6+$7+$8, $5}' /proc/stat"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(" ")
                var total = parseInt(parts[0])
                var idle  = parseInt(parts[1])
                if (pill.prevTotal !== 0) {
                    var dt = total - pill.prevTotal
                    var di = idle  - pill.prevIdle
                    if (dt > 0) pill.cpuPct = Math.round((1 - di / dt) * 100)
                }
                pill.prevTotal = total
                pill.prevIdle  = idle
            }
        }
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: cpuProc.running = true }

    // Animation tick — 40ms ≈ 25fps
    Timer {
        interval: 40
        running: true
        repeat: true
        onTriggered: {
            // 50 BPM idle → 160 BPM at 100% CPU
            var bpm = 50 + (pill.cpuPct / 100) * 110
            pill.beatPhase = (pill.beatPhase + (bpm / 60) * 0.04) % 1.0

            var arr = pill.samples.slice()
            arr.push(pill.ecgSample(pill.beatPhase))
            if (arr.length > pill.maxSamples) arr.shift()
            pill.samples = arr

            ecgCanvas.requestPaint()
        }
    }

    // PQRST waveform — phase 0..1 is one full beat cycle
    function ecgSample(phase) {
        var t
        // P wave
        if (phase >= 0.08 && phase < 0.18) {
            t = (phase - 0.08) / 0.10
            return 0.18 * Math.sin(Math.PI * t)
        }
        // Q dip
        if (phase >= 0.26 && phase < 0.30) {
            t = (phase - 0.26) / 0.04
            return -0.12 * Math.sin(Math.PI * t)
        }
        // R spike
        if (phase >= 0.30 && phase < 0.38) {
            t = (phase - 0.30) / 0.08
            return Math.sin(Math.PI * t)
        }
        // S dip
        if (phase >= 0.38 && phase < 0.43) {
            t = (phase - 0.38) / 0.05
            return -0.18 * Math.sin(Math.PI * t)
        }
        // T wave
        if (phase >= 0.48 && phase < 0.68) {
            t = (phase - 0.48) / 0.20
            return 0.28 * Math.sin(Math.PI * t)
        }
        return 0.0
    }

    Canvas {
        id: ecgCanvas
        anchors.centerIn: parent
        width: 72
        height: 13

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var s = pill.samples
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
                var x = (i / (pill.maxSamples - 1)) * width
                var y = midY - s[i] * amp
                if (i === 0) ctx.moveTo(x, y)
                else ctx.lineTo(x, y)
            }
            ctx.stroke()

            // Faint trailing fade on the left edge
            var grad = ctx.createLinearGradient(0, 0, width * 0.25, 0)
            grad.addColorStop(0, Qt.rgba(0, 0, 0, 0.8))
            grad.addColorStop(1, Qt.rgba(0, 0, 0, 0))
            ctx.fillStyle = grad
            ctx.fillRect(0, 0, width * 0.25, height)
        }
    }
}
