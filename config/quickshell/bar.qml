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
    property color colBarTrack: root.colWsEmpty
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 13
    property var wsIcons: ["terminal.svg", "browser.svg", "folder.svg", "music.svg"]
    property bool pillsVisible: false

    SequentialAnimation {
        id: showAnim
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
            NumberAnimation { target: ramPill; property: "xOff"; to: 24; duration: 160; easing.type: Easing.InCubic }
            NumberAnimation { target: ramPill; property: "opacity"; to: 0; duration: 120; easing.type: Easing.InCubic }
        }
        PauseAnimation { duration: 30 }
        ParallelAnimation {
            NumberAnimation { target: drivePill; property: "xOff"; to: 24; duration: 160; easing.type: Easing.InCubic }
            NumberAnimation { target: drivePill; property: "opacity"; to: 0; duration: 120; easing.type: Easing.InCubic }
        }
    }

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
            }
        }

        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Row {
                spacing: 8

            Rectangle {
                id: cpuPill
                property real xOff: 24
                property int prevTotal: 0
                property int prevIdle: 0
                property int cpuPct: 0
                opacity: 0
                transform: Translate { x: cpuPill.xOff }
                color: root.colPill
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
                            source: "cpu.svg"
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
                            color: root.colClock
                        }
                    }

                    Rectangle {
                        width: 44
                        height: 3
                        radius: 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.colBarTrack

                        Process {
                            id: cpuProc
                            command: ["sh", "-c", "awk '/^cpu /{print $2+$3+$4+$5+$6+$7+$8, $5}' /proc/stat"]
                            running: true
                            stdout: SplitParser {
                                onRead: data => {
                                    var parts = data.trim().split(" ")
                                    var total = parseInt(parts[0])
                                    var idle = parseInt(parts[1])
                                    if (cpuPill.prevTotal !== 0) {
                                        var dt = total - cpuPill.prevTotal
                                        var di = idle - cpuPill.prevIdle
                                        if (dt > 0) cpuPill.cpuPct = Math.round((1 - di / dt) * 100)
                                    }
                                    cpuPill.prevTotal = total
                                    cpuPill.prevIdle = idle
                                }
                            }
                        }

                        Timer {
                            interval: 2000
                            running: true
                            repeat: true
                            onTriggered: cpuProc.running = true
                        }

                        Rectangle {
                            width: parent.width * (cpuPill.cpuPct / 100)
                            height: parent.height
                            radius: 2
                            color: cpuPill.cpuPct >= 95 ? "#e05252" : cpuPill.cpuPct >= 80 ? "#e0c94a" : root.colWsActive
                        }
                    }
                }
            }

            Rectangle {
                id: ramPill
                property real xOff: 24
                property int ramPct: 0
                opacity: 0
                transform: Translate { x: ramPill.xOff }
                color: root.colPill
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
                            source: "ram.svg"
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
                            color: root.colClock
                        }
                    }

                    Rectangle {
                        width: 44
                        height: 3
                        radius: 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.colBarTrack

                        Process {
                            id: ramProc
                            command: ["sh", "-c", "awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf \"%.0f\", (t-a)/t*100}' /proc/meminfo"]
                            running: true
                            stdout: SplitParser {
                                onRead: data => {
                                    var num = parseInt(data.trim())
                                    if (!isNaN(num)) ramPill.ramPct = num
                                }
                            }
                        }

                        Timer {
                            interval: 3000
                            running: true
                            repeat: true
                            onTriggered: ramProc.running = true
                        }

                        Rectangle {
                            width: parent.width * (ramPill.ramPct / 100)
                            height: parent.height
                            radius: 2
                            color: ramPill.ramPct >= 95 ? "#e05252" : ramPill.ramPct >= 80 ? "#e0c94a" : root.colWsActive
                        }
                    }
                }
            }

            Rectangle {
                id: drivePill
                property real xOff: 24
                property int drivePct: 0
                opacity: 0
                transform: Translate { x: drivePill.xOff }
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
                        color: root.colBarTrack

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
                            color: drivePill.drivePct >= 95 ? "#e05252" : drivePill.drivePct >= 80 ? "#e0c94a" : root.colWsActive
                        }
                    }
                }
            }
            } // Row

            Rectangle {
                width: 8; height: 8
                radius: 4
                Layout.alignment: Qt.AlignVCenter
                color: root.pillsVisible ? root.colPill : root.colWsEmpty
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
