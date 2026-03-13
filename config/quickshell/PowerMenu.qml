import Quickshell
import Quickshell.Io
import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: powerMenu
    required property var panelRoot
    required property var anchorItem

    property bool menuOpen: false
    property int selectedIndex: 0

    readonly property var actions: [
        { label: "Shutdown", icon: "icons/shutdown.svg", cmd: ["systemctl", "poweroff"] },
        { label: "Restart",  icon: "icons/restart.svg",  cmd: ["systemctl", "reboot"]  },
        { label: "Lock",     icon: "icons/lock.svg",     cmd: ["loginctl", "lock-session"] },
        { label: "Logout",   icon: "icons/logout.svg",   cmd: ["hyprctl", "dispatch", "exit"] },
    ]

    function open() {
        selectedIndex = 0
        menuInner.opacity = 0
        menuInner.yOff = -8
        menuOpen = true
        openAnim.restart()
        keyHandler.forceActiveFocus()
    }

    function close() {
        menuOpen = false
    }

    function execute(idx) {
        actionProc.command = actions[idx].cmd
        actionProc.running = true
        close()
    }

    Process {
        id: actionProc
        command: ["true"]
    }

    Item {
        id: keyHandler
        Keys.onUpPressed:     if (powerMenu.selectedIndex > 0) powerMenu.selectedIndex--
        Keys.onDownPressed:   if (powerMenu.selectedIndex < powerMenu.actions.length - 1) powerMenu.selectedIndex++
        Keys.onReturnPressed: powerMenu.execute(powerMenu.selectedIndex)
        Keys.onEscapePressed: powerMenu.close()
        Keys.onPressed: event => {
            if (event.key === Qt.Key_K) { if (powerMenu.selectedIndex > 0) powerMenu.selectedIndex--; event.accepted = true }
            else if (event.key === Qt.Key_J) { if (powerMenu.selectedIndex < powerMenu.actions.length - 1) powerMenu.selectedIndex++; event.accepted = true }
        }
    }

    PopupWindow {
        visible: powerMenu.menuOpen
        implicitWidth: 160
        implicitHeight: menuInner.height + 8
        color: "transparent"
        anchor.window: powerMenu.panelRoot
        anchor.item: powerMenu.anchorItem
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        Rectangle {
            id: menuInner
            property real yOff: -8

            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 8 }
            height: menuCol.implicitHeight + 12
            color: powerMenu.panelRoot.colPill
            radius: 12
            opacity: 0
            transform: Translate { y: menuInner.yOff }

            ParallelAnimation {
                id: openAnim
                NumberAnimation { target: menuInner; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
                NumberAnimation { target: menuInner; property: "yOff";    to: 0; duration: 200; easing.type: Easing.OutCubic }
            }

            Column {
                id: menuCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }
                spacing: 2

                Repeater {
                    model: powerMenu.actions
                    delegate: Rectangle {
                        width: parent.width
                        height: 30
                        color: index === powerMenu.selectedIndex ? "#33ffffff" : "transparent"
                        radius: 8

                        Row {
                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            spacing: 8

                            Item {
                                width: 14; height: 14
                                anchors.verticalCenter: parent.verticalCenter

                                Image {
                                    id: actionIcon
                                    anchors.fill: parent
                                    source: modelData.icon
                                    smooth: true
                                    mipmap: true
                                    sourceSize.width: 14
                                    sourceSize.height: 14
                                    visible: false
                                    layer.enabled: true
                                }

                                ColorOverlay {
                                    anchors.fill: actionIcon
                                    source: actionIcon
                                    color: powerMenu.panelRoot.colWsActive
                                }
                            }

                            Text {
                                text: modelData.label
                                color: powerMenu.panelRoot.colWsActive
                                font { family: powerMenu.panelRoot.fontFamily; pixelSize: powerMenu.panelRoot.fontSize - 1 }
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: powerMenu.execute(index)
                            onEntered: powerMenu.selectedIndex = index
                        }
                    }
                }
            }
        }
    }
}
