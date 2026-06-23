import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property string sourceLanguage
    property string targetLanguage
    property string detectedLanguage
    property var recentLanguages: []
    implicitHeight: 40

    signal sourceClicked()
    signal targetClicked()
    signal swapClicked()
    signal historyRequested()
    signal recentPicked(string lang, bool isTarget)

    RowLayout {
        anchors.fill: parent
        spacing: 6

        LanguageSelectorButton {
            displayText: root.sourceLanguage === "auto" && root.detectedLanguage
                ? Translation.tr("auto (%1)").arg(root.detectedLanguage)
                : root.sourceLanguage
            onClicked: root.sourceClicked()
        }

        RippleButton {
            implicitWidth: 34
            implicitHeight: 34
            buttonRadius: Appearance.rounding.full
            colBackground: Appearance.colors.colLayer2
            colBackgroundHover: Appearance.colors.colLayer2Hover
            onClicked: root.swapClicked()
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "swap_horiz"
                iconSize: 20
                color: Appearance.colors.colOnLayer2
            }
            StyledToolTip { text: Translation.tr("Swap languages") }
        }

        LanguageSelectorButton {
            displayText: root.targetLanguage
            onClicked: root.targetClicked()
        }

        // Recent-language chips, horizontally scrollable. (The earlier tap →
        // tab-switch was caused by ExtensionManager.setExtensionConfig firing
        // refreshExtensions — history/recents now live in a private file — not by
        // this Flickable, so horizontal scrolling is safe to re-enable.)
        StyledFlickable {
            Layout.fillWidth: true
            implicitHeight: 34
            contentWidth: chipRow.implicitWidth
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            RowLayout {
                id: chipRow
                height: parent.height
                spacing: 5
                Repeater {
                    model: root.recentLanguages
                    delegate: RippleButton {
                        required property var modelData
                        implicitHeight: 30
                        implicitWidth: chipText.implicitWidth + 18
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.colors.colSecondaryContainer
                        colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                        onClicked: root.recentPicked(modelData, true)
                        contentItem: StyledText {
                            id: chipText
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnSecondaryContainer
                        }
                    }
                }
            }
        }

        RippleButton { // history
            implicitWidth: 34
            implicitHeight: 34
            buttonRadius: Appearance.rounding.full
            colBackground: Appearance.colors.colLayer2
            colBackgroundHover: Appearance.colors.colLayer2Hover
            onClicked: root.historyRequested()
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "history"
                iconSize: 20
                color: Appearance.colors.colOnLayer2
            }
            StyledToolTip { text: Translation.tr("History") }
        }
    }
}
