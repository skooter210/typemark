import Foundation
import SwiftUI

@MainActor
@Observable
final class EditorViewModel {

    var markdownText: String = ""
    var selectedPane: Pane = .editor
    var showPreview: Bool = true
    var showOutline: Bool = false
    var focusMode: Bool = false
    var documentURL: URL? = nil

    enum Pane: String, CaseIterable {
        case editor = "Editor"
        case preview = "Preview"
    }

    // MARK: - Statistics

    var wordCount: Int {
        let words = markdownText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.count
    }

    var characterCount: Int {
        markdownText.count
    }

    var readingTime: String {
        let minutes = max(1, wordCount / 238)
        return "\(minutes) min read"
    }

    // MARK: - Outline

    var headings: [(level: Int, text: String, slug: String)] {
        markdownText.components(separatedBy: "\n").compactMap { line in
            for level in (1...6).reversed() {
                let prefix = String(repeating: "#", count: level) + " "
                if line.hasPrefix(prefix) {
                    let text = String(line.dropFirst(prefix.count))
                    let slug = text.lowercased()
                        .replacingOccurrences(of: " ", with: "-")
                        .filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
                    return (level, text, slug)
                }
            }
            return nil
        }
    }

    // MARK: - Formatting actions

    func applyInlineFormat(prefix: String, suffix: String, placeholder: String) {
        insertAtCursor(prefix + placeholder + suffix)
    }

    func applyHeading(level: Int) {
        let prefix = String(repeating: "#", count: level) + " "
        insertAtCursor("\n" + prefix)
    }

    func insertLink() {
        insertAtCursor("[link text](url)")
    }

    func insertCodeBlock() {
        insertAtCursor("```\ncode here\n```")
    }

    func insertBlockquote() {
        insertAtCursor("\n> ")
    }

    func insertStrikethrough() {
        insertAtCursor("~~text~~")
    }

    func insertHighlight() {
        insertAtCursor("==highlighted==")
    }

    func insertTaskList() {
        insertAtCursor("\n- [ ] ")
    }

    func insertTable() {
        insertAtCursor("\n| Column 1 | Column 2 |\n|----------|----------|\n| Cell 1   | Cell 2   |\n")
    }

    func insertHorizontalRule() {
        insertAtCursor("\n---\n")
    }

    func insertImage() {
        insertAtCursor("![alt text](image.png)")
    }

    // MARK: - Toggle task checkbox

    func toggleCheckbox(at lineContent: String) {
        if let range = markdownText.range(of: "- [ ] " + lineContent) {
            markdownText.replaceSubrange(range, with: "- [x] " + lineContent)
        } else if let range = markdownText.range(of: "- [x] " + lineContent) {
            markdownText.replaceSubrange(range, with: "- [ ] " + lineContent)
        }
    }

    // MARK: - Export

    func exportHTML() -> String {
        HTMLExporter.export(markdownText)
    }

    private func insertAtCursor(_ text: String) {
        markdownText.append(text)
    }
}
