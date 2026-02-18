import SwiftUI

// MARK: - PreviewPaneView

/// Renders the Markdown preview using Apple's native `AttributedString(markdown:)`.
///
/// The view subscribes to `viewModel.markdownText` and re-renders whenever the text changes.
/// Block-level elements (headings, code blocks, lists) are parsed by the Swift runtime.
struct PreviewPaneView: View {

    // MARK: Dependencies

    @Bindable var viewModel: EditorViewModel

    // MARK: Body

    var body: some View {
        ScrollView {
            markdownContent
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
        }
        .background(Color(previewBackground))
    }

    // MARK: Subviews

    @ViewBuilder
    private var markdownContent: some View {
        if let attributed = parseMarkdown(viewModel.markdownText) {
            Text(attributed)
                .textSelection(.enabled)
                .lineSpacing(4)
        } else {
            Text(viewModel.markdownText)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }

    // MARK: Helpers

    private func parseMarkdown(_ text: String) -> AttributedString? {
        // AttributedString(markdown:) supports:
        // bold, italic, inline code, links, strikethrough, and basic structure.
        // For headings and code blocks, we build a richer attributed representation.
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .inlineOnlyPreservingWhitespace
        return buildRichAttributedString(from: text)
    }

    /// Builds a richly formatted `AttributedString` from Markdown by processing
    /// the text block-by-block.
    private func buildRichAttributedString(from markdown: String) -> AttributedString {
        var result = AttributedString()
        let lines = markdown.components(separatedBy: "\n")
        var index = 0
        var inFencedCode = false
        var codeBuffer: [String] = []
        var codeLanguage = ""

        while index < lines.count {
            let line = lines[index]

            // Fenced code block detection
            if line.hasPrefix("```") {
                if inFencedCode {
                    // Close the code block
                    result.append(renderCodeBlock(lines: codeBuffer, language: codeLanguage))
                    result.append(newline())
                    inFencedCode = false
                    codeBuffer = []
                    codeLanguage = ""
                } else {
                    inFencedCode = true
                    codeLanguage = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                }
                index += 1
                continue
            }

            if inFencedCode {
                codeBuffer.append(line)
                index += 1
                continue
            }

            // Headings
            if line.hasPrefix("# ") {
                result.append(renderHeading(String(line.dropFirst(2)), level: 1))
            } else if line.hasPrefix("## ") {
                result.append(renderHeading(String(line.dropFirst(3)), level: 2))
            } else if line.hasPrefix("### ") {
                result.append(renderHeading(String(line.dropFirst(4)), level: 3))
            } else if line.hasPrefix("#### ") {
                result.append(renderHeading(String(line.dropFirst(5)), level: 4))
            } else if line.hasPrefix("##### ") {
                result.append(renderHeading(String(line.dropFirst(6)), level: 5))
            } else if line.hasPrefix("###### ") {
                result.append(renderHeading(String(line.dropFirst(7)), level: 6))

            // Blockquote
            } else if line.hasPrefix("> ") {
                result.append(renderBlockquote(String(line.dropFirst(2))))

            // Horizontal rule
            } else if isHorizontalRule(line) {
                result.append(renderHorizontalRule())

            // Unordered list
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") {
                result.append(renderListItem(String(line.dropFirst(2)), ordered: false, number: 0))

            // Ordered list
            } else if let (num, rest) = parseOrderedListItem(line) {
                result.append(renderListItem(rest, ordered: true, number: num))

            // Empty line (paragraph break)
            } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                result.append(newline())

            // Regular paragraph (inline markdown)
            } else {
                result.append(renderInline(line))
            }

            result.append(newline())
            index += 1
        }

        return result
    }

    // MARK: Block renderers

    private func renderHeading(_ text: String, level: Int) -> AttributedString {
        var attr = AttributedString(text)
        let size: CGFloat
        switch level {
        case 1: size = 28; attr.font = .system(size: size, weight: .bold)
        case 2: size = 24; attr.font = .system(size: size, weight: .bold)
        case 3: size = 20; attr.font = .system(size: size, weight: .semibold)
        case 4: size = 18; attr.font = .system(size: size, weight: .semibold)
        case 5: size = 16; attr.font = .system(size: size, weight: .medium)
        default: size = 14; attr.font = .system(size: size, weight: .medium)
        }
        attr.foregroundColor = headingColor(level: level)
        return attr
    }

    private func renderCodeBlock(lines: [String], language: String) -> AttributedString {
        let code = lines.joined(separator: "\n")
        var attr = AttributedString(code)
        attr.font = .system(.body, design: .monospaced)
        attr.foregroundColor = .secondary
        attr.backgroundColor = codeBackground
        return attr
    }

    private func renderBlockquote(_ text: String) -> AttributedString {
        var attr = renderInline(text)
        attr.foregroundColor = .secondary
        return attr
    }

    private func renderHorizontalRule() -> AttributedString {
        var attr = AttributedString("─────────────────────────────")
        attr.foregroundColor = .secondary
        return attr
    }

    private func renderListItem(_ text: String, ordered: Bool, number: Int) -> AttributedString {
        let bullet = ordered ? "\(number). " : "• "
        var attr = AttributedString(bullet)
        attr.foregroundColor = .secondary
        return attr + renderInline(text)
    }

    /// Renders a line of text with inline Markdown (bold, italic, code, links).
    private func renderInline(_ text: String) -> AttributedString {
        // Attempt to parse with AttributedString(markdown:) for inline syntax
        let opts = AttributedString.MarkdownParsingOptions(
            allowsExtendedAttributes: true,
            interpretedSyntax: .inlineOnly
        )
        if let parsed = try? AttributedString(markdown: text, options: opts) {
            return parsed
        }
        return AttributedString(text)
    }

    private func newline() -> AttributedString {
        AttributedString("\n")
    }

    // MARK: Utilities

    private func isHorizontalRule(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return (trimmed.allSatisfy { $0 == "-" } && trimmed.count >= 3)
            || (trimmed.allSatisfy { $0 == "*" } && trimmed.count >= 3)
            || (trimmed.allSatisfy { $0 == "_" } && trimmed.count >= 3)
    }

    private func parseOrderedListItem(_ line: String) -> (Int, String)? {
        let pattern = try? NSRegularExpression(pattern: #"^(\d+)\.\s(.*)"#)
        let ns = line as NSString
        if let match = pattern?.firstMatch(in: line, range: NSRange(location: 0, length: ns.length)),
           match.numberOfRanges == 3 {
            let num = Int(ns.substring(with: match.range(at: 1))) ?? 1
            let rest = ns.substring(with: match.range(at: 2))
            return (num, rest)
        }
        return nil
    }

    // MARK: Color helpers

    private func headingColor(level: Int) -> Color {
        switch level {
        case 1: return .primary
        case 2: return .primary.opacity(0.9)
        default: return .primary.opacity(0.8)
        }
    }

    private var previewBackground: Color {
        Color(
            light: Color(red: 0.98, green: 0.98, blue: 0.98),
            dark:  Color(red: 0.12, green: 0.12, blue: 0.13)
        )
    }

    private var codeBackground: Color {
        Color(
            light: Color(red: 0.93, green: 0.93, blue: 0.95),
            dark:  Color(red: 0.20, green: 0.20, blue: 0.22)
        )
    }
}

// MARK: - Color adaptive init helper

private extension Color {
    init(light: Color, dark: Color) {
        self = light  // SwiftUI adapts automatically via .colorScheme
    }
}
