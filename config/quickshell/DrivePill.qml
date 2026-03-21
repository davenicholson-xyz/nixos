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
    property real readSweep:  0.0
    property real writeSweep: 0.0
    property real readSpeed:  0
    property real writeSpeed: 0
    property real prevRead:   0
    property real prevWrite:  0
    property bool firstIO:    true
    property real maxIO:      500000   // sectors/sec (~250MB/s)

    opacity: 1
    transform: Translate { x: pill.xOff }
    color: panelRoot.colPill
    radius: 12
    width: 48
    height: driveRow.height + 10

    Timer {
        interval: 100
        running: panelRoot.pillsVisible
        repeat: true
        onTriggered: {
            var base  = 0.06
            var rBoost = Math.log1p(pill.readSpeed)  / Math.log1p(pill.maxIO) * 0.44
            var wBoost = Math.log1p(pill.writeSpeed) / Math.log1p(pill.maxIO) * 0.44
            pill.readSweep  = (pill.readSweep  + base + rBoost + Math.PI * 2) % (Math.PI * 2)
            pill.writeSweep = (pill.writeSweep - base - wBoost + Math.PI * 2) % (Math.PI * 2)
            ringCanvas.requestPaint()
        }
    }

    Process {
        id: diskIOProc
        command: ["sh", "-c", "awk '$3~/^(sd[a-z]$|nvme[0-9]n[0-9]$|vd[a-z]$)/{r+=$6; w+=$10} END{print r+0, w+0}' /proc/diskstats"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var p = data.trim().split(" ")
                if (p.length < 2) return
                var r = parseFloat(p[0]), w = parseFloat(p[1])
                if (!pill.firstIO) {
                    pill.readSpeed  = Math.max(0, r - pill.prevRead)
                    pill.writeSpeed = Math.max(0, w - pill.prevWrite)
                }
                pill.firstIO   = false
                pill.prevRead  = r
                pill.prevWrite = w
            }
        }
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: diskIOProc.running = true }

    Row {
        id: driveRow
        anchors.centerIn: parent
        spacing: 5

        Item {
            width: 13; height: 13
            anchors.verticalCenter: parent.verticalCenter

            // Mask image — rendered offscreen, used by both layers
            Image {
                id: driveIconMask
                anchors.fill: parent
                source: "icons/drive.svg"
                smooth: true; mipmap: true
                sourceSize.width: 13; sourceSize.height: 13
                visible: false
                layer.enabled: true
            }

            // Dim base — full icon, always visible
            ColorOverlay {
                anchors.fill: driveIconMask
                source: driveIconMask
                color: panelRoot.colWsEmpty
            }

            // Coloured fill rising from the bottom, clipped to icon shape
            Item {
                anchors.fill: parent
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: driveIconMask
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left:   parent.left
                    anchors.right:  parent.right
                    height: parent.height * (pill.drivePct / 100)
                    color:  pill.drivePct >= 95 ? "#e05252"
                          : pill.drivePct >= 80 ? "#e0c94a"
                          : "#4ae09a"
                }
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
            var r  = width / 2 - 1.5

            // Dim track
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.07)
            ctx.lineWidth   = 1.5
            ctx.shadowBlur  = 0
            ctx.stroke()

            // Always draw clockwise arcs — for the write sweep (moving CCW)
            // the tail sits at angle+tailLen so it still trails correctly
            function drawSweep(headAngle, tailAngle, color) {
                // Faded tail
                ctx.beginPath()
                ctx.arc(cx, cy, r, tailAngle, headAngle)
                ctx.strokeStyle = color
                ctx.globalAlpha = 0.3
                ctx.lineWidth   = 1.5
                ctx.stroke()
                ctx.globalAlpha = 1.0

                // Bright head
                ctx.beginPath()
                ctx.arc(cx, cy, r, headAngle - 0.15, headAngle)
                ctx.strokeStyle = color
                ctx.lineWidth   = 2.0
                ctx.stroke()

                // Tip dot
                ctx.beginPath()
                ctx.arc(cx + r * Math.cos(headAngle), cy + r * Math.sin(headAngle), 1.5, 0, Math.PI * 2)
                ctx.fillStyle  = color
                ctx.fill()
            }

            // Read: clockwise — tail behind head
            drawSweep(pill.readSweep, pill.readSweep - 0.55, "#4ac4e0")
            // Write: counter-clockwise — tail ahead (in CW terms)
            drawSweep(pill.writeSweep + 0.55, pill.writeSweep, "#e07840")
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
                Text {
                    text: "↓ " + Math.round(pill.readSpeed  * 512 / 1024) + " KB/s  "
                        + "↑ " + Math.round(pill.writeSpeed * 512 / 1024) + " KB/s"
                    color: panelRoot.colWsOccupied
                    font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                }
            }
        }
    }
}
