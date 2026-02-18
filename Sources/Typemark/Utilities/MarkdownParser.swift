import Foundation
import SwiftUI

// MARK: - Block model

public enum MarkdownBlock: Equatable {
    case heading(String, Int)
    case codeBlock(String, String)
    case blockquote([String])
    case callout(CalloutKind, [String])
    case horizontalRule
    case listItem(String, ordered: Bool, number: Int, indent: Int)
    case taskItem(String, checked: Bool)
    case table(headers: [String], rows: [[String]])
    case image(alt: String, source: String)
    case footnoteRef(id: String, text: String)
    case paragraph(String)
}

// MARK: - Callout types

public enum CalloutKind: String, CaseIterable, Equatable, Sendable {
    case note = "Note"
    case tip = "Tip"
    case important = "Important"
    case warning = "Warning"
    case caution = "Caution"

    public var icon: String {
        switch self {
        case .note: "info.circle.fill"
        case .tip: "lightbulb.fill"
        case .important: "exclamationmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .caution: "flame.fill"
        }
    }

    public var color: Color {
        switch self {
        case .note: .blue
        case .tip: .green
        case .important: .purple
        case .warning: .orange
        case .caution: .red
        }
    }

    public static func from(_ tag: String) -> CalloutKind? {
        let lower = tag.lowercased()
        return allCases.first { $0.rawValue.lowercased() == lower }
    }
}

// MARK: - Footnote

public struct FootnoteDef: Equatable {
    public let id: String
    public let text: String

    public init(id: String, text: String) {
        self.id = id
        self.text = text
    }
}

// MARK: - Parser

public enum MarkdownParser {

    public static func parseBlocks(_ markdown: String) -> [MarkdownBlock] {
        let lines = markdown.components(separatedBy: "\n")
        var blocks: [MarkdownBlock] = []
        var i = 0
        var inFencedCode = false
        var codeBuffer: [String] = []
        var codeLanguage = ""

        while i < lines.count {
            let line = lines[i]

            // Fenced code blocks
            if line.hasPrefix("```") {
                if inFencedCode {
                    blocks.append(.codeBlock(codeBuffer.joined(separator: "\n"), codeLanguage))
                    inFencedCode = false
                    codeBuffer = []
                    codeLanguage = ""
                } else {
                    inFencedCode = true
                    codeLanguage = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                }
                i += 1
                continue
            }

            if inFencedCode {
                // Cap code blocks at 10,000 lines to prevent unbounded memory growth
                if codeBuffer.count < 10_000 {
                    codeBuffer.append(line)
                }
                i += 1
                continue
            }

            // Table
            if isTableRow(line), i + 1 < lines.count, isTableSeparator(lines[i + 1]) {
                let headers = parseTableCells(line)
                i += 2
                var rows: [[String]] = []
                while i < lines.count, isTableRow(lines[i]) {
                    rows.append(parseTableCells(lines[i]))
                    i += 1
                }
                blocks.append(.table(headers: headers, rows: rows))
                continue
            }

            // Callouts: > [!TYPE]
            if let calloutKind = parseCalloutStart(line) {
                i += 1
                var calloutLines: [String] = []
                while i < lines.count, lines[i].hasPrefix(">") {
                    let content = stripBlockquotePrefix(lines[i])
                    calloutLines.append(content)
                    i += 1
                }
                blocks.append(.callout(calloutKind, calloutLines))
                continue
            }

            // Multi-line blockquotes
            if line.hasPrefix(">") {
                var bqLines: [String] = []
                while i < lines.count, lines[i].hasPrefix(">") {
                    bqLines.append(stripBlockquotePrefix(lines[i]))
                    i += 1
                }
                blocks.append(.blockquote(bqLines))
                continue
            }

            // Image
            if let (alt, src) = parseImage(line) {
                blocks.append(.image(alt: alt, source: src))
                i += 1
                continue
            }

            // Heading
            if let (level, text) = parseHeading(line) {
                blocks.append(.heading(text, level))
                i += 1
                continue
            }

            // Horizontal rule
            if isHorizontalRule(line) {
                blocks.append(.horizontalRule)
                i += 1
                continue
            }

            // Task list items
            if let (text, checked) = parseTaskItem(line) {
                blocks.append(.taskItem(text, checked: checked))
                i += 1
                continue
            }

            // Unordered list (with indent)
            if let (text, indent) = parseUnorderedListItem(line) {
                blocks.append(.listItem(text, ordered: false, number: 0, indent: indent))
                i += 1
                continue
            }

            // Ordered list
            if let (num, rest) = parseOrderedListItem(line) {
                blocks.append(.listItem(rest, ordered: true, number: num, indent: 0))
                i += 1
                continue
            }

            // Footnote definition lines — skip (rendered at bottom)
            if isFootnoteDefinition(line) {
                blocks.append(.footnoteRef(id: "", text: ""))
                i += 1
                continue
            }

            // Paragraph
            blocks.append(.paragraph(line))
            i += 1
        }

        // Handle unclosed code fence
        if inFencedCode {
            blocks.append(.codeBlock(codeBuffer.joined(separator: "\n"), codeLanguage))
        }

        return blocks
    }

    // MARK: - Footnote collector

