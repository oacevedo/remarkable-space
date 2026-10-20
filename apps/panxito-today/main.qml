// Full-page Today view: agenda + overdue reminders + 3-day weather strip.
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property var space
    anchors.fill: parent

    readonly property string endpoint: "http://panxito-today.l4local.net/api/today"
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
                try { payload = JSON.parse(x.responseText) }
                catch (e) { errorText = "Bad JSON: " + e }
            } else {
                errorText = space.tr("error_offline")
            }
        }
        x.send()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24 * space.unit
        spacing: 20

        Text {
            text: Qt.formatDate(space.localNow(), space.tr("date_format"))
            font.pixelSize: 36 * space.fontScale
            color: "#1a0f04"
        }

        Text {
            text: root.loading ? space.tr("loading") : root.errorText
            visible: text.length > 0
            font.pixelSize: 22 * space.fontScale
            color: "#8a7a6a"
        }

        Text {
            text: space.tr("section_agenda")
            font.pixelSize: 24 * space.fontScale
            font.weight: Font.Medium
            color: "#1a0f04"
            visible: root.payload !== null
        }
        Repeater {
            model: root.payload && root.payload.agenda ? root.payload.agenda : []
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 20
                Text {
                    text: modelData.time || "—"
                    Layout.preferredWidth: 140
                    font.pixelSize: 22 * space.fontScale
                    color: "#1a0f04"
                }
                Text {
                    text: modelData.title + (modelData.location ? "  —  " + modelData.location : "")
                    Layout.fillWidth: true
                    font.pixelSize: 22 * space.fontScale
                    color: "#1a0f04"
                    wrapMode: Text.WordWrap
                }
            }
        }
        Text {
            text: space.tr("agenda_empty")
            visible: root.payload && (!root.payload.agenda || root.payload.agenda.length === 0)
            font.pixelSize: 20 * space.fontScale
            color: "#8a7a6a"
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#eeeeee" }

        Text {
            text: space.tr("section_reminders")
            font.pixelSize: 24 * space.fontScale
            font.weight: Font.Medium
            color: "#1a0f04"
            visible: root.payload !== null
        }
        Repeater {
            model: root.payload && root.payload.overdue ? root.payload.overdue : []
            delegate: Text {
                required property var modelData
                text: "• " + modelData.title + (modelData.due ? "  (" + modelData.due + ")" : "")
                font.pixelSize: 22 * space.fontScale
                color: "#1a0f04"
            }
        }
        Text {
            text: space.tr("reminders_empty")
            visible: root.payload && (!root.payload.overdue || root.payload.overdue.length === 0)
            font.pixelSize: 20 * space.fontScale
            color: "#8a7a6a"
        }

        Item { Layout.fillHeight: true }
    }
}
