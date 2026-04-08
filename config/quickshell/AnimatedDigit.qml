import QtQuick

// A single clock digit that slides the old value down and the new value in from above.
Item {
    id: root
    required property string digit
    property color textColor: "white"
    property string fontFamily: ""
    property int fontSize: 13
    property bool fontBold: false

    clip: true
    implicitWidth: sizer.implicitWidth
    implicitHeight: sizer.implicitHeight

    // Invisible reference glyph — keeps width stable across all digits
    Text {
        id: sizer
        text: "0"
        font { family: root.fontFamily; pixelSize: root.fontSize; bold: root.fontBold }
        visible: false
    }

    // Outgoing digit (visible, slides down out)
    Text {
        id: front
        color: root.textColor
        font { family: root.fontFamily; pixelSize: root.fontSize; bold: root.fontBold }
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0; opacity: 1
    }

    // Incoming digit (hidden above, slides down into view)
    Text {
        id: back
        text: ""
        color: root.textColor
        font { family: root.fontFamily; pixelSize: root.fontSize; bold: root.fontBold }
        anchors.horizontalCenter: parent.horizontalCenter
        y: -root.implicitHeight; opacity: 0
    }

    Component.onCompleted: {
        front.text = root.digit
    }

    onDigitChanged: {
        if (digit === front.text && !swapAnim.running) return
        if (swapAnim.running) {
            swapAnim.stop()
            front.text = back.text !== "" ? back.text : front.text
            front.y = 0; front.opacity = 1
            back.y = -root.implicitHeight; back.opacity = 0
        }
        back.text = digit
        swapAnim.start()
    }

    SequentialAnimation {
        id: swapAnim
        ParallelAnimation {
            // Old digit slides down and fades
            NumberAnimation { target: front; property: "y"; to: root.implicitHeight; duration: 160; easing.type: Easing.InCubic }
            NumberAnimation { target: front; property: "opacity"; to: 0; duration: 120 }
            // New digit slides in from above
            NumberAnimation { target: back; property: "y"; to: 0; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { target: back; property: "opacity"; to: 1; duration: 160 }
        }
        ScriptAction {
            script: {
                front.text = back.text
                front.y = 0; front.opacity = 1
                back.y = -root.implicitHeight; back.opacity = 0
            }
        }
    }
}
