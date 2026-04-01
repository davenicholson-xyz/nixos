import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import Qt5Compat.GraphicalEffects

Rectangle {
    id: pill
    required property var panelRoot

    property bool mediaRunning: false
    property string mediaStatus: ""
    property string artUrl: ""
    property real trackProgress: 0
    property string trackName: ""
    property string artistName: ""
    property string playerName: ""
    property string posStr: "0:00"
    property string durStr: "0:00"
    property real _durSecs: 0
    property real _posSecs: 0
    property string albumName: ""
    property var cavaValues: [0,0,0,0,0,0,0,0,0,0,0,0]
    property int vizScheme: 0
    readonly property int vizSchemeCount: 6

    function vizColor(i) {
        var t = i / 11
        switch (vizScheme) {
            case 0: return Qt.hsla(t, 0.85, 0.65, 1.0)
            case 1: return Qt.hsla(t * 0.17, 0.95, 0.55 + t * 0.1, 1.0)
            case 2: return Qt.hsla(0.5 + t * 0.17, 0.8, 0.55 + t * 0.1, 1.0)
            case 3: return Qt.hsla(0.72 + t * 0.18, 0.85, 0.6 + t * 0.1, 1.0)
            case 4: return Qt.hsla(0.33, 0.75, 0.28 + t * 0.38, 1.0)
            case 5: return Qt.hsla(0, 0, 0.45 + t * 0.45, 1.0)
        }
    }

    function fmtSecs(s) {
        var m = Math.floor(s / 60)
        var sec = Math.floor(s % 60)
        return m + ":" + (sec < 10 ? "0" : "") + sec
    }

    function runPlayerctl(args) {
        ctlProc.cmdStr = args
        ctlProc.running = true
    }

    color: panelRoot.colPill
    radius: 12
    width: mediaRow.width + 20
    height: mediaRow.height + 10

    Behavior on width {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    opacity: mediaRunning ? 1 : 0
    visible: opacity > 0
    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    Row {
        id: mediaRow
        anchors.centerIn: parent
        spacing: 12

        // Album art thumbnail
        Item {
            width: 13; height: 13
            anchors.verticalCenter: parent.verticalCenter

            Image {
                id: artImg
                anchors.fill: parent
                source: pill.artUrl
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

        // Visualizer
        Item {
            id: vizContainer
            width: 71; height: 10
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
                model: 12
                delegate: Rectangle {
                    width: 4
                    height: Math.max(1, pill.cavaValues[index] || 0)
                    x: index * 6 + 0.5
                    y: vizContainer.height - height
                    color: pill.vizColor(index)
                    radius: 1
                    opacity: pill.mediaStatus === "Paused" ? 0.3 : 1

                    Behavior on height  { NumberAnimation { duration: 50;  easing.type: Easing.OutCubic } }
                    Behavior on color   { ColorAnimation  { duration: 300; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    pill.vizScheme = (pill.vizScheme + 1) % pill.vizSchemeCount
                    saveVizProc.running = true
                }
            }
        }

        // Track label — two Text items so we get proper eliding with bold artist
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Text {
                text: pill.artistName
                color: panelRoot.colWsActive
                font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2; bold: true }
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 120)
            }
            Text {
                text: pill.trackName ? " \u2013 " + pill.trackName : ""
                color: panelRoot.colWsActive
                font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 120)
            }
        }
    }

    MouseArea {
        id: mediaHover
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onClicked: mouse.accepted = false
    }

    // ── Data sources ──────────────────────────────────────────────────────────

    // playerctl --follow: long-running, emits a block on every metadata/status change.
    // Exits when no player is present; restartFollowTimer retries every 2s.
    Process {
        id: followProc
        command: ["bash", "-c",
            "exec playerctl --follow metadata --format " +
            "$'status:{{status}}\\nart:{{mpris:artUrl}}\\ntitle:{{xesam:title}}\\nartist:{{xesam:artist}}\\nalbum:{{xesam:album}}\\nlength:{{mpris:length}}\\nplayer:{{playerName}}' " +
            "2>/dev/null"
        ]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line.startsWith("status:")) {
                    var s = line.slice(7)
                    pill.mediaStatus = s
                    pill.mediaRunning = (s === "Playing" || s === "Paused")
                    if (s === "Stopped") {
                        pill.trackProgress = 0
                        pill.artUrl = ""
                        pill._posSecs = 0
                    }
                } else if (line.startsWith("art:")) {
                    var url = line.slice(4)
                    if (url !== pill.artUrl) pill.artUrl = url
                } else if (line.startsWith("title:")) {
                    pill.trackName = line.slice(6)
                } else if (line.startsWith("artist:")) {
                    pill.artistName = line.slice(7)
                } else if (line.startsWith("album:")) {
                    pill.albumName = line.slice(6)
                } else if (line.startsWith("player:")) {
                    pill.playerName = line.slice(7)
                } else if (line.startsWith("length:")) {
                    pill._durSecs = parseInt(line.slice(7)) / 1000000
                    pill.durStr = pill.fmtSecs(pill._durSecs)
                }
            }
        }
        onExited: {
            pill.mediaRunning = false
            pill.mediaStatus = ""
            restartFollowTimer.start()
        }
    }

    Timer {
        id: restartFollowTimer
        interval: 2000
        repeat: false
        onTriggered: followProc.running = true
    }

    // Fast position poll — 500ms, only while Playing
    Process {
        id: posProc
        command: ["playerctl", "position"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                var pos = parseFloat(data.trim())
                if (isNaN(pos)) return
                pill._posSecs = pos
                var dur = pill._durSecs
                pill.trackProgress = dur > 0 ? Math.min(pos / dur, 1) : 0
                pill.posStr = pill.fmtSecs(pos)
            }
        }
    }

    Timer {
        interval: 500
        running: pill.mediaStatus === "Playing"
        repeat: true
        onTriggered: posProc.running = true
    }

    // playerctl control — play-pause, previous, next, position <secs>
    Process {
        id: ctlProc
        property string cmdStr: ""
        command: ["sh", "-c", "playerctl " + ctlProc.cmdStr]
        running: false
    }

    // vizScheme persistence
    Process {
        id: saveVizProc
        command: ["sh", "-c", "echo " + pill.vizScheme + " > $HOME/.config/quickshell/vizscheme"]
        running: false
    }

    Process {
        id: loadVizProc
        command: ["sh", "-c", "cat $HOME/.config/quickshell/vizscheme 2>/dev/null || echo 0"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var v = parseInt(data.trim())
                if (!isNaN(v) && v >= 0 && v < pill.vizSchemeCount) pill.vizScheme = v
            }
        }
    }

    // cava — keep running whenever any media is present, not just while Playing.
    // Bars dim to 0.3 opacity on Pause (handled in delegate above).
    Process {
        id: cavaProc
        command: ["bash", "-c", "exec cava -p $HOME/.config/quickshell/cava.cfg"]
        running: pill.mediaRunning
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().replace(/;$/, "").split(";")
                if (parts.length >= 12)
                    pill.cavaValues = parts.slice(0, 12).map(s => parseInt(s) || 0)
            }
        }
        onRunningChanged: if (!running) pill.cavaValues = [0,0,0,0,0,0,0,0,0,0,0,0]
    }

    // ── Popup ─────────────────────────────────────────────────────────────────

    PopupWindow {
        visible: mediaHover.containsMouse && pill.mediaRunning
        implicitWidth: 300
        implicitHeight: 308
        color: "transparent"
        anchor.window: panelRoot
        anchor.item: pill
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        Rectangle {
            id: mediaPopupRect
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 8 }
            height: 300
            radius: 20
            clip: true
            layer.enabled: true
            color: panelRoot.colPill

            Image {
                id: popupArtImg
                anchors.fill: parent
                source: pill.artUrl
                fillMode: Image.PreserveAspectCrop
                smooth: true
                mipmap: true
            }

            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 160
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.72) }
                }
            }

            // Play/Pause toggle (top-left) — shows the action you'd take, not current state
            Item {
                anchors { top: parent.top; left: parent.left; topMargin: 12; leftMargin: 12 }
                width: 22; height: 22

                Image {
                    id: statusIcon
                    anchors.fill: parent
                    source: pill.mediaStatus === "Playing"
                        ? Qt.resolvedUrl("icons/pause.svg")
                        : Qt.resolvedUrl("icons/play.svg")
                    fillMode: Image.PreserveAspectFit
                    smooth: true; mipmap: true
                    visible: false; layer.enabled: true
                }
                ColorOverlay { anchors.fill: statusIcon; source: statusIcon; color: "#ffffff" }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pill.runPlayerctl("play-pause")
                }
            }

            // Prev / Next (top-right)
            Row {
                anchors { top: parent.top; right: parent.right; topMargin: 12; rightMargin: 12 }
                spacing: 10

                Item {
                    width: 22; height: 22
                    Image {
                        id: prevIcon
                        anchors.fill: parent
                        source: Qt.resolvedUrl("icons/left-arrow.svg")
                        fillMode: Image.PreserveAspectFit
                        smooth: true; mipmap: true
                        visible: false; layer.enabled: true
                    }
                    ColorOverlay { anchors.fill: prevIcon; source: prevIcon; color: "#cccccc" }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pill.runPlayerctl("previous")
                    }
                }

                Item {
                    width: 22; height: 22
                    Image {
                        id: nextIcon
                        anchors.fill: parent
                        source: Qt.resolvedUrl("icons/right-arrow.svg")
                        fillMode: Image.PreserveAspectFit
                        smooth: true; mipmap: true
                        visible: false; layer.enabled: true
                    }
                    ColorOverlay { anchors.fill: nextIcon; source: nextIcon; color: "#cccccc" }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pill.runPlayerctl("next")
                    }
                }
            }

            Column {
                id: mediaOverlay
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 14; bottomMargin: 12 }
                spacing: 6

                Text {
                    text: pill.trackName
                    color: "#ffffff"
                    font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize; bold: true }
                    elide: Text.ElideRight
                    width: parent.width
                    style: Text.Raised; styleColor: "#00000088"
                }
                Text {
                    text: pill.artistName
                    color: "#dddddd"
                    font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                    elide: Text.ElideRight
                    width: parent.width
                }
                Text {
                    text: pill.albumName || pill.playerName
                    color: "#aaaaaa"
                    font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                    elide: Text.ElideRight
                    width: parent.width
                }

                Column {
                    width: parent.width
                    spacing: 4

                    // Seekable progress bar — larger hit target via Item wrapper
                    Item {
                        width: parent.width
                        height: 10

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 3
                            radius: 2
                            color: Qt.rgba(1, 1, 1, 0.25)

                            Rectangle {
                                width: parent.width * pill.trackProgress
                                height: parent.height
                                radius: 2
                                color: pill.playerName === "spotify" ? "#1db954" : "#7eb8f7"
                                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.Linear } }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.SizeHorCursor
                            onClicked: {
                                var secs = (mouseX / width) * pill._durSecs
                                pill.runPlayerctl("position " + secs.toFixed(1))
                                // Optimistic update so the bar snaps immediately
                                pill._posSecs = secs
                                pill.trackProgress = pill._durSecs > 0 ? secs / pill._durSecs : 0
                                pill.posStr = pill.fmtSecs(secs)
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: posLabel.height

                        Text {
                            id: posLabel
                            text: pill.posStr
                            color: "#aaaaaa"
                            font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 3 }
                        }
                        Text {
                            anchors.right: parent.right
                            text: pill.durStr
                            color: "#aaaaaa"
                            font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 3 }
                        }
                    }
                }
            }
        }
    }
}
