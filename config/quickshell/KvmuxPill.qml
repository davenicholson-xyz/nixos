import Quickshell
import Quickshell.Io
import QtQuick
import Qt5Compat.GraphicalEffects

Rectangle {
    id: pill
    required property var panelRoot

    property bool connected: false
    property bool remote: false

    color: panelRoot.colPill
    radius: 12
    width: 28
    height: 24

    opacity: connected ? 1 : 0
    visible: opacity > 0
    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    Item {
        width: 14; height: 14
        anchors.centerIn: parent

        Image {
            id: appleIcon
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
            anchors.fill: appleIcon
            source: appleIcon
            color: pill.remote ? "#ffffff" : "#555555"
            Behavior on color {
                ColorAnimation { duration: 200 }
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
                    pill.connected = obj.connected === true
                    pill.remote = obj.remote === true
                } catch (e) {
                    pill.connected = false
                    pill.remote = false
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
}
