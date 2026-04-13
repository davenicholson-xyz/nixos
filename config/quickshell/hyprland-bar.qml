import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: root

    Theme { id: theme }
    property color colBg:         theme.colBg
    property color colPill:       theme.colPill
    property color colWsActive:   theme.colWsActive
    property color colWsOccupied: theme.colWsOccupied
    property color colWsEmpty:    theme.colWsEmpty
    property color colClock:      theme.colClock
    property color colBarTrack:   theme.colBarTrack
    property color colHigh:       theme.colHigh
    property color colWarn:       theme.colWarn
    property string fontFamily:   theme.fontFamily
    property int fontSize:        theme.fontSize
    property var wsIcons: ["icons/terminal.svg", "icons/browser.svg", "icons/video.svg", "icons/music.svg"]
    property bool pillsVisible: true
    property bool kvmConnected: false
    property bool kvmRemote: false

    Process {
        id: kvmuxProc
        command: ["sh", "-c",
            "R=$(echo '{\"type\":\"status\"}' | /run/current-system/sw/bin/nc -U /tmp/kvmux.sock 2>/dev/null | head -1); " +
            "[ -n \"$R\" ] && echo \"$R\" || echo '{\"connected\":false,\"remote\":false}'"
        ]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (!line) return
                try {
                    var obj = JSON.parse(line)
                    root.kvmConnected = obj.connected === true
                    root.kvmRemote = obj.remote === true
                } catch (e) {
                    root.kvmConnected = false
                    root.kvmRemote = false
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: kvmuxProc.running = true
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "togglePills"
        description: "Toggle info pills"
        onPressed: {
            root.pillsVisible = !root.pillsVisible
            if (root.pillsVisible) { hideAnim.stop(); showAnim.start() }
            else { showAnim.stop(); hideAnim.start() }
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "toggleLauncher"
        description: "Toggle launcher pill"
        onPressed: launcherPill.toggle()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "togglePowerMenu"
        description: "Toggle power menu"
        onPressed: powerMenu.menuOpen ? powerMenu.close() : powerMenu.open()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "toggleRepoMenu"
        description: "Toggle repo session menu"
        onPressed: repoMenu.menuOpen ? repoMenu.close() : repoMenu.open()
    }

    PowerMenu {
        id: powerMenu
        panelRoot: root
        anchorItem: workspacePill
    }

    RepoMenu {
        id: repoMenu
        panelRoot: root
        anchorItem: workspacePill
    }

    ParallelAnimation {
        id: showAnim
        NumberAnimation { target: infoPill; property: "xOff"; to: 0; duration: 220; easing.type: Easing.OutCubic }
        NumberAnimation { target: infoPill; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: hideAnim
        NumberAnimation { target: infoPill; property: "xOff"; to: 24; duration: 160; easing.type: Easing.InCubic }
        NumberAnimation { target: infoPill; property: "opacity"; to: 0; duration: 120; easing.type: Easing.InCubic }
    }

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 30
    color: root.colBg
    WlrLayershell.keyboardFocus: (launcherPill.launcherOpen || powerMenu.menuOpen || repoMenu.menuOpen) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Item {
        anchors.fill: parent
        anchors.topMargin: 4
        anchors.leftMargin: 8
        anchors.rightMargin: 8

        Rectangle {
            id: workspacePill
            anchors.centerIn: parent
            color: root.colPill
            radius: 12
            width: workspaceRow.width + 16
            height: workspaceRow.height + 8
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0; verticalOffset: 0
                radius: 14; samples: 17
                color: Qt.rgba(1, 1, 1, 0.13)
                spread: 0.04
            }

            Row {
                id: workspaceRow
                anchors.centerIn: parent
                spacing: 8

                Repeater {
                    model: 4
                    delegate: Item {
                        property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                        property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                        property color wsColor: isActive ? root.colWsActive : (ws ? root.colWsOccupied : root.colWsEmpty)
                        width: 16; height: 16

                        scale: isActive ? 1.15 : 1.0
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

                        // Halo ring behind icon — slides in when workspace becomes active
                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            color: parent.isActive ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
                            border.color: parent.isActive ? Qt.rgba(1, 1, 1, 0.45) : "transparent"
                            border.width: 1
                            Behavior on color        { ColorAnimation { duration: 200 } }
                            Behavior on border.color { ColorAnimation { duration: 200 } }
                        }

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
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Hyprland.dispatch("workspace " + (index + 1))
                        }
                    }
                }

                Rectangle {
                    width: 4; height: 4
                    radius: 2
                    color: root.colWsEmpty
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.kvmConnected
                }

                Item {
                    width: 14; height: 14
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.kvmConnected

                    Image {
                        id: kvmAppleIcon
                        anchors.fill: parent
                        source: "icons/apple.svg"
                        smooth: true
                        mipmap: true
                        sourceSize.width: 14
                        sourceSize.height: 14
                        visible: false
                        layer.enabled: true
                    }

                    ColorOverlay {
                        anchors.fill: kvmAppleIcon
                        source: kvmAppleIcon
                        color: root.kvmRemote ? "#ffffff" : "#555555"
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
            }
        }

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            MediaPill {
                id: mediaPill
                panelRoot: root
                anchors.verticalCenter: parent.verticalCenter
            }

            LauncherPill {
                id: launcherPill
                panelRoot: root
                anchors.verticalCenter: parent.verticalCenter
            }
        }

RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            InfoPill { id: infoPill; panelRoot: root }

            Item {
                width: 14; height: 14
                Layout.alignment: Qt.AlignVCenter

                Image {
                    id: toggleArrow
                    anchors.fill: parent
                    source: root.pillsVisible ? "icons/right-arrow.svg" : "icons/left-arrow.svg"
                    smooth: true
                    mipmap: true
                    sourceSize.width: 14
                    sourceSize.height: 14
                    visible: false
                    layer.enabled: true
                }
                ColorOverlay {
                    anchors.fill: toggleArrow
                    source: toggleArrow
                    color: root.colPill
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.pillsVisible = !root.pillsVisible
                        if (root.pillsVisible) { hideAnim.stop(); showAnim.start() }
                        else { showAnim.stop(); hideAnim.start() }
                    }
                }
            }

Rectangle {
                color: root.colPill
                radius: 12
                width: clockRow.width + 16
                height: clockRow.height + 10
                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0; verticalOffset: 0
                    radius: 10; samples: 17
                    color: Qt.rgba(1, 1, 1, 0.1)
                    spread: 0.03
                }

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
                            source: "icons/clock.svg"
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

                    // HH:mm with blinking colon synced to wall-clock seconds
                    Text {
                        id: clock
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.colClock
                        font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
                        text: Qt.formatDateTime(new Date(), "HH:mm")
                    }

                    // :ss — same size as HH:mm, slightly dimmed
                    Text {
                        id: clockSecs
                        anchors.verticalCenter: parent.verticalCenter
                        color: Qt.rgba(1, 1, 1, 0.6)
                        font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
                        text: "00"
                    }

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: {
                            var d = new Date()
                            var h = String(d.getHours()).padStart(2, '0')
                            var m = String(d.getMinutes()).padStart(2, '0')
                            var s = String(d.getSeconds()).padStart(2, '0')
                            // Colon blinks on odd seconds (synced to wall clock)
                            clock.text = h + (d.getSeconds() % 2 === 0 ? ":" : " ") + m
                            clockSecs.text = s
                        }
                    }
                }
            }
        }
    }
}
