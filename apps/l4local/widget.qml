// Half widget — count of healthy vs broken services, red dot if any broken.
import QtQuick

Item {
    id: root
    property var space
    property var app

    readonly property string endpoint: "http://tools.l4local.net/api/status"
    property var payload: null
    property string errorText: ""
    property bool loading: true

    Component.onCompleted: refresh()
    Timer { interval: 5 * 60 * 1000; repeat: true; running: true; onTriggered: root.refresh() }

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

    function count(status) {
        if (!payload || !payload.services) return 0
        var n = 0
        for (var i = 0; i < payload.services.length; i++) {
            if (payload.services[i].status === status) n++
        }
        return n
    }

    Rectangle {
        anchors.fill: parent
        color: "white"
        border.color: "#dddddd"
        border.width: 1
        radius: 8

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 10

            Row {
                spacing: 8
                Rectangle {
                    width: 16; height: 16
                    radius: 8
                    color: root.count("broken") > 0 ? "#8a1a0a" : "#1a0f04"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: space.trApp(app.id, "title")
                    font.pixelSize: 20 * space.fontScale
                    color: "#8a7a6a"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Text {
                text: root.payload
                      ? root.count("ok") + " / " + root.payload.services.length
                      : (root.loading ? "…" : "—")
                font.pixelSize: 48 * space.fontScale
                font.weight: Font.Medium
                color: "#1a0f04"
            }

            Text {
                text: space.trApp(app.id, "ok")
                font.pixelSize: 14 * space.fontScale
                color: "#8a7a6a"
            }

            Rectangle { width: parent.width; height: 1; color: "#eeeeee" }

            Text {
                text: root.count("broken") > 0
                      ? "⚠ " + space.trApp(app.id, "n_broken").replace("{n}", root.count("broken"))
                      : (root.errorText || "")
                font.pixelSize: 18 * space.fontScale
                color: root.count("broken") > 0 ? "#8a1a0a" : "#8a7a6a"
                elide: Text.ElideRight
                width: parent.width
            }
        }

        MouseArea { anchors.fill: parent; onClicked: space.openApp(app.id) }
    }
}
