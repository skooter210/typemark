import Foundation
import SwiftUI

// MARK: - SyntaxHighlighter

/// Applies Markdown-aware color attributes to a plain `String`,
/// returning an `AttributedString` suitable for display in the editor pane.
///
/// Uses pre-compiled NSRegularExpression patterns for performance.
/// All regex matching is done against the raw String; results are then
/// mapped to AttributedString index ranges to apply attributes.
enum SyntaxHighlighter {

    // MARK: - Theme

    struct Theme {
        let heading: Color
        let bold: Color
        let italic: Color
        let code: Color
        let link: Color
        let blockquote: Color
        let punctuation: Color

        static let dark = Theme(
            heading:     Color(red: 0.40, green: 0.80, blue: 1.00),
            bold:        Color(red: 1.00, green: 0.85, blue: 0.55),
            italic:      Color(red: 0.65, green: 0.95, blue: 0.65),
            code:        Color(red: 1.00, green: 0.65, blue: 0.55),
            link:        Color(red: 0.45, green: 0.75, blue: 1.00),
            blockquote:  Color(red: 0.65, green: 0.65, blue: 0.65),
            punctuation: Color(red: 0.60, green: 0.60, blue: 0.60)
        )

        static let light = Theme(
            heading:     Color(red: 0.05, green: 0.30, blue: 0.70),
            bold:        Color(red: 0.55, green: 0.18, blue: 0.00),
            italic:      Color(red: 0.15, green: 0.40, blue: 0.10),
            code:        Color(red: 0.65, green: 0.10, blue: 0.05),
            link:        Color(red: 0.10, green: 0.35, blue: 0.75),
            blockquote:  Color(red: 0.35, green: 0.35, blue: 0.35),
            punctuation: Color(red: 0.40, green: 0.40, blue: 0.40)
        )
    }

    // MARK: - Regex patterns

    private static let patterns: [(regex: NSRegularExpression, role: Role)] = {
        let defs: [(String, NSRegularExpression.Options, Role)] = [
            // Fenced code blocks (multiline, must come first)
            (#"^```[\s\S]*?^```\s*$"#,     [.anchorsMatchLines], .code),
            // Headings
            (#"^#{1,6}\s+.*$"#,            [.anchorsMatchLines], .heading),
            // Bold (** or __)
            (#"\*\*(?!\s)(.+?)(?<!\s)\*\*|__(?!\s)(.+?)(?<!\s)__"#, [], .bold),
            // Italic (* or _) — only single markers
            (#"(?<!\*)\*(?!\*)(?!\s)(.+?)(?<!\s)(?<!\*)\*(?!\*)|(?<!_)_(?!_)(?!\s)(.+?)(?<!\s)(?<!_)_(?!_)"#, [], .italic),
            // Inline code
            (#"`[^`\n]+`"#,                [], .code),
            // Images (before links)
            (#"!\[[^\]]*\]\([^)]+\)"#,     [], .link),
            // Links
            (#"\[[^\]]+\]\([^)]+\)"#,      [], .link),
            // Blockquotes
            (#"^>.*$"#,                    [.anchorsMatchLines], .blockquote),
            // Horizontal rules
            (#"^(\*{3,}|-{3,}|_{3,})\s*$"#, [.anchorsMatchLines], .punctuation),
        ]
        return defs.compactMap { pattern, options, role in
            guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
            return (regex, role)
        }
    }()

    private enum Role {
        case heading, bold, italic, code, link, blockquote, punctuation
    }

    // MARK: - Public API

    /// Returns a syntax-highlighted `AttributedString` for `text`.
    static func highlight(_ text: String, colorScheme: ColorScheme) -> AttributedString {
        let theme = colorScheme == .dark ? Theme.dark : Theme.light
        var result = AttributedString(text)

        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)

        for (regex, role) in patterns {
            let matches = regex.matches(in: text, range: fullRange)
            for match in matches {
                guard let attrRange = attributedRange(from: match.range, in: text, attributed: result)
                else { continue }

                switch role {
                case .heading:
                    result[attrRange].foregroundColor = theme.heading
                    result[attrRange].font = .system(.body, design: .default, weight: .bold)
                case .bold:
                    result[attrRange].foregroundColor = theme.bold
                    result[attrRange].font = .system(.body, design: .default, weight: .bold)
                case .italic:
                    result[attrRange].foregroundColor = theme.italic
                    result[attrRange].font = .system(.body, design: .default).italic()
                case .code:
                    result[attrRange].foregroundColor = theme.code
                    result[attrRange].font = .system(.body, design: .monospaced)
                case .link:
                    result[attrRange].foregroundColor = theme.link
                case .blockquote:
                    result[attrRange].foregroundColor = theme.blockquote
                case .punctuation:
                    result[attrRange].foregroundColor = theme.punctuation
                }
            }
        }

        return result
    }

    // MARK: - Range conversion

    /// Converts an `NSRange` in the source `String` to a `Range<AttributedString.Index>`.
    private static func attributedRange(
        from nsRange: NSRange,
        in source: String,
        attributed: AttributedString
    ) -> Range<AttributedString.Index>? {
        // Step 1: NSRange → Range<String.Index>
        guard let stringRange = Range<String.Index>(nsRange, in: source) else { return nil }
        // Step 2: String.Index → AttributedString.Index
        guard
            let lower = AttributedString.Index(stringRange.lowerBound, within: attributed),
            let upper = AttributedString.Index(stringRange.upperBound, within: attributed)
        else { return nil }
        return lower..<upper
    }
}
