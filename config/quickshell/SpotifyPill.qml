import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import Qt5Compat.GraphicalEffects

Rectangle {
    id: pill
    required property var panelRoot

    property bool spotifyRunning: false
    property string spotifyStatus: ""
    property string artUrl: ""
    property real trackProgress: 0
    property string trackName: ""
    property string artistName: ""
    property string posStr: "0:00"
    property string durStr: "0:00"
    property real _durSecs: 0
    property string albumName: ""
    property var cavaValues: [0,0,0,0,0,0,0,0,0,0,0,0]
    property int vizScheme: 0
    readonly property int vizSchemeCount: 6

    function vizColor(i) {
        var t = i / 11
        switch (vizScheme) {
            case 0: return Qt.hsla(t, 0.85, 0.65, 1.0)                          // rainbow
            case 1: return Qt.hsla(t * 0.17, 0.95, 0.55 + t * 0.1, 1.0)        // fire: red → orange → yellow
            case 2: return Qt.hsla(0.5 + t * 0.17, 0.8, 0.55 + t * 0.1, 1.0)  // ocean: cyan → blue
            case 3: return Qt.hsla(0.72 + t * 0.18, 0.85, 0.6 + t * 0.1, 1.0) // neon: purple → pink
            case 4: return Qt.hsla(0.33, 0.75, 0.28 + t * 0.38, 1.0)           // matrix: dark → bright green
            case 5: return Qt.hsla(0, 0, 0.45 + t * 0.45, 1.0)                 // mono: grey → white
        }
    }

    color: panelRoot.colPill
    radius: 12
    width: spotifyRow.width + 20
    height: spotifyRow.height + 10

    Behavior on width {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    opacity: spotifyRunning ? 1 : 0
    visible: opacity > 0
    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    Row {
        id: spotifyRow
        anchors.centerIn: parent
        spacing: 12

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
                    opacity: pill.spotifyStatus === "Paused" ? 0.3 : 1

                    Behavior on height { NumberAnimation { duration: 50; easing.type: Easing.OutCubic } }
                    Behavior on color  { ColorAnimation  { duration: 300; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: pill.vizScheme = (pill.vizScheme + 1) % pill.vizSchemeCount
            }
        }

        Text {
            textFormat: Text.RichText
            text: "<b>" + pill.artistName + "</b>" + (pill.trackName ? " – " + pill.trackName : "")
            color: panelRoot.colWsActive
            font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea { id: spotifyHover; anchors.fill: parent; hoverEnabled: true; propagateComposedEvents: true; onClicked: mouse.accepted = false }

    Process {
        id: spotifyProc
        command: ["sh", "-c",
            "S=$(playerctl -p spotify status 2>/dev/null) || { echo 'status:Stopped'; exit 0; }; " +
            "echo \"status:$S\"; " +
            "playerctl -p spotify metadata --format $'art:{{mpris:artUrl}}\\ntitle:{{xesam:title}}\\nartist:{{xesam:artist}}\\nalbum:{{xesam:album}}\\nlength:{{mpris:length}}' 2>/dev/null; " +
            "playerctl -p spotify position 2>/dev/null | awk '{print \"pos:\" $1}'"
        ]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var line = data.trim()
                if (line.startsWith("status:")) {
                    var s = line.slice(7)
                    pill.spotifyStatus = s
                    pill.spotifyRunning = (s === "Playing" || s === "Paused")
                } else if (line.startsWith("art:")) {
                    var url = line.slice(4)
                    if (url !== pill.artUrl) pill.artUrl = url
                } else if (line.startsWith("title:")) {
                    pill.trackName = line.slice(6)
                } else if (line.startsWith("artist:")) {
                    pill.artistName = line.slice(7)
                } else if (line.startsWith("album:")) {
                    pill.albumName = line.slice(6)
                } else if (line.startsWith("length:")) {
                    pill._durSecs = parseInt(line.slice(7)) / 1000000
                } else if (line.startsWith("pos:")) {
                    var pos = parseFloat(line.slice(4))
                    var dur = pill._durSecs
                    pill.trackProgress = dur > 0 ? Math.min(pos / dur, 1) : 0
                    var fmt = function(s) {
                        var m = Math.floor(s / 60)
                        var sec = Math.floor(s % 60)
                        return m + ":" + (sec < 10 ? "0" : "") + sec
                    }
                    pill.posStr = fmt(pos)
                    pill.durStr = fmt(dur)
                }
            }
        }
        onExited: {
            if (!pill.spotifyRunning) {
                pill.trackProgress = 0
                pill.artUrl = ""
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: spotifyProc.running = true
    }

    Process {
        id: cavaProc
        command: ["bash", "-c", "exec cava -p $HOME/.config/quickshell/cava.cfg"]
        running: pill.spotifyStatus === "Playing"
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().replace(/;$/, "").split(";")
                if (parts.length >= 12)
                    pill.cavaValues = parts.slice(0, 12).map(s => parseInt(s) || 0)
            }
        }
        onRunningChanged: if (!running) pill.cavaValues = [0,0,0,0,0,0,0,0,0,0,0,0]
    }

    PopupWindow {
        visible: spotifyHover.containsMouse && pill.spotifyRunning
        implicitWidth: 300
        implicitHeight: 308
        color: "transparent"
        anchor.window: panelRoot
        anchor.item: pill
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        Rectangle {
            id: spotifyPopupRect
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 8 }
            height: 300
            radius: 20
            clip: true
            color: panelRoot.colPill

            // Full-bleed album art background
            Image {
                id: popupArtImg
                anchors.fill: parent
                source: pill.artUrl
                fillMode: Image.PreserveAspectCrop
                smooth: true
                mipmap: true
            }

            // Gradient scrim so overlay text is readable
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 160
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.72) }
                }
            }

            // Play/pause icon — top left
            Item {
                anchors { top: parent.top; left: parent.left; topMargin: 12; leftMargin: 12 }
                width: 22; height: 22

                Image {
                    id: statusIcon
                    anchors.fill: parent
                    source: pill.spotifyStatus === "Playing"
                        ? Qt.resolvedUrl("icons/play.svg")
                        : Qt.resolvedUrl("icons/pause.svg")
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    visible: false
                    layer.enabled: true
                }
                ColorOverlay {
                    anchors.fill: statusIcon
                    source: statusIcon
                    color: "#ffffff"
                }
            }

            // Info overlay anchored to bottom
            Column {
                id: spotifyOverlay
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
                    text: pill.albumName
                    color: "#aaaaaa"
                    font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                    elide: Text.ElideRight
                    width: parent.width
                }


                Column {
                    width: parent.width
                    spacing: 4

                    Rectangle {
                        width: parent.width
                        height: 3
                        radius: 2
                        color: Qt.rgba(1, 1, 1, 0.25)

                        Rectangle {
                            width: parent.width * pill.trackProgress
                            height: parent.height
                            radius: 2
                            color: "#1db954"
                            Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.Linear } }
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
