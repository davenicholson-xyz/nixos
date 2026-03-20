import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import Qt5Compat.GraphicalEffects

Rectangle {
    id: pill
    required property var panelRoot

    property real xOff: 0
    property int ramPct: 0
    property string ramInfo: ""
    property var blobs: []

    opacity: 1
    transform: Translate { x: pill.xOff }
    color: panelRoot.colPill
    radius: 12
    width: 96
    height: ramRow.height + 10

    Component.onCompleted: {
        var arr = []
        for (var i = 0; i < 8; i++) {
            arr.push({
                x:  4 + Math.random() * 56,
                y:  2 + Math.random() *  9,
                vx: (Math.random() - 0.5) * 0.7,
                vy: (Math.random() - 0.5) * 0.35,
                r:  2.5 + Math.random() * 1.5
            })
        }
        pill.blobs = arr
    }

    Timer {
        interval: 40
        running: true
        repeat: true
        onTriggered: {
            var W = 64, H = 13
            var arr = pill.blobs.slice()
            for (var i = 0; i < arr.length; i++) {
                var b = { x: arr[i].x, y: arr[i].y,
                          vx: arr[i].vx, vy: arr[i].vy, r: arr[i].r }
                b.x += b.vx
                b.y += b.vy
                if (b.x - b.r < 0)  { b.x = b.r;     b.vx =  Math.abs(b.vx) }
                if (b.x + b.r > W)  { b.x = W - b.r; b.vx = -Math.abs(b.vx) }
                if (b.y - b.r < 0)  { b.y = b.r;     b.vy =  Math.abs(b.vy) }
                if (b.y + b.r > H)  { b.y = H - b.r; b.vy = -Math.abs(b.vy) }
                arr[i] = b
            }
            pill.blobs = arr
            lavaCanvas.requestPaint()
        }
    }

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
                color: panelRoot.colClock
            }
        }

        Canvas {
            id: lavaCanvas
            width: 64
            height: 13
            anchors.verticalCenter: parent.verticalCenter

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var count = Math.max(1, Math.round(pill.ramPct / 100 * 8))
                var color = pill.ramPct >= 95 ? "#e05252"
                          : pill.ramPct >= 80 ? "#e0c94a"
                          : "#4ae09a"

                for (var i = 0; i < count; i++) {
                    var b = pill.blobs[i]
                    if (!b) continue
                    ctx.beginPath()
                    ctx.arc(b.x, b.y, b.r, 0, Math.PI * 2)
                    ctx.fillStyle = color
                    ctx.shadowColor = color
                    ctx.shadowBlur = 6
                    ctx.fill()
                }
            }
        }
    }

    Process {
        id: ramProc
        command: ["sh", "-c", "awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf \"%.0f\", (t-a)/t*100}' /proc/meminfo"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var num = parseInt(data.trim())
                if (!isNaN(num)) pill.ramPct = num
            }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: ramProc.running = true }

    Process {
        id: ramInfoProc
        command: ["sh", "-c", "free -h | awk '/^Mem:/{print $3\" / \"$2}'"]
        running: true
        stdout: SplitParser { onRead: data => pill.ramInfo = data.trim() }
    }
    Timer { interval: 3000; running: true; repeat: true; onTriggered: ramInfoProc.running = true }

    MouseArea { id: ramHover; anchors.fill: parent; hoverEnabled: true }

    PopupWindow {
        visible: panelRoot.pillsVisible && ramHover.containsMouse
        implicitWidth: 140
        implicitHeight: 60
        color: "transparent"
        anchor.window: panelRoot
        anchor.item: pill
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 8
            color: panelRoot.colPill
            radius: 10
            Column {
                anchors.centerIn: parent
                spacing: 4
                Text {
                    text: "RAM   " + pill.ramPct + "%"
                    color: panelRoot.colWsActive
                    font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                }
                Text {
                    text: pill.ramInfo
                    color: panelRoot.colWsOccupied
                    font { family: panelRoot.fontFamily; pixelSize: panelRoot.fontSize - 2 }
                }
            }
        }
    }
}
