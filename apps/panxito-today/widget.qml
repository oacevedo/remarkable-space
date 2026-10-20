// Hero widget — today's agenda + overdue reminders summary.
// Reads from the Panxito today endpoint over Tailscale.
import QtQuick

Item {
    id: root
    property var space
    property var app

    readonly property string endpoint: "http://panxito-today.l4local.net/api/today"
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
                errorText = space.trApp(app.id, "error_offline")
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
            spacing: 12

            Row {
                width: parent.width
                spacing: 12
                Text {
                    text: Qt.formatDate(space.localNow(), space.tr("date_format"))
                    font.pixelSize: 28 * space.fontScale
                    font.weight: Font.Medium
                    color: "#1a0f04"
                }
                Item { width: parent.width - 400; height: 1 }
                Text {
                    text: root.payload && root.payload.weather
                          ? root.payload.weather.summary + " · " + root.payload.weather.temp_f + "°F"
                          : ""
                    font.pixelSize: 22 * space.fontScale
                    color: "#555555"
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#eeeeee" }

            Text {
                text: root.loading ? space.trApp(app.id, "loading")
                      : root.errorText.length > 0 ? root.errorText
                      : (root.payload && root.payload.agenda && root.payload.agenda.length > 0)
                          ? ""
                          : space.trApp(app.id, "agenda_empty")
                font.pixelSize: 20 * space.fontScale
                color: "#555555"
                visible: text.length > 0
            }

            Repeater {
                model: root.payload && root.payload.agenda ? root.payload.agenda.slice(0, 4) : []
                delegate: Row {
                    required property var modelData
                    spacing: 16
                    Text {
                        text: modelData.time || "·"
                        font.pixelSize: 22 * space.fontScale
                        width: 110
                        color: "#1a0f04"
                        font.weight: Font.Medium
                    }
                    Text {
                        text: modelData.title
                        font.pixelSize: 22 * space.fontScale
                        color: "#1a0f04"
                        elide: Text.ElideRight
                        width: 540
                    }
                }
            }

            Rectangle {
                width: parent.width; height: 1; color: "#eeeeee"
                visible: root.payload && root.payload.overdue && root.payload.overdue.length > 0
            }

            Text {
                text: space.trApp(app.id, "section_reminders")
                      + (root.payload && root.payload.overdue ? " · " + root.payload.overdue.length : "")
                font.pixelSize: 18 * space.fontScale
                color: "#8a7a6a"
                visible: root.payload && root.payload.overdue && root.payload.overdue.length > 0
            }

            Repeater {
                model: root.payload && root.payload.overdue ? root.payload.overdue.slice(0, 3) : []
                delegate: Text {
                    required property var modelData
                    text: "• " + modelData.title
                    font.pixelSize: 20 * space.fontScale
                    color: "#1a0f04"
                    elide: Text.ElideRight
                    width: 700
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: space.openApp(app.id)
        }
    }
}
