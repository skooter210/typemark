import Foundation

// MARK: - MarkdownFormatter

/// Pure functions for applying Markdown formatting to a string.
///
/// All functions are static and operate on plain `String` values.
/// No SwiftUI or AppKit dependencies.
enum MarkdownFormatter {

    // MARK: Inline formatting

    /// Wraps `text` with `**` for bold.
    static func bold(_ text: String) -> String {
        wrap(text, with: "**", placeholder: "bold text")
    }

    /// Wraps `text` with `*` for italic.
    static func italic(_ text: String) -> String {
        wrap(text, with: "*", placeholder: "italic text")
    }

    /// Wraps `text` with `` ` `` for inline code.
    static func inlineCode(_ text: String) -> String {
        wrap(text, prefix: "`", suffix: "`", placeholder: "code")
    }

    /// Wraps `text` with `~~` for strikethrough.
    static func strikethrough(_ text: String) -> String {
        wrap(text, with: "~~", placeholder: "strikethrough text")
    }

    // MARK: Block formatting

    /// Prepends `#` characters for a heading of the given level (1–6).
    static func heading(_ text: String, level: Int) -> String {
        let clamped = min(max(level, 1), 6)
        let prefix = String(repeating: "#", count: clamped) + " "
        if text.isEmpty {
            return prefix + "Heading"
        }
        return prefix + text
    }

    /// Wraps text in a fenced code block with an optional language identifier.
    static func fencedCodeBlock(_ text: String, language: String = "") -> String {
        "```\(language)\n\(text.isEmpty ? "code here" : text)\n```"
    }

    /// Prepends `> ` to each line for a blockquote.
    static func blockquote(_ text: String) -> String {
        if text.isEmpty { return "> blockquote" }
        return text
            .components(separatedBy: "\n")
            .map { "> " + $0 }
            .joined(separator: "\n")
    }

    /// Inserts a Markdown link. If `text` is non-empty it becomes the label.
    static func link(label: String, url: String = "url") -> String {
        let label = label.isEmpty ? "link text" : label
        return "[\(label)](\(url))"
    }

    /// Inserts a Markdown image reference.
    static func image(alt: String = "alt text", url: String = "image-url") -> String {
        "![\(alt)](\(url))"
    }

    /// Inserts a horizontal rule.
    static func horizontalRule() -> String { "---" }

    // MARK: List helpers

    /// Converts each line of `text` to an unordered list item.
    static func unorderedList(_ text: String) -> String {
        lines(text, prefix: "- ", emptyPlaceholder: "- list item")
    }

    /// Converts each line of `text` to an ordered list item.
    static func orderedList(_ text: String) -> String {
        let parts = text.isEmpty ? ["list item"] : text.components(separatedBy: "\n")
        return parts.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
    }

    // MARK: Private helpers

    private static func wrap(_ text: String, with marker: String, placeholder: String) -> String {
        wrap(text, prefix: marker, suffix: marker, placeholder: placeholder)
    }

    private static func wrap(_ text: String, prefix: String, suffix: String, placeholder: String) -> String {
        let inner = text.isEmpty ? placeholder : text
        return "\(prefix)\(inner)\(suffix)"
    }

    private static func lines(_ text: String, prefix: String, emptyPlaceholder: String) -> String {
        if text.isEmpty { return emptyPlaceholder }
        return text
            .components(separatedBy: "\n")
            .map { prefix + $0 }
            .joined(separator: "\n")
    }
}
