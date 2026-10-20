// Full-page: today's health glance + last 7 workouts.
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property var space
    anchors.fill: parent

    readonly property string endpoint: "http://health.l4local.net/api/summary"
    property var payload: null
    property string errorText: ""
    property bool loading: true

    Component.onCompleted: { space.title = space.tr("title"); refresh() }

    function refresh() {
        loading = true
        errorText = ""
        var x = new XMLHttpRequest()
        x.timeout = 10000
        x.open("GET", endpoint)
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE) return
            loading = false
            if (x.status === 200) {
                try { payload = JSON.parse(x.responseText) } catch (e) {}
            } else {
                errorText = space.tr("offline")
            }
        }
        x.send()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24 * space.unit
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            spacing: 40
            Column {
                Text {
                    text: root.payload && root.payload.today ? root.payload.today.steps.toLocaleString() : "—"
                    font.pixelSize: 72 * space.fontScale
                    font.weight: Font.Medium
                    color: "#1a0f04"
                }
                Text { text: space.tr("steps"); font.pixelSize: 20 * space.fontScale; color: "#8a7a6a" }
            }
            Column {
                Text {
                    text: root.payload && root.payload.today && root.payload.today.resting_hr
                          ? root.payload.today.resting_hr + " " + space.tr("bpm")
                          : "—"
                    font.pixelSize: 44 * space.fontScale
                    color: "#1a0f04"
                }
                Text { text: space.tr("resting_hr"); font.pixelSize: 20 * space.fontScale; color: "#8a7a6a" }
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#eeeeee" }

        Text {
            text: space.tr("last_workout")
            font.pixelSize: 24 * space.fontScale
            font.weight: Font.Medium
            color: "#1a0f04"
        }

        Repeater {
            model: root.payload && root.payload.recent_workouts ? root.payload.recent_workouts : []
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 20
                Text { text: modelData.date; Layout.preferredWidth: 140; font.pixelSize: 22 * space.fontScale; color: "#8a7a6a" }
                Text { text: modelData.kind; Layout.preferredWidth: 220; font.pixelSize: 22 * space.fontScale; color: "#1a0f04" }
                Text { text: modelData.duration_min + " min"; font.pixelSize: 22 * space.fontScale; color: "#1a0f04" }
                Item { Layout.fillWidth: true }
            }
        }

        Text {
            text: root.loading ? space.tr("loading") : root.errorText
            visible: text.length > 0
            font.pixelSize: 20 * space.fontScale
            color: "#8a7a6a"
        }

        Item { Layout.fillHeight: true }
    }
}
