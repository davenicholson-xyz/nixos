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
    property color colPill: "#cc000000"
    property color colWsActive: "#ffffff"
    property color colWsOccupied: "#999999"
    property color colWsEmpty: "#555555"
    property color colClock: "#ffffff"
    property color colBarTrack: root.colWsEmpty
    property string fontFamily: "SauceCodePro Nerd Font"
    property int fontSize: 13
    property var wsIcons: ["icons/terminal.svg", "icons/browser.svg", "icons/folder.svg", "icons/music.svg"]
    property bool pillsVisible: false

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

    PopupWindow {
        visible: root.pillsVisible && typeof cpuHover !== "undefined" && cpuHover.containsMouse
        implicitWidth: 190
        implicitHeight: cpuPopupRect.height + 8
        color: "transparent"
        anchor.window: root
        anchor.item: cpuPill
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        Rectangle {
            id: cpuPopupRect
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 8 }
            height: cpuPopupCol.implicitHeight + 20
            color: root.colPill
            radius: 10

            Column {
                id: cpuPopupCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                spacing: 4

                Text {
                    text: "CPU   " + cpuPill.cpuPct + "%"
                    color: root.colWsActive
                    font { family: root.fontFamily; pixelSize: root.fontSize - 2 }
                }
                Text {
                    text: "Temp  " + cpuPill.tempC + "°C"
                    color: cpuPill.tempC >= 90 ? "#e05252" : cpuPill.tempC >= 75 ? "#e0c94a" : root.colWsActive
                    font { family: root.fontFamily; pixelSize: root.fontSize - 2 }
                }
                Rectangle {
                    width: cpuPopupCol.width
                    height: 1
                    color: root.colBarTrack
                    visible: cpuPill.topProcs.length > 0
                }
                Repeater {
                    model: cpuPill.topProcs
                    delegate: Row {
                        width: cpuPopupCol.width
                        Text {
                            text: modelData.name
                            color: root.colWsOccupied
                            font { family: root.fontFamily; pixelSize: root.fontSize - 2 }
                            width: parent.width - 44
                            elide: Text.ElideRight
                        }
                        Text {
                            text: modelData.pct
                            color: root.colWsOccupied
                            font { family: root.fontFamily; pixelSize: root.fontSize - 2 }
                            width: 44
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }
        }
    }

    PopupWindow {
        visible: root.pillsVisible && typeof ramHover !== "undefined" && ramHover.containsMouse
        implicitWidth: 140
        implicitHeight: 60
        color: "transparent"
        anchor.window: root
        anchor.item: ramPill
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 8
            color: root.colPill
            radius: 10
            Column {
                anchors.centerIn: parent
                spacing: 4
                Text {
                    text: "RAM   " + ramPill.ramPct + "%"
                    color: root.colWsActive
                    font { family: root.fontFamily; pixelSize: root.fontSize - 2 }
                }
                Text {
                    text: ramPill.ramInfo
                    color: root.colWsOccupied
                    font { family: root.fontFamily; pixelSize: root.fontSize - 2 }
                }
            }
        }
    }

    PopupWindow {
        visible: root.pillsVisible && typeof driveHover !== "undefined" && driveHover.containsMouse
        implicitWidth: 160
        implicitHeight: 60
        color: "transparent"
        anchor.window: root
        anchor.item: drivePill
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 8
            color: root.colPill
            radius: 10
            Column {
                anchors.centerIn: parent
                spacing: 4
                Text {
                    text: "Disk  " + drivePill.drivePct + "%"
                    color: root.colWsActive
                    font { family: root.fontFamily; pixelSize: root.fontSize - 2 }
                }
                Text {
                    text: drivePill.driveInfo
                    color: root.colWsOccupied
                    font { family: root.fontFamily; pixelSize: root.fontSize - 2 }
                }
            }
        }
    }

    PopupWindow {
        visible: typeof spotifyHover !== "undefined" && spotifyHover.containsMouse && spotifyPill.spotifyRunning
        implicitWidth: 230
        implicitHeight: spotifyPopupRect.height + 8
        color: "transparent"
        anchor.window: root
        anchor.item: spotifyPill
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        Rectangle {
            id: spotifyPopupRect
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 8 }
            height: spotifyPopupRow.implicitHeight + 20
            color: root.colPill
            radius: 10

            Row {
                id: spotifyPopupRow
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                spacing: 10

                Item {
                    width: 56; height: 56
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: popupArtImg
                        anchors.fill: parent
                        source: spotifyPill.artUrl
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        mipmap: true
                        visible: false
                        layer.enabled: true
                    }
                    Rectangle {
                        id: popupArtMask
                        anchors.fill: parent
                        radius: 6
                        visible: false
                        layer.enabled: true
                    }
                    OpacityMask {
                        anchors.fill: parent
                        source: popupArtImg
                        maskSource: popupArtMask
                    }
                }

                Column {
                    id: spotifyPopupCol
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 56 - parent.spacing

                    Text {
                        text: spotifyPill.trackName
                        color: root.colWsActive
                        font { family: root.fontFamily; pixelSize: root.fontSize - 2 }
                        elide: Text.ElideRight
                        width: parent.width
                    }
                    Text {
                        text: spotifyPill.artistName
                        color: root.colWsOccupied
                        font { family: root.fontFamily; pixelSize: root.fontSize - 2 }
                        elide: Text.ElideRight
                        width: parent.width
                    }
                    Text {
                        text: spotifyPill.posStr + " / " + spotifyPill.durStr
                        color: root.colWsEmpty
                        font { family: root.fontFamily; pixelSize: root.fontSize - 2 }
                    }
                }
            }
        }
    }

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

        Rectangle {
            id: spotifyPill
            property bool spotifyRunning: false
            property string spotifyStatus: ""
            property string artUrl: ""
            property real trackProgress: 0
            property string trackName: ""
            property string artistName: ""
            property string posStr: "0:00"
            property string durStr: "0:00"
            property real _durSecs: 0

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            color: root.colPill
            radius: 12
            width: 110
            height: spotifyRow.height + 10

            opacity: spotifyRunning ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            Row {
                id: spotifyRow
                anchors.centerIn: parent
                spacing: 6

                Item {
                    width: 13; height: 13
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: artImg
                        anchors.fill: parent
                        source: spotifyPill.artUrl
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        mipmap: true
                        visible: false
                        layer.enabled: true
                    }
                    Rectangle {
                        id: artMask
                        anchors.fill: parent
                        radius: 3
                        visible: false
                        layer.enabled: true
                    }
                    OpacityMask {
                        anchors.fill: parent
                        source: artImg
                        maskSource: artMask
                    }
                }

                Rectangle {
                    width: 71; height: 3
                    radius: 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.colBarTrack

                    Rectangle {
                        width: parent.width * spotifyPill.trackProgress
                        height: parent.height
                        radius: 2
                        color: root.colWsActive
                        opacity: spotifyPill.spotifyStatus === "Paused" ? 0.4 : 1
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                }
            }

            MouseArea { id: spotifyHover; anchors.fill: parent; hoverEnabled: true }

            Process {
                id: spotifyProc
                command: ["sh", "-c",
                    "S=$(playerctl -p spotify status 2>/dev/null) || { echo 'status:Stopped'; exit 0; }; " +
                    "echo \"status:$S\"; " +
                    "playerctl -p spotify metadata --format $'art:{{mpris:artUrl}}\\ntitle:{{xesam:title}}\\nartist:{{xesam:artist}}\\nlength:{{mpris:length}}' 2>/dev/null; " +
                    "playerctl -p spotify position 2>/dev/null | awk '{print \"pos:\" $1}'"
                ]
                running: true
                stdout: SplitParser {
                    onRead: data => {
                        var line = data.trim()
                        if (line.startsWith("status:")) {
                            var s = line.slice(7)
                            spotifyPill.spotifyStatus = s
                            spotifyPill.spotifyRunning = (s === "Playing" || s === "Paused")
                        } else if (line.startsWith("art:")) {
                            var url = line.slice(4)
                            if (url !== spotifyPill.artUrl) spotifyPill.artUrl = url
                        } else if (line.startsWith("title:")) {
                            spotifyPill.trackName = line.slice(6)
                        } else if (line.startsWith("artist:")) {
                            spotifyPill.artistName = line.slice(7)
                        } else if (line.startsWith("length:")) {
                            spotifyPill._durSecs = parseInt(line.slice(7)) / 1000000
                        } else if (line.startsWith("pos:")) {
                            var pos = parseFloat(line.slice(4))
                            var dur = spotifyPill._durSecs
                            spotifyPill.trackProgress = dur > 0 ? Math.min(pos / dur, 1) : 0
                            var fmt = function(s) {
                                var m = Math.floor(s / 60)
                                var sec = Math.floor(s % 60)
                                return m + ":" + (sec < 10 ? "0" : "") + sec
                            }
                            spotifyPill.posStr = fmt(pos)
                            spotifyPill.durStr = fmt(dur)
                        }
                    }
                }
                onExited: {
                    if (!spotifyPill.spotifyRunning) {
                        spotifyPill.trackProgress = 0
                        spotifyPill.artUrl = ""
                    }
                }
            }

            Timer {
                interval: 2000
                running: true
                repeat: true
                onTriggered: spotifyProc.running = true
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
                property int tempC: 0
                property var topProcs: []
                property var _procBuf: []
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

                Process {
                    id: tempProc
                    command: ["sh", "-c", "cat /sys/class/thermal/thermal_zone1/temp"]
                    running: true
                    stdout: SplitParser {
                        onRead: data => {
                            var num = parseInt(data.trim())
                            if (!isNaN(num)) cpuPill.tempC = Math.round(num / 1000)
                        }
                    }
                }
                Timer { interval: 3000; running: true; repeat: true; onTriggered: tempProc.running = true }

                Process {
                    id: topProcsProc
                    command: ["sh", "-c", "ps -eo comm,%cpu --sort=-%cpu | awk 'NR>1 && $2+0>0 {c++; printf \"%s\\t%s\\n\", $1, $2; if(c>=10) exit}'"]
                    running: true
                    onRunningChanged: if (running) cpuPill._procBuf = []
                    stdout: SplitParser {
                        onRead: data => {
                            var p = data.trim().split("\t")
                            if (p.length >= 2) cpuPill._procBuf.push({name: p[0], pct: p[1] + "%"})
                        }
                    }
                    onExited: cpuPill.topProcs = cpuPill._procBuf.slice()
                }
                Timer { interval: 2000; running: true; repeat: true; onTriggered: topProcsProc.running = true }

                MouseArea { id: cpuHover; anchors.fill: parent; hoverEnabled: true }
            }

            Rectangle {
                id: ramPill
                property real xOff: 24
                property int ramPct: 0
                property string ramInfo: ""
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

                Process {
                    id: ramInfoProc
                    command: ["sh", "-c", "free -h | awk '/^Mem:/{print $3\" / \"$2}'"]
                    running: true
                    stdout: SplitParser { onRead: data => ramPill.ramInfo = data.trim() }
                }
                Timer { interval: 3000; running: true; repeat: true; onTriggered: ramInfoProc.running = true }
                MouseArea { id: ramHover; anchors.fill: parent; hoverEnabled: true }
            }

            Rectangle {
                id: drivePill
                property real xOff: 24
                property int drivePct: 0
                property string driveInfo: ""
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

                Process {
                    id: driveInfoProc
                    command: ["sh", "-c", "df -h / | awk 'NR==2{print $3\" / \"$2}'"]
                    running: true
                    stdout: SplitParser { onRead: data => drivePill.driveInfo = data.trim() }
                }
                Timer { interval: 30000; running: true; repeat: true; onTriggered: driveInfoProc.running = true }
                MouseArea { id: driveHover; anchors.fill: parent; hoverEnabled: true }
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
