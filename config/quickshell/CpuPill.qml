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

    opacity: 0
    transform: Translate { x: pill.xOff }
    color: panelRoot.colPill
    radius: 12
    width: 76
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

        Rectangle {
            width: 44
            height: 3
            radius: 2
            anchors.verticalCenter: parent.verticalCenter
            color: panelRoot.colBarTrack

            Rectangle {
                width: parent.width * (pill.cpuPct / 100)
                height: parent.height
                radius: 2
                color: pill.cpuPct >= 95 ? "#e05252" : pill.cpuPct >= 80 ? "#e0c94a" : panelRoot.colWsActive
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

    MouseArea { id: cpuHover; anchors.fill: parent; hoverEnabled: true }

    PopupWindow {
        visible: panelRoot.pillsVisible && cpuHover.containsMouse
        implicitWidth: 190
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
