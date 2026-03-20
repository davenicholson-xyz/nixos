import Quickshell
import Quickshell.Io
import QtQuick
import Qt5Compat.GraphicalEffects

Rectangle {
    id: pill
    required property var panelRoot

    property bool waiting: false

    color: panelRoot.colPill
    radius: 12
    width: 30
    height: iconItem.height + 10

    opacity: waiting ? 1 : 0
    visible: opacity > 0
    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    // Pulsing glow when waiting
    SequentialAnimation {
        running: pill.waiting
        loops: Animation.Infinite
        NumberAnimation { target: iconOverlay; property: "opacity"; to: 0.3; duration: 700; easing.type: Easing.InOutSine }
        NumberAnimation { target: iconOverlay; property: "opacity"; to: 1.0; duration: 700; easing.type: Easing.InOutSine }
    }
    onWaitingChanged: if (!waiting) iconOverlay.opacity = 1.0

    Item {
        id: iconItem
        width: 13; height: 13
        anchors.centerIn: parent

        Image {
            id: iconImg
            anchors.fill: parent
            source: "icons/claude.svg"
            smooth: true
            mipmap: true
            sourceSize.width: 13
            sourceSize.height: 13
            visible: false
            layer.enabled: true
        }
        ColorOverlay {
            id: iconOverlay
            anchors.fill: iconImg
            source: iconImg
            color: "#da7756"
        }
    }

    // Poll for ~/.claude/waiting-for-input
    Process {
        id: checkProc
        command: ["sh", "-c", "test -f $HOME/.claude/waiting-for-input && pgrep -x claude > /dev/null && echo 1 || echo 0"]
        running: true
        stdout: SplitParser {
            onRead: data => { pill.waiting = data.trim() === "1" }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: checkProc.running = true
    }
}
