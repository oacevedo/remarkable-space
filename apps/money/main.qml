// Full page: account list with balances.
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property var space
    anchors.fill: parent

    readonly property string endpoint: "http://simplefin.l4local.net/api/accounts"
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

    function fmt(n) {
        if (n === undefined || n === null) return "—"
        var s = n.toFixed(2)
        return "$" + s.replace(/\B(?=(\d{3})+(?!\.))/g, ",")
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24 * space.unit
        spacing: 16

        Text {
            text: space.tr("accounts")
            font.pixelSize: 28 * space.fontScale
            font.weight: Font.Medium
            color: "#1a0f04"
        }

        Repeater {
            model: root.payload && root.payload.accounts ? root.payload.accounts : []
            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 20
                Text {
                    text: modelData.name
                    Layout.fillWidth: true
                    font.pixelSize: 22 * space.fontScale
                    color: "#1a0f04"
                    elide: Text.ElideRight
                }
                Text {
                    text: root.fmt(modelData.balance)
                    font.pixelSize: 22 * space.fontScale
                    font.weight: Font.Medium
                    color: modelData.balance < 0 ? "#8a1a0a" : "#1a0f04"
                }
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#eeeeee" }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: space.tr("total")
                Layout.fillWidth: true
                font.pixelSize: 24 * space.fontScale
                font.weight: Font.Medium
                color: "#1a0f04"
            }
            Text {
                text: root.payload ? root.fmt(root.payload.total) : "—"
                font.pixelSize: 24 * space.fontScale
                font.weight: Font.Medium
                color: "#1a0f04"
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
