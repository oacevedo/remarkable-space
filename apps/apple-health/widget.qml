// Half-width widget — step count + resting HR for today, plus last workout.
import QtQuick

Item {
    id: root
    property var space
    property var app

    readonly property string endpoint: "http://health.l4local.net/api/today"
    property var payload: null
    property string errorText: ""
    property bool loading: true

    Component.onCompleted: refresh()
    Timer {
        interval: 10 * 60 * 1000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

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
                try { payload = JSON.parse(x.responseText) }
                catch (e) { errorText = "Bad JSON" }
            } else {
                errorText = space.trApp(app.id, "offline")
            }
        }
        x.send()
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

            Row {
                spacing: 24
                Column {
                    Text {
                        text: root.payload && root.payload.steps !== undefined ? root.payload.steps.toLocaleString() : "—"
                        font.pixelSize: 44 * space.fontScale
                        font.weight: Font.Medium
                        color: "#1a0f04"
                    }
                    Text {
                        text: space.trApp(app.id, "steps")
                        font.pixelSize: 16 * space.fontScale
                        color: "#8a7a6a"
                    }
                }
                Column {
                    Text {
                        text: root.payload && root.payload.resting_hr ? root.payload.resting_hr : "—"
                        font.pixelSize: 44 * space.fontScale
                        font.weight: Font.Medium
                        color: "#1a0f04"
                    }
                    Text {
                        text: space.trApp(app.id, "resting_hr")
                        font.pixelSize: 16 * space.fontScale
                        color: "#8a7a6a"
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#eeeeee" }

            Text {
                text: space.trApp(app.id, "last_workout")
                font.pixelSize: 14 * space.fontScale
                color: "#8a7a6a"
                visible: root.payload && root.payload.last_workout
            }
            Text {
                text: root.payload && root.payload.last_workout
                      ? root.payload.last_workout.kind + " · " + root.payload.last_workout.duration_min + "min"
                      : (root.loading ? space.trApp(app.id, "loading") : (root.errorText || space.trApp(app.id, "none")))
                font.pixelSize: 20 * space.fontScale
                color: "#1a0f04"
                elide: Text.ElideRight
                width: parent.width
            }
        }

        MouseArea { anchors.fill: parent; onClicked: space.openApp(app.id) }
    }
}
