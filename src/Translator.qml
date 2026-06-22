import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import "translator"
import "translator/TransParse.js" as TransParse
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

/**
 * Translator widget with the `trans` commandline tool.
 */
Item {
    id: root
    anchors.fill: parent

    // Sizes
    property real padding: 4

    // Layout: two columns when there is room (extended Ctrl+O / detached window), else stacked
    property int wideThreshold: 600
    readonly property bool wide: width >= wideThreshold

    // Widgets
    property var inputField: inputCanvas.inputTextArea

    // Widget variables
    property bool translationFor: false // Indicates if the translation is for an autocorrected text
    property string translatedText: ""
    property list<string> languages: []

    // Options
    property string targetLanguage: Config.options.language.translator.targetLanguage
    property string sourceLanguage: Config.options.language.translator.sourceLanguage
    property string hostLanguage: targetLanguage
    property string detectedLanguage: ""
    property string extId: "ii-eve-translator"
    property var recentLanguages: ExtensionManager.getExtensionConfig(root.extId, "recentLanguages", ["auto", "en"])
    property var history: ExtensionManager.getExtensionConfig(root.extId, "translationHistory", [])

    function recordHistory() {
        const input = root.inputField.text.trim();
        const output = root.translatedText.trim();
        if (input.length === 0 || output.length === 0) return;
        let hist = Array.from(root.history).filter(e =>
            !(e.input === input && e.source === root.sourceLanguage && e.target === root.targetLanguage));
        hist.unshift({ input, output, source: root.sourceLanguage, target: root.targetLanguage });
        hist = hist.slice(0, 13);
        root.history = hist;
        ExtensionManager.setExtensionConfig(root.extId, "translationHistory", hist);
    }

    function restoreHistory(entry) {
        root.sourceLanguage = entry.source;
        root.targetLanguage = entry.target;
        Config.options.language.translator.sourceLanguage = entry.source;
        Config.options.language.translator.targetLanguage = entry.target;
        root.inputField.text = entry.input;
        translateTimer.restart();
    }

    // States
    property bool showLanguageSelector: false
    property bool languageSelectorTarget: false // true for target language, false for source language

    function showLanguageSelectorDialog(isTargetLang: bool) {
        root.languageSelectorTarget = isTargetLang;
        root.showLanguageSelector = true
    }

    function addRecentLanguage(lang) {
        if (!lang || lang === "auto") return;
        let list = Array.from(root.recentLanguages).filter(l => l !== lang);
        list.unshift(lang);
        list = list.slice(0, 6);
        root.recentLanguages = list;
        ExtensionManager.setExtensionConfig(root.extId, "recentLanguages", list);
    }

    function swapLanguages() {
        if (root.sourceLanguage === "auto") {
            // Can't swap "auto" into target — use the detected language if known
            if (!root.detectedLanguage) return;
            root.sourceLanguage = root.targetLanguage;
            root.targetLanguage = root.detectedLanguage;
        } else {
            const s = root.sourceLanguage;
            root.sourceLanguage = root.targetLanguage;
            root.targetLanguage = s;
        }
        Config.options.language.translator.sourceLanguage = root.sourceLanguage;
        Config.options.language.translator.targetLanguage = root.targetLanguage;
        // Translate the current OUTPUT back through the swapped pair
        if (root.translatedText.trim().length > 0) {
            root.inputField.text = root.translatedText;
        }
        translateTimer.restart();
        root.detectedLanguage = "";
    }

    onFocusChanged: (focus) => {
        if (focus) {
            root.inputField.forceActiveFocus()
        }
    }

    Timer {
        id: historyRecordTimer
        interval: 1200
        repeat: false
        onTriggered: root.recordHistory()
    }

    Timer {
        id: translateTimer
        interval: Config.options.sidebar.translator.delay
        repeat: false
        onTriggered: () => {
            if (root.inputField.text.trim().length > 0) {
                // console.log("Translating with command:", translateProc.command);
                translateProc.running = false;
                translateProc.buffer = ""; // Clear the buffer
                translateProc.running = true; // Restart the process
            } else {
                root.translatedText = "";
            }
        }
    }

    Process {
        id: translateProc
        command: ["bash", "-c", `trans -brief -no-bidi`
            + ` -source '${StringUtils.shellSingleQuoteEscape(root.sourceLanguage)}'`
            + ` -target '${StringUtils.shellSingleQuoteEscape(root.targetLanguage)}'`
            + ` '${StringUtils.shellSingleQuoteEscape(root.inputField.text.trim())}'`]
        property string buffer: ""
        stdout: SplitParser {
            onRead: data => {
                translateProc.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            // With -brief mode, we get output with no metadata
            root.translatedText = translateProc.buffer.trim();
            historyRecordTimer.restart();
            root.fetchDetails();
            root.activeWordIndex = -1;
            root.wordSynonyms = [];
            if (root.sourceLanguage === "auto") root.detectLanguage(root.inputField.text);
            else root.detectedLanguage = "";
        }
    }

    Process {
        id: getLanguagesProc
        command: ["trans", "-list-languages", "-no-bidi"]
        property list<string> bufferList: ["auto"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                getLanguagesProc.bufferList.push(data.trim());
            }
        }
        onExited: (exitCode, exitStatus) => {
            // Ensure "auto" is always the first language
            let langs = getLanguagesProc.bufferList
                .filter(lang => lang.trim().length > 0 && lang !== "auto")
                .sort((a, b) => a.localeCompare(b));
            langs.unshift("auto");
            root.languages = langs;
            getLanguagesProc.bufferList = []; // Clear the buffer
        }
    }

    Process {
        id: ttsProc
        command: ["true"]
    }

    function speak(text, lang) {
        const t = (text || "").trim();
        if (t.length === 0) return;
        ttsProc.running = false;
        ttsProc.command = ["bash", "-c",
            `trans -speak -no-translate -no-bidi`
            + ` -source '${StringUtils.shellSingleQuoteEscape(lang || "auto")}'`
            + ` -target '${StringUtils.shellSingleQuoteEscape(lang || "auto")}'`
            + ` '${StringUtils.shellSingleQuoteEscape(t)}'`];
        ttsProc.running = true;
    }

    property var dictionaryEntries: []
    property var sentenceAlternatives: []
    readonly property bool isSingleWord: TransParse.isSingleWord(root.inputField ? root.inputField.text : "")

    property var wordSynonyms: []        // current popover synonyms
    property int activeWordIndex: -1

    Process {
        id: detailProc
        property string buffer: ""
        property bool wasWord: false
        command: ["true"]
        stdout: SplitParser { onRead: data => detailProc.buffer += data + "\n" }
        onExited: (code, status) => {
            if (detailProc.wasWord) {
                root.dictionaryEntries = TransParse.parseDictionary(detailProc.buffer);
                root.sentenceAlternatives = [];
            } else {
                root.sentenceAlternatives = TransParse.parseAlternatives(detailProc.buffer);
                root.dictionaryEntries = [];
            }
        }
    }

    Process {
        id: detectProc
        property string buffer: ""
        command: ["true"]
        stdout: SplitParser { onRead: data => detectProc.buffer += data + "\n" }
        onExited: (code, status) => {
            // `trans -identify` prints a verbose block with a "Code   <xx>" line.
            // Best-effort: leave detectedLanguage empty if it failed (e.g. Null response).
            const m = TransParse.stripAnsi(detectProc.buffer).match(/^Code\s+(\S+)/m);
            root.detectedLanguage = m ? m[1] : "";
        }
    }

    function detectLanguage(text) {
        const t = (text || "").trim();
        if (t.length === 0) { root.detectedLanguage = ""; return; }
        detectProc.running = false;
        detectProc.buffer = "";
        detectProc.command = ["bash", "-c",
            `trans -no-bidi -identify '${StringUtils.shellSingleQuoteEscape(t)}'`];
        detectProc.running = true;
    }

    function fetchDetails() {
        const text = root.inputField.text.trim();
        if (text.length === 0) { root.dictionaryEntries = []; root.sentenceAlternatives = []; return; }
        detailProc.running = false;
        detailProc.buffer = "";
        detailProc.wasWord = root.isSingleWord;
        const base = `-no-bidi -source '${StringUtils.shellSingleQuoteEscape(root.sourceLanguage)}'`
            + ` -target '${StringUtils.shellSingleQuoteEscape(root.targetLanguage)}'`
            + ` '${StringUtils.shellSingleQuoteEscape(text)}'`;
        if (root.isSingleWord) {
            detailProc.command = ["bash", "-c", `trans -d ${base}`];
        } else {
            detailProc.command = ["bash", "-c", `trans -show-translation n -show-alternatives y ${base}`];
        }
        detailProc.running = true;
    }

    Process {
        id: wordLookupProc
        property string buffer: ""
        command: ["true"]
        stdout: SplitParser { onRead: data => wordLookupProc.buffer += data + "\n" }
        onExited: (code, status) => {
            const entries = TransParse.parseDictionary(wordLookupProc.buffer);
            let syn = [];
            for (const e of entries) for (const m of e.meanings) syn = syn.concat(m.synonyms);
            // de-dup, drop the original word, cap
            root.wordSynonyms = Array.from(new Set(syn)).slice(0, 8);
        }
    }

    // Synonyms of a TARGET-language word: look it up target->source so the
    // dictionary's "Синонимы" come back in the target language.
    function lookupWord(word) {
        wordLookupProc.running = false;
        wordLookupProc.buffer = "";
        wordLookupProc.command = ["bash", "-c",
            `trans -d -no-bidi -source '${StringUtils.shellSingleQuoteEscape(root.targetLanguage)}'`
            + ` -target '${StringUtils.shellSingleQuoteEscape(root.sourceLanguage === "auto" ? "en" : root.sourceLanguage)}'`
            + ` '${StringUtils.shellSingleQuoteEscape(word)}'`];
        wordLookupProc.running = true;
    }

    function replaceOutputWord(wordIndex, newWord) {
        const words = root.translatedText.split(/(\s+)/); // keep separators
        // map word index (non-space tokens) to token index
        let count = -1;
        for (let i = 0; i < words.length; ++i) {
            if (/\S/.test(words[i])) {
                count++;
                if (count === wordIndex) { words[i] = newWord; break; }
            }
        }
        root.translatedText = words.join("");
    }

    GridLayout {
        anchors {
            fill: parent
            margins: root.padding
        }
        columns: root.wide ? 2 : 1
        rowSpacing: root.padding
        columnSpacing: root.padding

        LanguageBar {
            Layout.fillWidth: true
            Layout.columnSpan: root.wide ? 2 : 1
            sourceLanguage: root.sourceLanguage
            targetLanguage: root.targetLanguage
            detectedLanguage: root.detectedLanguage
            recentLanguages: root.recentLanguages
            onSourceClicked: root.showLanguageSelectorDialog(false)
            onTargetClicked: root.showLanguageSelectorDialog(true)
            onSwapClicked: root.swapLanguages()
            onHistoryRequested: historyPopover.open()
            onRecentPicked: (lang, isTarget) => {
                if (isTarget) {
                    root.targetLanguage = lang;
                    Config.options.language.translator.targetLanguage = lang;
                } else {
                    root.sourceLanguage = lang;
                    Config.options.language.translator.sourceLanguage = lang;
                }
                root.addRecentLanguage(lang);
                translateTimer.restart();
            }
        }

        // Source language + input
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.padding

            TextCanvas {
                id: inputCanvas
                isInput: true
                Layout.fillHeight: true
                placeholderText: Translation.tr("Enter text to translate...")
                onInputTextChanged: translateTimer.restart()

                GroupButton {
                    baseWidth: 36
                    implicitHeight: 36
                    buttonRadius: Appearance.rounding.small
                    enabled: inputCanvas.inputTextArea.text.trim().length > 0
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        iconSize: Appearance.font.pixelSize.larger
                        text: "volume_up"
                        color: enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                    }
                    onClicked: root.speak(inputCanvas.inputTextArea.text, root.sourceLanguage)
                }
                GroupButton {
                    id: pasteButton
                    baseWidth: 36
                    implicitHeight: 36
                    buttonRadius: Appearance.rounding.small
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        iconSize: Appearance.font.pixelSize.larger
                        text: "content_paste"
                        color: Appearance.colors.colOnLayer1
                    }
                    onClicked: root.inputField.text = Quickshell.clipboardText
                }
                GroupButton {
                    id: deleteButton
                    baseWidth: 36
                    implicitHeight: 36
                    buttonRadius: Appearance.rounding.small
                    enabled: inputCanvas.inputTextArea.text.length > 0
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        iconSize: Appearance.font.pixelSize.larger
                        text: "close"
                        color: deleteButton.enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                    }
                    onClicked: root.inputField.text = ""
                }
            }
        }

        // Target language + output
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.padding

            TextCanvas {
                id: outputCanvas
                isInput: false
                Layout.fillHeight: true
                placeholderText: Translation.tr("Translation goes here...")
                property bool hasTranslation: (root.translatedText.trim().length > 0)
                text: hasTranslation ? root.translatedText : ""
                interactive: true
                synonyms: root.wordSynonyms
                activeWordIndex: root.activeWordIndex
                onWordClicked: (i, w) => { root.activeWordIndex = i; root.lookupWord(w); }
                onSynonymChosen: (i, s) => { root.replaceOutputWord(i, s); root.activeWordIndex = -1; root.wordSynonyms = []; }

                GroupButton {
                    baseWidth: 36
                    implicitHeight: 36
                    buttonRadius: Appearance.rounding.small
                    enabled: outputCanvas.displayedText.trim().length > 0
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        iconSize: Appearance.font.pixelSize.larger
                        text: "volume_up"
                        color: enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                    }
                    onClicked: root.speak(outputCanvas.displayedText, root.targetLanguage)
                }
                GroupButton {
                    id: copyButton
                    baseWidth: 36
                    implicitHeight: 36
                    buttonRadius: Appearance.rounding.small
                    enabled: outputCanvas.displayedText.trim().length > 0
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        iconSize: Appearance.font.pixelSize.larger
                        text: "content_copy"
                        color: copyButton.enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                    }
                    onClicked: Quickshell.clipboardText = outputCanvas.displayedText
                }
                GroupButton {
                    id: searchButton
                    baseWidth: 36
                    implicitHeight: 36
                    buttonRadius: Appearance.rounding.small
                    enabled: outputCanvas.displayedText.trim().length > 0
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        iconSize: Appearance.font.pixelSize.larger
                        text: "travel_explore"
                        color: searchButton.enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                    }
                    onClicked: {
                        let url = Config.options.search.engineBaseUrl + outputCanvas.displayedText;
                        for (let site of Config.options.search.excludedSites) {
                            url += ` -site:${site}`;
                        }
                        Qt.openUrlExternally(url);
                    }
                }
            }
        }

        DictionaryCard {
            Layout.fillWidth: true
            Layout.columnSpan: root.wide ? 2 : 1
            dictionaryEntries: root.dictionaryEntries
            sentenceAlternatives: root.sentenceAlternatives
            onAlternativeChosen: (text) => { root.translatedText = text }
        }
    }

    Loader {
        id: historyPopover
        anchors.fill: parent
        active: false
        visible: active
        z: 9998
        function open() { active = true }
        function close() { active = false }
        sourceComponent: Item {
            MouseArea { // scrim
                anchors.fill: parent
                onClicked: historyPopover.close()
            }
            HistoryPopover {
                anchors.centerIn: parent
                width: Math.min(parent.width - 40, 480)
                height: Math.min(parent.height - 80, 520)
                history: root.history
                onCloseRequested: historyPopover.close()
                onEntryPicked: (entry) => {
                    root.restoreHistory(entry);
                    historyPopover.close();
                }
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: root.showLanguageSelector
        visible: root.showLanguageSelector
        z: 9999
        sourceComponent: SelectionDialog {
            id: languageSelectorDialog
            titleText: Translation.tr("Select Language")
            items: root.languages
            defaultChoice: root.languageSelectorTarget ? root.targetLanguage : root.sourceLanguage
            onCanceled: () => {
                root.showLanguageSelector = false;
            }
            onSelected: (result) => {
                root.showLanguageSelector = false;
                if (!result || result.length === 0) return; // No selection made

                if (root.languageSelectorTarget) {
                    root.targetLanguage = result;
                    Config.options.language.translator.targetLanguage = result; // Save to config
                } else {
                    root.sourceLanguage = result;
                    Config.options.language.translator.sourceLanguage = result; // Save to config
                }

                root.addRecentLanguage(result);
                translateTimer.restart(); // Restart translation after language change
            }
        }
    }
}
