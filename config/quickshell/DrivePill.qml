import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import Qt5Compat.GraphicalEffects

Rectangle {
    id: pill
    required property var panelRoot

    property real xOff: 24
    property int drivePct: 0
    property string driveInfo: ""

    opacity: 0
    transform: Translate { x: pill.xOff }
    color: panelRoot.colPill
    radius: 12
    width: 76
    height: driveRow.height + 10

    Row {
        id: driveRow
        anchors.centerIn: parent
        spacing: 6

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

        Rectangle {
            width: 44
            height: 3
            radius: 2
            anchors.verticalCenter: parent.verticalCenter
            color: panelRoot.colBarTrack

            Rectangle {
                width: parent.width * (pill.drivePct / 100)
                height: parent.height
                radius: 2
                color: pill.drivePct >= 95 ? "#e05252" : pill.drivePct >= 80 ? "#e0c94a" : panelRoot.colWsActive
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
