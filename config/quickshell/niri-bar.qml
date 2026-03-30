import Quickshell
import Quickshell.Wayland
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
    property color colHigh: "#e05252"
    property color colWarn: "#e0c94a"
    property string fontFamily: "SauceCodePro Nerd Font"
    property int fontSize: 13
    property bool pillsVisible: true
    property bool kvmConnected: false
    property bool kvmRemote: false

    // Niri workspace state
    property var niriWorkspaces: []
    property int niriFocusedIdx: 1
    property var niriWindows: []
    property real niriScreenWidth: 3072
    property real niriScreenHeight: 1728

    // Returns [{x,y,w,h,isFocused,isFloating}] with coords normalized to [0,1]
    function windowRectsForWorkspace(wsId) {
        var wins = root.niriWindows.filter(function(w) {
            return w.workspace_id === wsId && w.layout
        })
        if (wins.length === 0) return []

        var sw = root.niriScreenWidth
        var sh = root.niriScreenHeight
        var rects = []

        // Tiled windows: reconstruct positions from pos_in_scrolling_layout + tile_size
        var tiled = wins.filter(function(w) { return !w.is_floating && w.layout.pos_in_scrolling_layout })
        var colMap = {}
        for (var i = 0; i < tiled.length; i++) {
            var w = tiled[i]
            var col = w.layout.pos_in_scrolling_layout[0]
            var row = w.layout.pos_in_scrolling_layout[1]
            if (!colMap[col]) colMap[col] = []
            colMap[col].push({ win: w, row: row })
        }
        var colKeys = Object.keys(colMap).map(Number).sort(function(a, b) { return a - b })
        var curX = 0
        for (var ci = 0; ci < colKeys.length; ci++) {
            var col = colKeys[ci]
            var colWins = colMap[col].sort(function(a, b) { return a.row - b.row })
            var colW = 0
            for (var k = 0; k < colWins.length; k++)
                colW = Math.max(colW, colWins[k].win.layout.tile_size[0])
            var curY = 0
            for (var ri = 0; ri < colWins.length; ri++) {
                var entry = colWins[ri]
                rects.push({
                    x: curX / sw,
                    y: curY / sh,
                    w: entry.win.layout.tile_size[0] / sw,
                    h: entry.win.layout.tile_size[1] / sh,
                    isFocused: entry.win.is_focused,
                    isFloating: false
                })
                curY += entry.win.layout.tile_size[1]
            }
            curX += colW
        }

        // Floating windows: use tile_pos_in_workspace_view if niri provides it
        var floating = wins.filter(function(w) { return w.is_floating })
        for (var fi = 0; fi < floating.length; fi++) {
            var fw = floating[fi]
            var pos = fw.layout.tile_pos_in_workspace_view
            var sz = fw.layout.tile_size
            if (pos && sz) {
                rects.push({
                    x: pos[0] / sw,
                    y: pos[1] / sh,
                    w: sz[0] / sw,
                    h: sz[1] / sh,
                    isFocused: fw.is_focused,
                    isFloating: true
                })
            }
        }

        return rects
    }

    Process {
        id: niriEventStream
        command: ["niri", "msg", "--json", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (!line) return
                try {
                    var ev = JSON.parse(line)
                    if (ev.WorkspacesChanged) {
                        root.niriWorkspaces = ev.WorkspacesChanged.workspaces
                        var focused = ev.WorkspacesChanged.workspaces.find(w => w.is_focused)
                        if (focused) root.niriFocusedIdx = focused.idx
                    } else if (ev.WorkspaceActivated && ev.WorkspaceActivated.focused) {
                        var ws = root.niriWorkspaces.find(w => w.id === ev.WorkspaceActivated.id)
                        if (ws) root.niriFocusedIdx = ws.idx
                    } else if (ev.WindowsChanged) {
                        root.niriWindows = ev.WindowsChanged.windows
                    } else if (ev.WindowOpenedOrChanged) {
                        var win = ev.WindowOpenedOrChanged.window
                        var list = root.niriWindows.slice()
                        var i = list.findIndex(function(x) { return x.id === win.id })
                        if (i >= 0) list[i] = win
                        else list.push(win)
                        root.niriWindows = list
                    } else if (ev.WindowClosed) {
                        root.niriWindows = root.niriWindows.filter(function(x) { return x.id !== ev.WindowClosed.id })
                    }
                } catch(e) {}
            }
        }
    }

    Process {
        id: niriSwitchWs
    }

    Process {
        id: niriOutputsProc
        command: ["niri", "msg", "--json", "outputs"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    var outputs = JSON.parse(data.trim())
                    var keys = Object.keys(outputs)
                    if (keys.length > 0) {
                        var logical = outputs[keys[0]].logical
                        if (logical) {
                            root.niriScreenWidth = logical.width
                            root.niriScreenHeight = logical.height
                        }
                    }
                } catch(e) {}
            }
        }
    }

    Process {
        id: ipcListener
        command: ["sh", "-c", "mkfifo /tmp/qs-niri-ipc 2>/dev/null; while true; do read line < /tmp/qs-niri-ipc && echo \"$line\"; done"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var cmd = data.trim()
                if (cmd === "togglePills") {
                    root.pillsVisible = !root.pillsVisible
                    if (root.pillsVisible) { hideAnim.stop(); showAnim.start() }
                    else { showAnim.stop(); hideAnim.start() }
                } else if (cmd === "toggleLauncher") {
                    launcherPill.toggle()
                } else if (cmd === "togglePowerMenu") {
                    powerMenu.menuOpen ? powerMenu.close() : powerMenu.open()
                }
            }
        }
    }

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
            Behavior on width {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            Row {
                id: workspaceRow
                anchors.centerIn: parent
                spacing: 8

                Repeater {
                    model: root.niriWorkspaces.slice().sort(function(a, b) { return a.idx - b.idx })

                    delegate: Item {
                        id: wsDelegate
                        property bool isActive: root.niriFocusedIdx === modelData.idx
                        property var windowRects: root.windowRectsForWorkspace(modelData.id)

                        width: 30
                        height: 18

                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            color: wsDelegate.isActive ? "#22ffffff" : "transparent"
                            border.color: wsDelegate.isActive ? "#ccffffff" : "#44ffffff"
                            border.width: 1
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                            clip: true

                            Item {
                                id: wsInner
                                anchors { fill: parent; margins: 2 }

                                Repeater {
                                    model: wsDelegate.windowRects

                                    delegate: Rectangle {
                                        x: modelData.x * wsInner.width
                                        y: modelData.y * wsInner.height
                                        width: Math.max(1, modelData.w * wsInner.width)
                                        height: Math.max(1, modelData.h * wsInner.height)
                                        radius: 1
                                        color: modelData.isFocused ? "#ccffffff" : "#55aaaaaa"
                                        border.color: modelData.isFloating ? "#88ffffff" : "transparent"
                                        border.width: modelData.isFloating ? 1 : 0
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                niriSwitchWs.command = ["niri", "msg", "action", "focus-workspace", String(modelData.idx)]
                                niriSwitchWs.running = true
                            }
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
                height: clockRow.height + 6

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
                        font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
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
