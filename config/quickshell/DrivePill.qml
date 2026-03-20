import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import Qt5Compat.GraphicalEffects

Rectangle {
    id: pill
    required property var panelRoot

    property real xOff: 0
    property int drivePct: 0
    property string driveInfo: ""
    property real breathPhase: 0.0

    opacity: 1
    transform: Translate { x: pill.xOff }
    color: panelRoot.colPill
    radius: 12
    width: 48
    height: driveRow.height + 10

    Timer {
        interval: 50
        running: true
        repeat: true
        onTriggered: {
            pill.breathPhase = (pill.breathPhase + 0.04) % (Math.PI * 2)
            ringCanvas.requestPaint()
        }
    }

    Row {
        id: driveRow
        anchors.centerIn: parent
        spacing: 5

        Item {
            width: 13; height: 13
            anchors.verticalCenter: parent.verticalCenter

            Image {
                id: driveIcon
                anchors.fill: parent
                source: "icons/drive.svg"
                smooth: true
                mipmap: true
                sourceSize.width: 13
                sourceSize.height: 13
                visible: false
                layer.enabled: true
            }

            ColorOverlay {
                anchors.fill: driveIcon
                source: driveIcon
                color: panelRoot.colClock
            }
        }

        Canvas {
            id: ringCanvas
            anchors.verticalCenter: parent.verticalCenter
            width: 13
            height: 13

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var cx = width / 2
            var cy = height / 2
            var r  = width / 2 - 2

            var color = pill.drivePct >= 95 ? "#e05252"
                      : pill.drivePct >= 80 ? "#e0c94a"
                      : "#4ae09a"

            var breathe = 0.6 + 0.4 * Math.sin(pill.breathPhase)

            // Track
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.08)
            ctx.lineWidth = 2
            ctx.shadowBlur = 0
            ctx.stroke()

            // Usage arc
            var start = -Math.PI / 2
            var end   = start + (pill.drivePct / 100) * Math.PI * 2
            ctx.beginPath()
            ctx.arc(cx, cy, r, start, end)
            ctx.strokeStyle = color
            ctx.lineWidth = 2
            ctx.shadowColor = color
            ctx.shadowBlur = 3 + breathe * 6
            ctx.stroke()
        }
    }
    }

    Process {
        id: driveProc
        command: ["sh", "-c", "df --output=pcent / | tail -1 | tr -d ' '"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var num = parseInt(data.trim())
                if (!isNaN(num)) pill.drivePct = num
            }
        }
    }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: driveProc.running = true }

    Process {
        id: driveInfoProc
        command: ["sh", "-c", "df -h / | awk 'NR==2{print $3\" / \"$2}'"]
        running: true
        stdout: SplitParser { onRead: data => pill.driveInfo = data.trim() }
    }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: driveInfoProc.running = true }

    MouseArea { id: driveHover; anchors.fill: parent; hoverEnabled: true }

    PopupWindow {
        visible: panelRoot.pillsVisible && driveHover.containsMouse
        implicitWidth: 160
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
                    text: "Disk  " + pill.drivePct + "%"
                    color: panelRoot.colWsActive
                    font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                }
                Text {
                    text: pill.driveInfo
                    color: panelRoot.colWsOccupied
                    font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                }
            }
        }
    }
}
