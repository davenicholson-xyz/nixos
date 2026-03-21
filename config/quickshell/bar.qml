import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: root

    property color colBg: "#00000000"
    property color colPill: "#cc000000"
    property color colWsActive: "#ffffff"
    property color colWsOccupied: "#999999"
    property color colWsEmpty: "#555555"
    property color colClock: "#ffffff"
    property color colBarTrack: root.colWsEmpty
    property string fontFamily: "SauceCodePro Nerd Font"
    property int fontSize: 13
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

    PowerMenu {
        id: powerMenu
        panelRoot: root
        anchorItem: workspacePill
    }

    SequentialAnimation {
        id: showAnim
        ParallelAnimation {
            NumberAnimation { target: networkPill; property: "xOff"; to: 0; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { target: networkPill; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
        }
        PauseAnimation { duration: 40 }
        ParallelAnimation {
            NumberAnimation { target: drivePill; property: "xOff"; to: 0; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { target: drivePill; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
        }
        PauseAnimation { duration: 40 }
        ParallelAnimation {
            NumberAnimation { target: ramPill; property: "xOff"; to: 0; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { target: ramPill; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
        }
        PauseAnimation { duration: 40 }
        ParallelAnimation {
            NumberAnimation { target: gpuPill; property: "xOff"; to: 0; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { target: gpuPill; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
        }
        PauseAnimation { duration: 40 }
        ParallelAnimation {
            NumberAnimation { target: cpuPill; property: "xOff"; to: 0; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { target: cpuPill; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
        }
    }

    SequentialAnimation {
        id: hideAnim
        ParallelAnimation {
            NumberAnimation { target: cpuPill; property: "xOff"; to: 24; duration: 160; easing.type: Easing.InCubic }
            NumberAnimation { target: cpuPill; property: "opacity"; to: 0; duration: 120; easing.type: Easing.InCubic }
        }
        PauseAnimation { duration: 30 }
        ParallelAnimation {
            NumberAnimation { target: gpuPill; property: "xOff"; to: 24; duration: 160; easing.type: Easing.InCubic }
            NumberAnimation { target: gpuPill; property: "opacity"; to: 0; duration: 120; easing.type: Easing.InCubic }
        }
        PauseAnimation { duration: 30 }
        ParallelAnimation {
            NumberAnimation { target: ramPill; property: "xOff"; to: 24; duration: 160; easing.type: Easing.InCubic }
            NumberAnimation { target: ramPill; property: "opacity"; to: 0; duration: 120; easing.type: Easing.InCubic }
        }
        PauseAnimation { duration: 30 }
        ParallelAnimation {
            NumberAnimation { target: drivePill; property: "xOff"; to: 24; duration: 160; easing.type: Easing.InCubic }
            NumberAnimation { target: drivePill; property: "opacity"; to: 0; duration: 120; easing.type: Easing.InCubic }
        }
        PauseAnimation { duration: 30 }
        ParallelAnimation {
            NumberAnimation { target: networkPill; property: "xOff"; to: 24; duration: 160; easing.type: Easing.InCubic }
            NumberAnimation { target: networkPill; property: "opacity"; to: 0; duration: 120; easing.type: Easing.InCubic }
        }
    }

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 30
    color: root.colBg
    WlrLayershell.keyboardFocus: (launcherPill.launcherOpen || powerMenu.menuOpen) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

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

            SpotifyPill {
                id: spotifyPill
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

            Row {
                spacing: 8

                CpuPill     { id: cpuPill;     panelRoot: root }
                GpuPill     { id: gpuPill;     panelRoot: root }
                RamPill     { id: ramPill;     panelRoot: root }
                DrivePill   { id: drivePill;   panelRoot: root }
                NetworkPill { id: networkPill; panelRoot: root }
            }

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
