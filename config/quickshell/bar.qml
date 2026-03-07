import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: root

    property color colBg: "#00000000"
    property color colPill: "#99000000"
    property color colWsActive: "#ffffff"
    property color colWsOccupied: "#999999"
    property color colWsEmpty: "#555555"
    property color colClock: "#ffffff"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 13
    property var wsIcons: ["terminal.svg", "browser.svg", "folder.svg"]

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 30
    color: root.colBg

    Item {
        anchors.fill: parent
        anchors.topMargin: 4
        anchors.leftMargin: 8
        anchors.rightMargin: 8

        Rectangle {
            anchors.centerIn: parent
            color: root.colPill
            radius: 12
            width: workspaceRow.width + 16
            height: workspaceRow.height + 8

            Row {
                id: workspaceRow
                anchors.centerIn: parent
                spacing: 8

                Repeater {
                    model: 3
                    delegate: Item {
                        property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                        property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                        property color wsColor: isActive ? root.colWsActive : (ws ? root.colWsOccupied : root.colWsEmpty)
                        width: 16; height: 16

                        Image {
                            id: wsIcon
                            anchors.fill: parent
                            source: root.wsIcons[index]
                            smooth: true
                            mipmap: true
                            sourceSize.width: 16
                            sourceSize.height: 16
                            visible: false
                            layer.enabled: true
                        }

                        ColorOverlay {
                            anchors.fill: wsIcon
                            source: wsIcon
                            color: parent.wsColor
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: Hyprland.dispatch("workspace " + (index + 1))
                        }
                    }
                }
            }
        }

        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Rectangle {
                id: drivePill
                property int drivePct: 0
                color: root.colPill
                radius: 12
                width: 76
                height: driveColumn.height + 10

                Row {
                    id: driveColumn
                    anchors.centerIn: parent
                    spacing: 6

                    Item {
                        width: 13; height: 13
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            id: driveIcon
                            anchors.fill: parent
                            source: "drive.svg"
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
                            color: root.colClock
                        }
                    }

                    Rectangle {
                        width: 44
                        height: 3
                        radius: 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#0d1b4a"

                        Process {
                            id: driveProc
                            command: ["sh", "-c", "df --output=pcent / | tail -1 | tr -d ' '"]
                            running: true
                            stdout: SplitParser {
                                onRead: data => {
                                    var num = parseInt(data.trim())
                                    if (!isNaN(num)) drivePill.drivePct = num
                                }
                            }
                        }

                        Timer {
                            interval: 30000
                            running: true
                            repeat: true
                            onTriggered: driveProc.running = true
                        }

                        Rectangle {
                            width: parent.width * (drivePill.drivePct / 100)
                            height: parent.height
                            radius: 2
                            color: drivePill.drivePct >= 95 ? "#e05252" : drivePill.drivePct >= 90 ? "#e0c94a" : "#3b6fd4"
                        }
                    }
                }
            }

            Rectangle {
                color: root.colPill
                radius: 12
                width: clockRow.width + 16
                height: clockRow.height + 8

                Row {
                    id: clockRow
                    anchors.centerIn: parent
                    spacing: 5

                    Item {
                        width: 13; height: 13
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            id: clockIcon
                            anchors.fill: parent
                            source: "clock.svg"
                            smooth: true
                            mipmap: true
                            sourceSize.width: 13
                            sourceSize.height: 13
                            visible: false
                            layer.enabled: true
                        }

                        ColorOverlay {
                            anchors.fill: clockIcon
                            source: clockIcon
                            color: root.colClock
                        }
                    }

                    Text {
                        id: clock
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.colClock
                        font { family: root.fontFamily; pixelSize: root.fontSize - 2; bold: true }
                        text: Qt.formatDateTime(new Date(), "HH:mm")
                        Timer {
                            interval: 1000
                            running: true
                            repeat: true
                            onTriggered: clock.text = Qt.formatDateTime(new Date(), "HH:mm")
                        }
                    }
                }
            }
        }
    }
}
