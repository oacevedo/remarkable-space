// Full page: current message big + recent history scroll.
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property var space
    anchors.fill: parent

    readonly property string endpoint: "http://flap.l4local.net/api/history?limit=20"
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

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 180 * space.unit
            color: "#1a0f04"
            radius: 8
            Column {
                anchors.centerIn: parent
                spacing: 10
                width: parent.width - 48
                Text {
                    text: root.payload && root.payload.current ? root.payload.current.text : "—"
                    color: "white"
                    font.family: "monospace"
                    font.pixelSize: 40 * space.fontScale
                    font.weight: Font.Medium
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }
                Text {
                    text: root.payload && root.payload.current && root.payload.current.sender
                          ? space.tr("by") + " " + root.payload.current.sender
                          : ""
                    color: "#aaaaaa"
                    font.pixelSize: 18 * space.fontScale
                    visible: text.length > 0
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }
            }
        }

        Text {
            text: space.tr("history")
            font.pixelSize: 24 * space.fontScale
            font.weight: Font.Medium
            color: "#1a0f04"
        }

        Repeater {
            model: root.payload && root.payload.history ? root.payload.history : []
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 20
                Text {
                    text: modelData.at
                    Layout.preferredWidth: 160
                    font.pixelSize: 18 * space.fontScale
                    color: "#8a7a6a"
                }
                Text {
                    text: modelData.text
                    Layout.fillWidth: true
                    font.pixelSize: 20 * space.fontScale
                    font.family: "monospace"
                    color: "#1a0f04"
                    elide: Text.ElideRight
                }
                Text {
                    text: modelData.sender || ""
                    font.pixelSize: 18 * space.fontScale
                    color: "#8a7a6a"
                }
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
