import Quickshell
import Quickshell.Io
import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: repoMenu
    required property var panelRoot
    required property var anchorItem

    property bool menuOpen: false
    property int selectedIndex: 0
    property var repos: []
    property var _tmpRepos: []
    property var activeSessions: []
    property var _tmpSessions: []

    // sessions not backed by a repo folder
    readonly property var otherSessions: activeSessions.filter(s => repos.indexOf(s) === -1)

    // total navigable entries
    readonly property int totalCount: repos.length + otherSessions.length

    Process {
        id: listProc
        command: ["sh", "-c", "ls -1p /home/dave/repos/ 2>/dev/null | grep '/$' | sed 's|/$||' | sort"]
        stdout: SplitParser {
            onRead: data => {
                var name = data.trim()
                if (name.length > 0)
                    repoMenu._tmpRepos.push(name)
            }
        }
        onExited: {
            repoMenu.repos = repoMenu._tmpRepos.slice()
            repoMenu._tmpRepos = []
            sessionProc.running = true
        }
    }

    Process {
        id: sessionProc
        command: ["tmux", "list-sessions", "-F", "#{session_name}"]
        stdout: SplitParser {
            onRead: data => {
                var name = data.trim()
                if (name.length > 0)
                    repoMenu._tmpSessions.push(name)
            }
        }
        onExited: {
            repoMenu.activeSessions = repoMenu._tmpSessions.slice()
            repoMenu._tmpSessions = []
        }
    }

    Process {
        id: openProc
        command: ["true"]
    }

    Process {
        id: killProc
        command: ["true"]
    }

    function hasSession(name) {
        return activeSessions.indexOf(name) !== -1
    }

    // Returns the tmux session name for the given flat index, or "" if none
    function sessionForIndex(idx) {
        if (idx < repos.length)
            return hasSession(repos[idx]) ? repos[idx] : ""
        return otherSessions[idx - repos.length]
    }

    function open() {
        _tmpRepos = []
        _tmpSessions = []
        activeSessions = []
        listProc.running = true
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
        if (idx < repos.length) {
            openProc.command = [
                "/home/dave/nixos/bin/tmux-repo",
                "/home/dave/repos/" + repos[idx]
            ]
        } else {
            var session = otherSessions[idx - repos.length]
            openProc.command = ["kitty", "sh", "-c", "tmux attach-session -t '" + session + "'"]
        }
        openProc.running = true
        close()
    }

    function killSession(idx) {
        var session = sessionForIndex(idx)
        if (session === "") return
        killProc.command = ["tmux", "kill-session", "-t", session]
        killProc.running = true
        // refresh the session list in place
        _tmpSessions = []
        sessionProc.running = true
    }

    Item {
        id: keyHandler
        Keys.onUpPressed:     if (repoMenu.selectedIndex > 0) repoMenu.selectedIndex--
        Keys.onDownPressed:   if (repoMenu.selectedIndex < repoMenu.totalCount - 1) repoMenu.selectedIndex++
        Keys.onReturnPressed: if (repoMenu.totalCount > 0) repoMenu.execute(repoMenu.selectedIndex)
        Keys.onEscapePressed: repoMenu.close()
        Keys.onPressed: event => {
            if (event.key === Qt.Key_K) {
                if (repoMenu.selectedIndex > 0) repoMenu.selectedIndex--
                event.accepted = true
            } else if (event.key === Qt.Key_J) {
                if (repoMenu.selectedIndex < repoMenu.totalCount - 1) repoMenu.selectedIndex++
                event.accepted = true
            } else if (event.key === Qt.Key_D) {
                repoMenu.killSession(repoMenu.selectedIndex)
                event.accepted = true
            }
        }
    }

    PopupWindow {
        visible: repoMenu.menuOpen
        implicitWidth: 200
        implicitHeight: menuInner.height + 8
        color: "transparent"
        anchor.window: repoMenu.panelRoot
        anchor.item: repoMenu.anchorItem
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        Rectangle {
            id: menuInner
            property real yOff: -8

            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 8 }
            height: menuCol.implicitHeight + 12
            color: repoMenu.panelRoot.colPill
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

                // ── repo entries ──────────────────────────────────────────
                Repeater {
                    model: repoMenu.repos
                    delegate: Rectangle {
                        width: parent.width
                        height: 30
                        color: index === repoMenu.selectedIndex ? "#33ffffff" : "transparent"
                        radius: 8

                        Row {
                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            spacing: 8

                            Item {
                                width: 14; height: 14
                                anchors.verticalCenter: parent.verticalCenter

                                Image {
                                    id: folderIcon
                                    anchors.fill: parent
                                    source: "icons/folder.svg"
                                    smooth: true
                                    mipmap: true
                                    sourceSize.width: 14
                                    sourceSize.height: 14
                                    visible: false
                                    layer.enabled: true
                                }

                                ColorOverlay {
                                    anchors.fill: folderIcon
                                    source: folderIcon
                                    color: repoMenu.hasSession(modelData) ? "#fe8019" : repoMenu.panelRoot.colWsActive
                                }
                            }

                            Text {
                                text: modelData
                                color: repoMenu.panelRoot.colWsActive
                                font { family: repoMenu.panelRoot.fontFamily; pixelSize: repoMenu.panelRoot.fontSize - 1 }
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: repoMenu.execute(index)
                            onEntered: repoMenu.selectedIndex = index
                        }
                    }
                }

                // ── separator ─────────────────────────────────────────────
                Rectangle {
                    visible: repoMenu.otherSessions.length > 0
                    width: parent.width - 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 1
                    color: "#33ffffff"
                }

                // ── other tmux sessions ───────────────────────────────────
                Repeater {
                    model: repoMenu.otherSessions
                    delegate: Rectangle {
                        readonly property int flatIndex: repoMenu.repos.length + index
                        width: parent.width
                        height: 30
                        color: flatIndex === repoMenu.selectedIndex ? "#33ffffff" : "transparent"
                        radius: 8

                        Row {
                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            spacing: 8

                            Item {
                                width: 14; height: 14
                                anchors.verticalCenter: parent.verticalCenter

                                Image {
                                    id: termIcon
                                    anchors.fill: parent
                                    source: "icons/terminal.svg"
                                    smooth: true
                                    mipmap: true
                                    sourceSize.width: 14
                                    sourceSize.height: 14
                                    visible: false
                                    layer.enabled: true
                                }

                                ColorOverlay {
                                    anchors.fill: termIcon
                                    source: termIcon
                                    color: "#fe8019"
                                }
                            }

                            Text {
                                text: modelData
                                color: repoMenu.panelRoot.colWsActive
                                font { family: repoMenu.panelRoot.fontFamily; pixelSize: repoMenu.panelRoot.fontSize - 1 }
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: repoMenu.execute(flatIndex)
                            onEntered: repoMenu.selectedIndex = flatIndex
                        }
                    }
                }
            }
        }
    }
}
