import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import "LangNames.js" as LangNames

Rectangle {
    id: root
    property var history: []
    signal entryPicked(var entry)
    signal entryDeleted(var entry)
    signal clearRequested()
    signal closeRequested()

    color: Appearance.m3colors.m3surfaceContainerHigh
    radius: Appearance.rounding.normal
    border.width: 1
    border.color: Appearance.colors.colOutlineVariant

    ColumnLayout { // Empty state, centered in the whole card
        anchors.centerIn: parent
        visible: root.history.length === 0
        spacing: 6
        MaterialSymbol {
            Layout.alignment: Qt.AlignHCenter
            text: "history"
            iconSize: 40
            color: Appearance.colors.colSubtext
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Translation.tr("No history yet")
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.small
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("History")
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer1
            }
            RippleButton { // clear all
                visible: root.history.length > 0
                implicitWidth: 30
                implicitHeight: 30
                buttonRadius: Appearance.rounding.full
                onClicked: root.clearRequested()
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "delete_sweep"
                    iconSize: 18
                    color: Appearance.colors.colOnLayer1
                }
                StyledToolTip { text: Translation.tr("Clear all") }
            }
            RippleButton {
                implicitWidth: 30
                implicitHeight: 30
                buttonRadius: Appearance.rounding.full
                onClicked: root.closeRequested()
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "close"
                    iconSize: 18
                    color: Appearance.colors.colOnLayer1
                }
            }
        }

        StyledListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.history.length > 0
            clip: true
            spacing: 6
            model: ScriptModel { values: root.history }
            delegate: RippleButton {
                required property var modelData
                anchors.left: parent?.left
                anchors.right: parent?.right
                implicitHeight: rowCol.implicitHeight + 16
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.colors.colLayer2
                colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: root.entryPicked(modelData)
                contentItem: RowLayout {
                    id: rowCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.input
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer2
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: Translation.tr("%1 → %2 · %3")
                                .arg(LangNames.display(modelData.source))
                                .arg(LangNames.display(modelData.target))
                                .arg(modelData.output)
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                    }
                    RippleButton { // delete this entry
                        implicitWidth: 28
                        implicitHeight: 28
                        buttonRadius: Appearance.rounding.full
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colLayer2Hover
                        onClicked: root.entryDeleted(modelData)
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "close"
                            iconSize: 16
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }
        }
    }
}
