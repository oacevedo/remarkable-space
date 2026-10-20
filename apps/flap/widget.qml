// Half widget — current flap message (monospace, high contrast for e-ink).
import QtQuick

Item {
    id: root
    property var space
    property var app

    readonly property string endpoint: "http://flap.l4local.net/api/current"
    property var payload: null
    property string errorText: ""
    property bool loading: true

    Component.onCompleted: refresh()
    Timer { interval: 2 * 60 * 1000; repeat: true; running: true; onTriggered: root.refresh() }

    function refresh() {
        loading = true
        errorText = ""
        var x = new XMLHttpRequest()
        x.timeout = 6000
        x.open("GET", endpoint)
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE) return
            loading = false
            if (x.status === 200) {
                try { payload = JSON.parse(x.responseText) } catch (e) {}
            } else {
                errorText = space.trApp(app.id, "offline")
            }
        }
        x.send()
    }

    Rectangle {
        anchors.fill: parent
        color: "#1a0f04"
        radius: 8

        Column {
            anchors.centerIn: parent
            spacing: 8
            width: parent.width - 32

            Text {
                text: root.payload && root.payload.text
                      ? root.payload.text
                      : (root.loading ? space.trApp(app.id, "loading") : root.errorText)
                color: "white"
                font.family: "monospace"
                font.pixelSize: 28 * space.fontScale
                font.weight: Font.Medium
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }

            Text {
                text: root.payload && root.payload.sender
                      ? space.trApp(app.id, "by") + " " + root.payload.sender
                      : ""
                color: "#aaaaaa"
                font.pixelSize: 14 * space.fontScale
                visible: text.length > 0
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }
        }

        MouseArea { anchors.fill: parent; onClicked: space.openApp(app.id) }
    }
}
