import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import Qt5Compat.GraphicalEffects

Rectangle {
    id: pill
    required property var panelRoot

    property real xOff: 24
    property real rxSpeed: 0
    property real txSpeed: 0
    property real totalRx: 0
    property real totalTx: 0
    property real prevRx: 0
    property real prevTx: 0
    property bool firstRead: true
    property string iface: ""
    property string ip: ""
    property string ssid: ""
    property var _infoBuf: []
    property real maxSpeed: 10485760  // 10 MB/s reference for bar

    opacity: 0
    transform: Translate { x: pill.xOff }
    color: panelRoot.colPill
    radius: 12
    width: 80
    height: 23

    function formatSpeed(bps) {
        if (bps >= 1048576) return (bps / 1048576).toFixed(1) + "M/s"
        if (bps >= 1024) return Math.round(bps / 1024) + "K/s"
        return bps + "B/s"
    }

    function formatSpeedShort(bps) {
        if (bps >= 1048576) return (bps / 1048576).toFixed(1) + "M"
        if (bps >= 1024) return Math.round(bps / 1024) + "K"
        return bps + "B"
    }

    function dotColor(bps) {
        if (bps >= 1048576) return panelRoot.colWsActive
        if (bps >= 10240)   return panelRoot.colWsOccupied
        return panelRoot.colWsEmpty
    }

    function formatBytes(b) {
        if (b >= 1073741824) return (b / 1073741824).toFixed(1) + " GB"
        if (b >= 1048576) return (b / 1048576).toFixed(1) + " MB"
        if (b >= 1024) return Math.round(b / 1024) + " KB"
        return b + " B"
    }

    Item {
        anchors {
            left: parent.left; right: parent.right
            leftMargin: 8; rightMargin: 8
            verticalCenter: parent.verticalCenter
        }
        height: 13

        Item {
            id: netIconItem
            width: 13; height: 13
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            Image {
                id: netIcon
                anchors.fill: parent
                source: "icons/network.svg"
                smooth: true
                mipmap: true
                sourceSize.width: 13
                sourceSize.height: 13
                visible: false
                layer.enabled: true
            }

            ColorOverlay {
                anchors.fill: netIcon
                source: netIcon
                color: panelRoot.colClock
            }
        }

        Row {
            anchors.left: netIconItem.right
            anchors.leftMargin: 5
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                text: "↑"
                color: pill.dotColor(pill.txSpeed)
                font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 1 }
            }
            Text {
                text: "↓"
                color: pill.dotColor(pill.rxSpeed)
                font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 1 }
            }
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: pill.formatSpeedShort(pill.rxSpeed)
            color: panelRoot.colWsActive
            font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 3 }
        }
    }

    Process {
        id: netStatsProc
        command: ["sh", "-c", "iface=$(ip route show default | awk '/default/{print $5; exit}'); awk -v i=\"${iface}:\" '$1==i{print $2, $10}' /proc/net/dev"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(" ")
                if (parts.length < 2) return
                var rx = parseFloat(parts[0])
                var tx = parseFloat(parts[1])
                if (!pill.firstRead) {
                    pill.rxSpeed = Math.max(0, (rx - pill.prevRx) / 2)
                    pill.txSpeed = Math.max(0, (tx - pill.prevTx) / 2)
                }
                pill.firstRead = false
                pill.prevRx = rx
                pill.prevTx = tx
                pill.totalRx = rx
                pill.totalTx = tx
            }
        }
    }
    Timer { interval: 2000; running: true; repeat: true; onTriggered: netStatsProc.running = true }

    Process {
        id: netInfoProc
        command: ["sh", "-c", "iface=$(ip route show default | awk '/default/{print $5; exit}'); printf '%s\\n' \"$iface\"; ip -4 addr show dev \"$iface\" 2>/dev/null | awk '/inet /{split($2, a, \"/\"); print a[1]; exit}'; iwgetid -r \"$iface\" 2>/dev/null"]
        running: true
        onRunningChanged: if (running) pill._infoBuf = []
        stdout: SplitParser {
            onRead: data => { pill._infoBuf.push(data.trim()) }
        }
        onExited: {
            if (pill._infoBuf.length >= 1) pill.iface = pill._infoBuf[0] || ""
            if (pill._infoBuf.length >= 2) pill.ip   = pill._infoBuf[1] || ""
            pill.ssid = pill._infoBuf.length >= 3 ? pill._infoBuf[2] : ""
        }
    }
    Timer { interval: 15000; running: true; repeat: true; onTriggered: netInfoProc.running = true }

    MouseArea { id: netHover; anchors.fill: parent; hoverEnabled: true }

    PopupWindow {
        visible: panelRoot.pillsVisible && netHover.containsMouse
        implicitWidth: 200
        implicitHeight: netPopupRect.height + 8
        color: "transparent"
        anchor.window: panelRoot
        anchor.item: pill
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        Rectangle {
            id: netPopupRect
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 8 }
            height: netPopupCol.implicitHeight + 20
            color: panelRoot.colPill
            radius: 10

            Column {
                id: netPopupCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                spacing: 4

                Row {
                    width: netPopupCol.width
                    Text {
                        text: "↓  " + pill.formatSpeed(pill.rxSpeed)
                        color: panelRoot.colWsActive
                        font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                        width: parent.width / 2
                    }
                    Text {
                        text: "↑  " + pill.formatSpeed(pill.txSpeed)
                        color: panelRoot.colWsActive
                        font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                    }
                }

                Rectangle {
                    width: netPopupCol.width
                    height: 1
                    color: panelRoot.colBarTrack
                }

                Repeater {
                    model: [
                        { label: "Interface", value: pill.iface },
                        { label: "IP",        value: pill.ip },
                        { label: "SSID",      value: pill.ssid },
                        { label: "Total ↓",   value: pill.formatBytes(pill.totalRx) },
                        { label: "Total ↑",   value: pill.formatBytes(pill.totalTx) },
                    ].filter(r => r.value !== "")
                    delegate: Row {
                        width: netPopupCol.width
                        Text {
                            text: modelData.label
                            color: panelRoot.colWsOccupied
                            font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                            width: 76
                        }
                        Text {
                            text: modelData.value
                            color: panelRoot.colWsActive
                            font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                            width: netPopupCol.width - 76
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
