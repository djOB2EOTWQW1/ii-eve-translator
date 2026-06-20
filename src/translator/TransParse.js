.pragma library

// Strip ANSI escape sequences trans emits in verbose mode.
function stripAnsi(s) {
    return s.replace(/\[[0-9;]*m/g, "").replace(/\[[0-9]+m/g, "");
}

// Parse `trans -d` (dictionary) output into structured entries.
// Returns [{ partOfSpeech, meanings: [{ text, synonyms: [..], example }] }]
function parseDictionary(raw) {
    const lines = stripAnsi(raw).split("\n");
    const entries = [];
    let current = null;
    let meaning = null;
    let started = false;
    const posWords = /^(noun|verb|adjective|adverb|pronoun|preposition|conjunction|interjection|существительное|глагол|прилагательное|наречие|местоимение|предлог|союз|междометие)\b/i;
    for (let i = 0; i < lines.length; ++i) {
        const line = lines[i];
        const trimmed = line.trim();
        if (!started) { if (/определени|definition|–/.test(line)) started = true; continue; }
        if (trimmed.length === 0) continue;
        if (posWords.test(trimmed)) {
            current = { partOfSpeech: trimmed, meanings: [] };
            entries.push(current);
            meaning = null;
        } else if (current && /^Синонимы:|^Synonyms:/i.test(trimmed)) {
            if (meaning) meaning.synonyms = trimmed.replace(/^Синонимы:|^Synonyms:/i, "").split(",").map(s => s.trim()).filter(s => s.length);
        } else if (current && /^- "/.test(trimmed)) {
            if (meaning) meaning.example = trimmed.replace(/^- "/, "").replace(/"$/, "");
        } else if (current && /^\s{4}\S/.test(line)) {
            meaning = { text: trimmed, synonyms: [], example: "" };
            current.meanings.push(meaning);
        }
    }
    return entries;
}

// Parse `trans -show-alternatives` for whole-sentence alternative phrasings.
function parseAlternatives(raw) {
    const lines = stripAnsi(raw).split("\n");
    const alts = [];
    let inAlts = false;
    for (const line of lines) {
        if (/варианты перевода|translations of/i.test(line)) { inAlts = true; continue; }
        if (!inAlts) continue;
        const t = line.trim();
        if (t.length === 0 || /^\[/.test(t) || /->/.test(t)) continue;
        for (const part of t.split(",")) {
            const a = part.trim();
            if (a.length) alts.push(a);
        }
    }
    return alts.slice(0, 6);
}

function isSingleWord(text) {
    return text.trim().split(/\s+/).filter(w => w.length).length === 1;
}
