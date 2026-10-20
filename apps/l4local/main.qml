// Full page: tile grid of every service, color by status.
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property var space
    anchors.fill: parent

    readonly property string endpoint: "http://tools.l4local.net/api/status"
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

    function tileColor(status) {
        if (status === "ok") return "white"
        if (status === "broken") return "#1a0f04"
        return "#eeeeee"
    }
    function tileTextColor(status) {
        return status === "broken" ? "white" : "#1a0f04"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24 * space.unit
        spacing: 20

        Text {
            text: space.tr("title")
            font.pixelSize: 28 * space.fontScale
            font.weight: Font.Medium
            color: "#1a0f04"
        }

        GridView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.payload && root.payload.services ? root.payload.services : []
            cellWidth: Math.max(220, Math.floor(width / 3))
            cellHeight: 100 * space.unit
            delegate: Rectangle {
                required property var modelData
                width: GridView.view.cellWidth - 12
                height: GridView.view.cellHeight - 12
                radius: 8
                color: root.tileColor(modelData.status)
                border.color: "#1a0f04"
                border.width: 1
                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: modelData.name
                        font.pixelSize: 22 * space.fontScale
                        font.weight: Font.Medium
                        color: root.tileTextColor(modelData.status)
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.parent.width - 24
                        elide: Text.ElideRight
                    }
                    Text {
                        text: space.tr(modelData.status === "ok" ? "ok" : modelData.status === "broken" ? "broken" : "unknown")
                        font.pixelSize: 16 * space.fontScale
                        color: root.tileTextColor(modelData.status)
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.parent.width - 24
                    }
                }
            }
        }

        Text {
            text: root.loading ? space.tr("loading") : root.errorText
            visible: text.length > 0
            font.pixelSize: 20 * space.fontScale
            color: "#8a7a6a"
        }
    }
}
