import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import Qt5Compat.GraphicalEffects

Rectangle {
    id: pill
    required property var panelRoot

    property real xOff: 0
    property int ramPct: 0
    property string ramInfo: ""
    property real sloshPhase: 0.0

    opacity: 1
    transform: Translate { x: pill.xOff }
    color: panelRoot.colPill
    radius: 12
    width: 96
    height: ramRow.height + 10

    Timer {
        interval: 40
        running: true
        repeat: true
        onTriggered: {
            pill.sloshPhase += 0.05
            lavaCanvas.requestPaint()
        }
    }

    Row {
        id: ramRow
        anchors.centerIn: parent
        spacing: 6

        Item {
            width: 13; height: 13
            anchors.verticalCenter: parent.verticalCenter

            Image {
                id: ramIcon
                anchors.fill: parent
                source: "icons/ram.svg"
                smooth: true
                mipmap: true
                sourceSize.width: 13
                sourceSize.height: 13
                visible: false
                layer.enabled: true
            }

            ColorOverlay {
                anchors.fill: ramIcon
                source: ramIcon
                color: panelRoot.colClock
            }
        }

        Canvas {
            id: lavaCanvas
            width: 64
            height: 13
            anchors.verticalCenter: parent.verticalCenter

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var cr, cg, cb, color
                if (pill.ramPct >= 95)      { cr=0.878; cg=0.322; cb=0.322; color="#e05252" }
                else if (pill.ramPct >= 80) { cr=0.878; cg=0.788; cb=0.290; color="#e0c94a" }
                else                        { cr=0.290; cg=0.647; cb=0.878; color="#4aa6e0" }

                var phase      = pill.sloshPhase
                var fillHeight = Math.max(2, (pill.ramPct / 100) * height)
                var baseY      = height - fillHeight

                // Build surface points: tilt slosh + small ripple
                var pts = []
                for (var x = 0; x <= width; x++) {
                    var slosh  = Math.sin(phase * 0.7) * 2.0 * (x / width - 0.5)
                    var ripple = Math.sin(x * 0.28 + phase * 1.8) * 0.7
                            + Math.sin(x * 0.11 - phase * 1.1) * 0.4
                    pts.push(baseY + slosh + ripple)
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
                grad.addColorStop(1, Qt.rgba(cr, cg, cb, 0.20))
                ctx.fillStyle = grad
                ctx.shadowBlur = 0
                ctx.fill()

                // Glowing surface line
                ctx.beginPath()
                ctx.moveTo(0, pts[0])
                for (var j = 1; j < pts.length; j++) ctx.lineTo(j, pts[j])
                ctx.strokeStyle = color
                ctx.lineWidth   = 1.5
                ctx.lineJoin    = "round"
                ctx.shadowColor = color
                ctx.shadowBlur  = 4
                ctx.stroke()
            }
        }
    }

    Process {
        id: ramProc
        command: ["sh", "-c", "awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf \"%.0f\", (t-a)/t*100}' /proc/meminfo"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var num = parseInt(data.trim())
                if (!isNaN(num)) pill.ramPct = num
            }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: ramProc.running = true }

    Process {
        id: ramInfoProc
        command: ["sh", "-c", "free -h | awk '/^Mem:/{print $3\" / \"$2}'"]
        running: true
        stdout: SplitParser { onRead: data => pill.ramInfo = data.trim() }
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: ramInfoProc.running = true }

    MouseArea { id: ramHover; anchors.fill: parent; hoverEnabled: true }

    PopupWindow {
        visible: panelRoot.pillsVisible && ramHover.containsMouse
        implicitWidth: 140
        implicitHeight: 60
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
                    text: "RAM   " + pill.ramPct + "%"
                    color: panelRoot.colWsActive
                    font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                }
                Text {
                    text: pill.ramInfo
                    color: panelRoot.colWsOccupied
                    font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                }
            }
        }
    }
}
