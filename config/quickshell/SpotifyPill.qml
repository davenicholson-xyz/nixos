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
    property var cavaValues: [0,0,0,0,0,0,0,0,0,0,0,0]

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
                    color: panelRoot.colWsActive
                    radius: 1
                    opacity: pill.spotifyStatus === "Paused" ? 0.3 : 1

                    Behavior on height { NumberAnimation { duration: 50; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
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
                    pill.spotifyStatus = s
                    pill.spotifyRunning = (s === "Playing" || s === "Paused")
                } else if (line.startsWith("art:")) {
                    var url = line.slice(4)
                    if (url !== pill.artUrl) pill.artUrl = url
                } else if (line.startsWith("title:")) {
                    pill.trackName = line.slice(6)
                } else if (line.startsWith("artist:")) {
                    pill.artistName = line.slice(7)
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
        implicitWidth: 230
        implicitHeight: spotifyPopupRect.height + 8
        color: "transparent"
        anchor.window: panelRoot
        anchor.item: pill
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        Rectangle {
            id: spotifyPopupRect
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 8 }
            height: spotifyPopupRow.implicitHeight + 20
            color: panelRoot.colPill
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
                        source: pill.artUrl
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
                        text: pill.trackName
                        color: panelRoot.colWsActive
                        font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                        elide: Text.ElideRight
                        width: parent.width
                    }
                    Text {
                        text: pill.artistName
                        color: panelRoot.colWsOccupied
                        font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                        elide: Text.ElideRight
                        width: parent.width
                    }
                    Text {
                        text: pill.posStr + " / " + pill.durStr
                        color: panelRoot.colWsEmpty
                        font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                    }
                }
            }
        }
    }
}
