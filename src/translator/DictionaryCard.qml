import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property var dictionaryEntries: []
    property var sentenceAlternatives: []
    signal alternativeChosen(string text)

    visible: dictionaryEntries.length > 0 || sentenceAlternatives.length > 0
    implicitHeight: (dictionaryEntries.length > 0 || sentenceAlternatives.length > 0) ? contentCol.implicitHeight + 24 : 0
    color: Appearance.colors.colLayer2
    radius: Appearance.rounding.normal

    ColumnLayout {
        id: contentCol
        anchors { fill: parent; margins: 12 }
        spacing: 10

        // Dictionary (single word)
        Repeater {
            model: root.dictionaryEntries
            delegate: ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 4
                StyledText {
                    text: modelData.partOfSpeech
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Bold
                    color: Appearance.colors.colPrimary
                }
                Repeater {
                    model: modelData.meanings
                    delegate: ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 1
                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.text
                            wrapMode: Text.Wrap
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer2
                        }
                        StyledText {
                            Layout.fillWidth: true
                            visible: modelData.synonyms.length > 0
                            text: Translation.tr("Synonyms: %1").arg(modelData.synonyms.join(", "))
                            wrapMode: Text.Wrap
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                        StyledText {
                            Layout.fillWidth: true
                            visible: modelData.example.length > 0
                            text: "“" + modelData.example + "”"
                            wrapMode: Text.Wrap
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.italic: true
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }
        }

        // Sentence alternatives
        StyledText {
            visible: root.sentenceAlternatives.length > 0
            text: Translation.tr("Alternatives")
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.Bold
            color: Appearance.colors.colPrimary
        }
        Repeater {
            model: root.sentenceAlternatives
            delegate: RippleButton {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: altText.implicitHeight + 14
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.colors.colLayer1
                colBackgroundHover: Appearance.colors.colLayer1Hover
                onClicked: root.alternativeChosen(modelData)
                contentItem: StyledText {
                    id: altText
                    anchors.fill: parent
                    anchors.margins: 8
                    text: modelData
                    wrapMode: Text.Wrap
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                }
            }
        }
    }
}
