// Half widget: total across all accounts + last-refresh time.
import QtQuick

Item {
    id: root
    property var space
    property var app

    readonly property string endpoint: "http://simplefin.l4local.net/api/summary"
    property var payload: null
    property string errorText: ""
    property bool loading: true

    Component.onCompleted: refresh()
    Timer { interval: 15 * 60 * 1000; repeat: true; running: true; onTriggered: root.refresh() }

    function refresh() {
        loading = true
        errorText = ""
        var x = new XMLHttpRequest()
        x.timeout = 8000
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

    function fmt(n) {
        if (n === undefined || n === null) return "—"
        var s = Math.round(n).toString()
        return "$" + s.replace(/\B(?=(\d{3})+(?!\d))/g, ",")
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

            Text {
                text: space.trApp(app.id, "title")
                font.pixelSize: 20 * space.fontScale
                color: "#8a7a6a"
            }

            Text {
                text: root.payload ? root.fmt(root.payload.total) : (root.loading ? "…" : "—")
                font.pixelSize: 48 * space.fontScale
                font.weight: Font.Medium
                color: "#1a0f04"
            }

            Text {
                text: space.trApp(app.id, "total")
                font.pixelSize: 14 * space.fontScale
                color: "#8a7a6a"
            }

            Rectangle { width: parent.width; height: 1; color: "#eeeeee" }

            Text {
                text: root.payload && root.payload.last_refresh
                      ? space.trApp(app.id, "updated") + " " + root.payload.last_refresh
                      : (root.errorText || "")
                font.pixelSize: 14 * space.fontScale
                color: "#8a7a6a"
                elide: Text.ElideRight
                width: parent.width
            }
        }

        MouseArea { anchors.fill: parent; onClicked: space.openApp(app.id) }
    }
}
