import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import Qt5Compat.GraphicalEffects

Rectangle {
    id: pill
    required property var panelRoot

    property real xOff: 24
    property int ramPct: 0
    property string ramInfo: ""

    opacity: 0
    transform: Translate { x: pill.xOff }
    color: panelRoot.colPill
    radius: 12
    width: 76
    height: ramRow.height + 10

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

        Rectangle {
            width: 44
            height: 3
            radius: 2
            anchors.verticalCenter: parent.verticalCenter
            color: panelRoot.colBarTrack

            Rectangle {
                width: parent.width * (pill.ramPct / 100)
                height: parent.height
                radius: 2
                color: pill.ramPct >= 95 ? "#e05252" : pill.ramPct >= 80 ? "#e0c94a" : panelRoot.colWsActive
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
