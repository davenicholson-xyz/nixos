import Quickshell
import Quickshell.Io
import QtQuick
import Qt5Compat.GraphicalEffects

Rectangle {
    id: pill
    required property var panelRoot

    property var appList: []
    property var _tmpList: []
    property var filteredApps: []
    property int selectedIndex: 0
    property bool popupOpen: false
    property bool launcherOpen: false
    property real xOff: -24

    opacity: 0
    transform: Translate { x: pill.xOff }

    color: panelRoot.colPill
    radius: 12
    width: launcherRow.width + 16
    height: 23

    function toggle() {
        if (pill.launcherOpen) {
            pill.launcherOpen = false
            showAnim.stop(); hideAnim.start()
        } else {
            pill.launcherOpen = true
            hideAnim.stop(); showAnim.start()
        }
    }

    SequentialAnimation {
        id: showAnim
        ParallelAnimation {
            NumberAnimation { target: pill; property: "xOff"; to: 0; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { target: pill; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
        }
        ScriptAction { script: searchInput.forceActiveFocus() }
    }

    SequentialAnimation {
        id: hideAnim
        ParallelAnimation {
            NumberAnimation { target: pill; property: "xOff"; to: -24; duration: 160; easing.type: Easing.InCubic }
            NumberAnimation { target: pill; property: "opacity"; to: 0; duration: 120; easing.type: Easing.InCubic }
        }
        ScriptAction {
            script: {
                searchInput.text = ""
                pill.filteredApps = []
                pill.popupOpen = false
            }
        }
    }

    Process {
        id: appListProc
        command: ["sh", "-c",
            "{ ls -1 /run/current-system/sw/bin; ls -1 /home/dave/.nix-profile/bin; ls -1 /etc/profiles/per-user/dave/bin; } 2>/dev/null | grep -v '/' | sort -u"
        ]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var name = data.trim()
                if (name.length > 0)
                    pill._tmpList.push(name)
            }
        }
        onExited: {
            pill.appList = pill._tmpList.slice()
        }
    }

    Process {
        id: launchProc
        command: ["sh", "-c", "true"]
    }

    function filterApps(query) {
        if (query.length === 0) {
            filteredApps = []
            selectedIndex = 0
            popupOpen = false
            return
        }
        var q = query.toLowerCase()
        var scored = []
        for (var i = 0; i < appList.length; i++) {
            var name = appList[i].toLowerCase()
            if (name.startsWith(q))
                scored.push({ name: appList[i], score: 2 })
            else if (name.includes(q))
                scored.push({ name: appList[i], score: 1 })
        }
        scored.sort(function(a, b) { return b.score - a.score || a.name.localeCompare(b.name) })
        filteredApps = scored.slice(0, 5).map(function(x) { return x.name })
        selectedIndex = 0
        popupOpen = filteredApps.length > 0
    }

    function launch(appName) {
        launchProc.command = ["/bin/sh", "-c", "\"$1\" </dev/null >/dev/null 2>&1 &", "--", appName]
        launchProc.running = true
        pill.launcherOpen = false
        showAnim.stop(); hideAnim.start()
    }

    Row {
        id: launcherRow
        anchors.centerIn: parent
        spacing: 6

        Item {
            width: 13; height: 13
            anchors.verticalCenter: parent.verticalCenter

            Image {
                id: launcherIcon
                anchors.fill: parent
                source: "icons/launcher.svg"
                smooth: true
                mipmap: true
                sourceSize.width: 13
                sourceSize.height: 13
                visible: false
                layer.enabled: true
            }

            ColorOverlay {
                anchors.fill: launcherIcon
                source: launcherIcon
                color: panelRoot.colWsActive
            }
        }

        Item {
            width: 120
            height: 13
            anchors.verticalCenter: parent.verticalCenter

            TextInput {
                id: searchInput
                anchors.fill: parent
                color: panelRoot.colWsActive
                font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                clip: true
                selectByMouse: true

                Keys.onUpPressed: {
                    if (pill.selectedIndex > 0) pill.selectedIndex--
                }
                Keys.onDownPressed: {
                    if (pill.selectedIndex < pill.filteredApps.length - 1) pill.selectedIndex++
                }
                Keys.onReturnPressed: {
                    if (pill.filteredApps.length > 0)
                        pill.launch(pill.filteredApps[pill.selectedIndex])
                    else if (text.length > 0)
                        pill.launch(text)
                }
                Keys.onEscapePressed: {
                    pill.launcherOpen = false
                    showAnim.stop(); hideAnim.start()
                }
                onTextChanged: pill.filterApps(text)
            }

            Text {
                anchors.fill: parent
                text: "launch app..."
                color: panelRoot.colWsEmpty
                font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                visible: searchInput.text.length === 0
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: searchInput.forceActiveFocus()
        z: -1
    }

    PopupWindow {
        visible: pill.popupOpen
        implicitWidth: pill.width
        implicitHeight: popupInner.height + 8
        color: "transparent"
        anchor.window: panelRoot
        anchor.item: pill
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        Rectangle {
            id: popupInner
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 8 }
            height: popupCol.implicitHeight + 8
            color: panelRoot.colPill
            radius: 10

            Column {
                id: popupCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 4 }

                Repeater {
                    model: pill.filteredApps
                    delegate: Rectangle {
                        width: parent.width
                        height: 22
                        color: index === pill.selectedIndex ? "#33ffffff" : "transparent"
                        radius: 6

                        Text {
                            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                            text: modelData
                            color: panelRoot.colWsActive
                            font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: pill.launch(modelData)
                            onEntered: pill.selectedIndex = index
                        }
                    }
                }
            }
        }
    }
}
