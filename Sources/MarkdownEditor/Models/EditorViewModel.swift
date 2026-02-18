import Foundation
import SwiftUI

// MARK: - EditorViewModel

/// Observable coordinator that bridges the `MarkdownDocument` binding
/// to the editor and preview panes.
///
/// Marked `@MainActor` to satisfy Swift 6 strict concurrency — all mutations
/// happen on the main thread since they drive SwiftUI updates.
@MainActor
@Observable
final class EditorViewModel {

    // MARK: Published state

    /// The raw Markdown text currently shown in the editor.
    /// Modifications here update both the editor pane and the live preview.
    var markdownText: String = ""

    /// Controls whether the editor or preview pane is focused (iPad compact mode).
    var selectedPane: Pane = .editor

    /// Whether the preview is shown side-by-side (true) or fullscreen (false).
    var showPreview: Bool = true

    /// The current insertion point / selection range used by formatting helpers.
    /// Stored as a plain range of the string's indices; updated by EditorPaneView.
    var selectedRange: Range<String.Index>? = nil

    // MARK: Pane enum

    enum Pane: String, CaseIterable {
        case editor = "Editor"
        case preview = "Preview"
    }

    // MARK: Formatting actions

    /// Wraps the currently selected text (or inserts placeholder) with `syntax`.
    ///
    /// - Parameters:
    ///   - prefix: The opening Markdown syntax string (e.g. `**`).
    ///   - suffix: The closing Markdown syntax string (e.g. `**`).
    ///   - placeholder: Text to insert when there is no selection.
    func applyInlineFormat(prefix: String, suffix: String, placeholder: String) {
        if let range = selectedRange, !range.isEmpty {
            let selected = String(markdownText[range])
            let replacement = prefix + selected + suffix
            markdownText.replaceSubrange(range, with: replacement)
            // Move selection past the newly inserted prefix
            if let newStart = markdownText.index(range.lowerBound, offsetBy: prefix.count, limitedBy: markdownText.endIndex) {
                let newEnd = markdownText.index(newStart, offsetBy: selected.count, limitedBy: markdownText.endIndex) ?? newStart
                selectedRange = newStart..<newEnd
            }
        } else {
            // No selection — insert markers with placeholder
            insertAtCursor(prefix + placeholder + suffix)
        }
    }

    /// Inserts a heading prefix at the beginning of the current line.
    func applyHeading(level: Int) {
        let prefix = String(repeating: "#", count: level) + " "
        insertAtCursor(prefix)
    }

    /// Inserts a link skeleton `[text](url)`.
    func insertLink() {
        if let range = selectedRange, !range.isEmpty {
            let selected = String(markdownText[range])
            markdownText.replaceSubrange(range, with: "[\(selected)](url)")
        } else {
            insertAtCursor("[link text](url)")
        }
    }

    /// Inserts a fenced code block.
    func insertCodeBlock() {
        insertAtCursor("```\ncode here\n```")
    }

    /// Inserts a blockquote prefix.
    func insertBlockquote() {
        insertAtCursor("> ")
    }

    // MARK: Private helpers

    private func insertAtCursor(_ text: String) {
        if let range = selectedRange {
            markdownText.insert(contentsOf: text, at: range.lowerBound)
        } else {
            markdownText.append(text)
        }
    }
}