    public static func collectFootnoteDefinitions(_ markdown: String) -> [FootnoteDef] {
        let pattern = try? NSRegularExpression(pattern: #"^\[\^(\w+)\]:\s*(.+)$"#, options: .anchorsMatchLines)
        let ns = markdown as NSString
        guard let matches = pattern?.matches(in: markdown, range: NSRange(location: 0, length: ns.length)) else { return [] }
        return matches.compactMap { match in
            guard match.numberOfRanges == 3 else { return nil }
            let id = ns.substring(with: match.range(at: 1))
            let text = ns.substring(with: match.range(at: 2))
            return FootnoteDef(id: id, text: text)
        }
    }

    // MARK: - Heading slug

    public static func headingSlug(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
    }

    // MARK: - Line parsers

    public static func parseHeading(_ line: String) -> (Int, String)? {
        for level in (1...6).reversed() {
            let prefix = String(repeating: "#", count: level) + " "
            if line.hasPrefix(prefix) {
                return (level, String(line.dropFirst(prefix.count)))
            }
        }
        return nil
    }

    public static func isHorizontalRule(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3 else { return false }
        return trimmed.allSatisfy({ $0 == "-" })
            || trimmed.allSatisfy({ $0 == "*" })
            || trimmed.allSatisfy({ $0 == "_" })
    }

    public static func parseTaskItem(_ line: String) -> (String, Bool)? {
        let trimmed = line.trimmingCharacters(in: .init(charactersIn: " \t"))
        if trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("- [X] ") {
            return (String(trimmed.dropFirst(6)), true)
        }
        if trimmed.hasPrefix("- [ ] ") {
            return (String(trimmed.dropFirst(6)), false)
        }
        return nil
    }

    public static func parseUnorderedListItem(_ line: String) -> (String, Int)? {
        var indent = 0
        var idx = line.startIndex
        while idx < line.endIndex && (line[idx] == " " || line[idx] == "\t") {
            indent += line[idx] == "\t" ? 1 : 0
            if line[idx] == " " {
                let next = line.index(after: idx)
                if next < line.endIndex && line[next] == " " {
                    indent += 1
                    idx = line.index(after: next)
                    continue
                }
            }
            idx = line.index(after: idx)
        }
        let rest = line[idx...]
        if rest.hasPrefix("- ") || rest.hasPrefix("* ") || rest.hasPrefix("+ ") {
            return (String(rest.dropFirst(2)), indent)
        }
        return nil
    }

    public static func parseOrderedListItem(_ line: String) -> (Int, String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let pattern = try? NSRegularExpression(pattern: #"^(\d{1,4})\.\s(.*)$"#)
        let ns = trimmed as NSString
        if let match = pattern?.firstMatch(in: trimmed, range: NSRange(location: 0, length: ns.length)),
           match.numberOfRanges == 3 {
            let num = Int(ns.substring(with: match.range(at: 1))) ?? 1
            let rest = ns.substring(with: match.range(at: 2))
            return (num, rest)
        }
        return nil
    }

    public static func parseCalloutStart(_ line: String) -> CalloutKind? {
        guard line.hasPrefix(">") else { return nil }
        let trimmed = stripBlockquotePrefix(line)
        let pattern = try? NSRegularExpression(pattern: #"^\[!(\w+)\]"#)
        let ns = trimmed as NSString
        if let match = pattern?.firstMatch(in: trimmed, range: NSRange(location: 0, length: ns.length)),
           match.numberOfRanges == 2 {
            let tag = ns.substring(with: match.range(at: 1))
            return CalloutKind.from(tag)
        }
        return nil
    }

    public static func stripBlockquotePrefix(_ line: String) -> String {
        if line.hasPrefix("> ") { return String(line.dropFirst(2)) }
        if line.hasPrefix(">") { return String(line.dropFirst(1)) }
        return line
    }

    public static func isFootnoteDefinition(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let pattern = try? NSRegularExpression(pattern: #"^\[\^\w+\]:"#)
        let ns = trimmed as NSString
        return pattern?.firstMatch(in: trimmed, range: NSRange(location: 0, length: ns.length)) != nil
    }

    public static func isTableRow(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("|") && trimmed.hasSuffix("|") && trimmed.count > 1
    }

    public static func isTableSeparator(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("|") && trimmed.hasSuffix("|") else { return false }
        let inner = trimmed.dropFirst().dropLast()
        return inner.allSatisfy { $0 == "-" || $0 == "|" || $0 == ":" || $0 == " " }
            && inner.contains("-")
    }

    public static func parseTableCells(_ line: String) -> [String] {
        var trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("|") { trimmed = String(trimmed.dropFirst()) }
        if trimmed.hasSuffix("|") { trimmed = String(trimmed.dropLast()) }
        return trimmed.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    public static func parseImage(_ line: String) -> (String, String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("![") else { return nil }
        guard let closeBracket = trimmed.range(of: "](") else { return nil }
        guard trimmed.hasSuffix(")") else { return nil }
        let alt = String(trimmed[trimmed.index(trimmed.startIndex, offsetBy: 2)..<closeBracket.lowerBound])
        let src = String(trimmed[closeBracket.upperBound..<trimmed.index(before: trimmed.endIndex)])
        return (alt, src)
    }
}
