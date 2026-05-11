import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "clock-overlay"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    // ── time state ────────────────────────────────────────────────────────────
    property string timeStr: Qt.formatTime(new Date(), "HHmmss")
    property string dateStr: Qt.formatDate(new Date(), "dddd, MMMM d")
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.timeStr = Qt.formatTime(new Date(), "HHmmss")
            root.dateStr = Qt.formatDate(new Date(), "dddd, MMMM d")
        }
    }

    // ── layout ────────────────────────────────────────────────────────────────
    // Render at a fixed base size, then scale the whole column to fill the
    // screen width. The binding is reactive so it tracks window size changes.
    readonly property int baseFontSize: 300

    Column {
        id: clockColumn
        anchors.centerIn: parent
        spacing: 0

        // Scale so the time row fills 95 % of the screen width.
        // clockRow.width is non-zero once the Row has laid out.
        scale: clockRow.width > 0 ? root.width * 0.55 / clockRow.width : 1.0
        transformOrigin: Item.Center

        // ── HH : MM : SS ─────────────────────────────────────────────────────
        Row {
            id: clockRow
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 0

            AnimatedDigit { digit: root.timeStr[0]; fontSize: root.baseFontSize; fontBold: true; textColor: "#aaffffff" }
            AnimatedDigit { digit: root.timeStr[1]; fontSize: root.baseFontSize; fontBold: true; textColor: "#aaffffff" }

            Text {
                text: ":"
                color: "#ffffff"
                font { pixelSize: root.baseFontSize; bold: true }
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 12; rightPadding: 12
            }

            AnimatedDigit { digit: root.timeStr[2]; fontSize: root.baseFontSize; fontBold: true; textColor: "#aaffffff" }
            AnimatedDigit { digit: root.timeStr[3]; fontSize: root.baseFontSize; fontBold: true; textColor: "#aaffffff" }

            Text {
                text: ":"
                color: "#ffffff"
                font { pixelSize: root.baseFontSize; bold: true }
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 12; rightPadding: 12
            }

            AnimatedDigit { digit: root.timeStr[4]; fontSize: root.baseFontSize; fontBold: true; textColor: "#aaffffff" }
            AnimatedDigit { digit: root.timeStr[5]; fontSize: root.baseFontSize; fontBold: true; textColor: "#aaffffff" }
        }

        // ── date line ─────────────────────────────────────────────────────────
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.dateStr
            color: "#bbbbbb"
            // Keep the date label a fixed fraction of the digit height so it
            // scales proportionally with the rest of the column.
            font { pixelSize: Math.round(root.baseFontSize * 0.18); bold: false }
        }
    }
}
