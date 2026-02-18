import Foundation
import SwiftUI

@MainActor
@Observable
public final class EditorViewModel {

    public var markdownText: String = ""
    public var selectedPane: Pane = .editor
    public var showPreview: Bool = true
    public var showOutline: Bool = false
    public var focusMode: Bool = false
    public var documentURL: URL? = nil

    public init() {}

    public enum Pane: String, CaseIterable {
        case editor = "Editor"
        case preview = "Preview"
    }

    // MARK: - Statistics

    public var wordCount: Int {
        let words = markdownText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.count
    }

    public var characterCount: Int {
        markdownText.count
    }

    public var readingTime: String {
        let minutes = max(1, wordCount / 238)
        return "\(minutes) min read"
    }

    // MARK: - Outline

    public var headings: [(level: Int, text: String, slug: String)] {
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

    public func applyInlineFormat(prefix: String, suffix: String, placeholder: String) {
        insertAtCursor(prefix + placeholder + suffix)
    }

    public func applyHeading(level: Int) {
        let prefix = String(repeating: "#", count: level) + " "
        insertAtCursor("\n" + prefix)
    }

    public func insertLink() {
        insertAtCursor("[link text](url)")
    }

    public func insertCodeBlock() {
        insertAtCursor("```\ncode here\n```")
    }

    public func insertBlockquote() {
        insertAtCursor("\n> ")
    }

    public func insertStrikethrough() {
        insertAtCursor("~~text~~")
    }

    public func insertHighlight() {
        insertAtCursor("==highlighted==")
    }

    public func insertTaskList() {
        insertAtCursor("\n- [ ] ")
    }

    public func insertTable() {
        insertAtCursor("\n| Column 1 | Column 2 |\n|----------|----------|\n| Cell 1   | Cell 2   |\n")
    }

    public func insertHorizontalRule() {
        insertAtCursor("\n---\n")
    }

    public func insertImage() {
        insertAtCursor("![alt text](image.png)")
    }

    // MARK: - Toggle task checkbox

    public func toggleCheckbox(at lineContent: String) {
        if let range = markdownText.range(of: "- [ ] " + lineContent) {
            markdownText.replaceSubrange(range, with: "- [x] " + lineContent)
        } else if let range = markdownText.range(of: "- [x] " + lineContent) {
            markdownText.replaceSubrange(range, with: "- [ ] " + lineContent)
        }
    }

    // MARK: - Export

    public func exportHTML() -> String {
        HTMLExporter.export(markdownText)
    }

    private func insertAtCursor(_ text: String) {
        markdownText.append(text)
    }
}
