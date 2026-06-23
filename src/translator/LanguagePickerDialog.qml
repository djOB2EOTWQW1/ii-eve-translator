import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell

// Language picker with a search/filter field. Replaces the host SelectionDialog
// (which has no search) for the long `trans` language list.
Item {
    id: root
    property real dialogMargin: 30
    property real dialogPadding: 15
    property var languages: []
    property string current: ""
    signal selected(string lang)
    signal canceled()

    Component.onCompleted: searchField.forceActiveFocus()

    readonly property var filtered: {
        const q = searchField.text.trim().toLowerCase();
        if (q.length === 0) return root.languages;
        return root.languages.filter(l => l.toLowerCase().indexOf(q) !== -1);
    }

    Rectangle { // Scrim
        anchors.fill: parent
        radius: Appearance.rounding.small
        color: Appearance.colors.colScrim
        MouseArea { anchors.fill: parent; onClicked: root.canceled() }
    }

    Rectangle { // Dialog
        anchors.fill: parent
        anchors.margins: root.dialogMargin
        color: Appearance.m3colors.m3surfaceContainerHigh
        radius: Appearance.rounding.normal

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.dialogPadding
            spacing: 12

            StyledText {
                text: Translation.tr("Select Language")
                font.pixelSize: Appearance.font.pixelSize.larger
                color: Appearance.m3colors.m3onSurface
            }

            MaterialTextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: Translation.tr("Search language...")
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        root.canceled();
                        event.accepted = true;
                    }
                }
            }

            StyledListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4
                model: ScriptModel { values: root.filtered }
                delegate: RippleButton {
                    required property var modelData
                    anchors.left: parent?.left
                    anchors.right: parent?.right
                    implicitHeight: 38
                    buttonRadius: Appearance.rounding.small
                    colBackground: modelData === root.current
                        ? Appearance.colors.colSecondaryContainer : "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    onClicked: root.selected(modelData)
                    contentItem: StyledText {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData
                        color: modelData === root.current
                            ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                DialogButton {
                    buttonText: Translation.tr("Cancel")
                    onClicked: root.canceled()
                }
            }
        }
    }
}
