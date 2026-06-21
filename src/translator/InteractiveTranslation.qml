import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

Flow {
    id: root
    property string text: ""
    property var synonyms: []          // bound to current popover synonyms
    property int activeIndex: -1
    signal wordClicked(int wordIndex, string word)
    signal synonymChosen(int wordIndex, string synonym)
    spacing: 0

    readonly property var words: text.length > 0 ? text.split(/\s+/).filter(w => w.length) : []

    Repeater {
        model: root.words
        delegate: Text {
            required property var modelData
            required property int index
            text: modelData + " "
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            font.underline: hover.hovered
            MouseArea {
                id: hover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.wordClicked(index, modelData)
            }
            // Per-word synonym popover
            Loader {
                active: root.activeIndex === index && root.synonyms.length > 0
                visible: active
                y: parent.height + 2
                sourceComponent: Rectangle {
                    width: synCol.implicitWidth + 12
                    height: synCol.implicitHeight + 12
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer0
                    border.width: 1
                    border.color: Appearance.colors.colOutlineVariant
                    z: 50
                    ColumnLayout {
                        id: synCol
                        anchors.centerIn: parent
                        spacing: 2
                        Repeater {
                            model: root.synonyms
                            delegate: RippleButton {
                                required property var modelData
                                implicitWidth: synText.implicitWidth + 16
                                implicitHeight: 26
                                buttonRadius: Appearance.rounding.small
                                colBackground: Appearance.colors.colLayer1
                                colBackgroundHover: Appearance.colors.colSecondaryContainer
                                onClicked: root.synonymChosen(index, modelData)
                                contentItem: StyledText {
                                    id: synText
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colOnLayer1
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
