import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

struct PreviewPaneView: View {

    @Bindable var viewModel: EditorViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var scrollTarget: String? = nil

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    renderBlocks(from: viewModel.markdownText)

                    // Render footnote definitions at end
                    let defs = collectFootnoteDefinitions(viewModel.markdownText)
                    if !defs.isEmpty {
                        Divider().padding(.vertical, 16)
                        ForEach(Array(defs.enumerated()), id: \.offset) { idx, def in
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text("\(def.id).")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                Text(inlineMarkdown(def.text))
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                            .id("fn-\(def.id)")
                            .padding(.vertical, 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
            .onChange(of: scrollTarget) { _, target in
                if let target {
                    withAnimation { proxy.scrollTo(target, anchor: .top) }
                    scrollTarget = nil
                }
            }
        }
        .environment(\.openURL, OpenURLAction { url in
            if let fragment = url.fragment {
                scrollTarget = fragment
                return .handled
            }
            return .systemAction
        })
        .background(backgroundColor)
    }

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.12, green: 0.12, blue: 0.14)
            : Color(red: 1.0, green: 1.0, blue: 1.0)
    }

    // MARK: - Block renderer

    @ViewBuilder
    private func renderBlocks(from markdown: String) -> some View {
        let blocks = parseBlocks(markdown)
        ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
            switch block {
            case .heading(let text, let level):
                headingView(text, level: level)
                    .id(headingSlug(text))
                    .padding(.top, level == 1 ? 16 : 12)
                    .padding(.bottom, 4)
            case .codeBlock(let code, _):
                codeBlockView(code)
                    .padding(.vertical, 8)
            case .blockquote(let lines):
                blockquoteView(lines)
                    .padding(.vertical, 4)
            case .callout(let kind, let lines):
                calloutView(kind: kind, lines: lines)
                    .padding(.vertical, 8)
            case .horizontalRule:
                Divider().padding(.vertical, 12)
            case .listItem(let text, let ordered, let number, let indent):
                listItemView(text, ordered: ordered, number: number, indent: indent)
                    .padding(.vertical, 2)
            case .taskItem(let text, let checked):
                taskItemView(text: text, checked: checked)
                    .padding(.vertical, 2)
            case .table(let headers, let rows):
                tableView(headers: headers, rows: rows)
                    .padding(.vertical, 8)
            case .image(let alt, let source):
                imageView(alt: alt, source: source)
                    .padding(.vertical, 8)
            case .footnoteRef:
                EmptyView()
            case .paragraph(let text):
                if text.trimmingCharacters(in: .whitespaces).isEmpty {
                    Spacer().frame(height: 8)
                } else {
                    paragraphView(text)
                        .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Block views

    private func headingView(_ text: String, level: Int) -> some View {
        Text(inlineMarkdown(text))
            .font(headingFont(level))
            .foregroundStyle(.primary)
    }

    private func codeBlockView(_ code: String) -> some View {
        Text(code)
            .font(.system(.callout, design: .monospaced))
            .foregroundStyle(.primary.opacity(0.85))
            .textSelection(.enabled)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(colorScheme == .dark
                          ? Color.white.opacity(0.06)
                          : Color.black.opacity(0.04))
            )
    }

    private func blockquoteView(_ lines: [String]) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(inlineMarkdown(line))
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.leading, 4)
    }

    private func calloutView(kind: CalloutKind, lines: [String]) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: kind.icon)
                .foregroundStyle(kind.color)
                .font(.body.bold())
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 4) {
                Text(kind.rawValue.uppercased())
                    .font(.caption.bold())
                    .foregroundStyle(kind.color)
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(inlineMarkdown(line))
                        .font(.body)
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(kind.color.opacity(colorScheme == .dark ? 0.12 : 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(kind.color.opacity(0.3), lineWidth: 1)
        )
    }

    private func listItemView(_ text: String, ordered: Bool, number: Int, indent: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(ordered ? "\(number)." : "\u{2022}")
                .foregroundStyle(.secondary)
                .frame(width: 20, alignment: .trailing)
            Text(inlineMarkdown(text))
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding(.leading, CGFloat(indent) * 20)
    }

    private func taskItemView(text: String, checked: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: checked ? "checkmark.square.fill" : "square")
                .foregroundStyle(checked ? Color.accentColor : Color.secondary)
                .onTapGesture { viewModel.toggleCheckbox(at: text) }
            Text(inlineMarkdown(text))
                .font(.body)
                .foregroundStyle(checked ? .secondary : .primary)
                .strikethrough(checked)
        }
    }

    private func paragraphView(_ text: String) -> some View {
        Text(inlineMarkdown(text))
            .font(.body)
            .foregroundStyle(.primary)
            .lineSpacing(4)
    }

    @ViewBuilder
    private func imageView(alt: String, source: String) -> some View {
        if let image = loadImage(source: source) {
            VStack(alignment: .leading, spacing: 4) {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 600)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                if !alt.isEmpty {
                    Text(alt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            HStack(spacing: 8) {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
                Text(alt.isEmpty ? source : alt)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(colorScheme == .dark
                          ? Color.white.opacity(0.06)
                          : Color.black.opacity(0.04))
            )
        }
    }

    private func loadImage(source: String) -> Image? {
        if let url = URL(string: source), url.scheme == "https" || url.scheme == "http" {
            return nil
        }
        let candidates: [URL] = {
            var urls: [URL] = []
            if let docURL = viewModel.documentURL {
                let docDir = docURL.deletingLastPathComponent()
                urls.append(docDir.appendingPathComponent(source))
            }
            urls.append(URL(fileURLWithPath: source))
            return urls
        }()
        for url in candidates {
            #if canImport(AppKit)
            if let nsImage = NSImage(contentsOf: url) {
                return Image(nsImage: nsImage)
            }
            #elseif canImport(UIKit)
            if let data = try? Data(contentsOf: url),
               let uiImage = UIImage(data: data) {
                return Image(uiImage: uiImage)
            }
            #endif
        }
        return nil
    }

    private func tableView(headers: [String], rows: [[String]]) -> some View {
        let borderColor = colorScheme == .dark
            ? Color.white.opacity(0.15)
            : Color.black.opacity(0.12)

        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array(headers.enumerated()), id: \.offset) { col, header in
                    Text(inlineMarkdown(header))
                        .font(.body.bold())
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if col < headers.count - 1 {
                        borderColor.frame(width: 1)
                    }
                }
            }
            .background(colorScheme == .dark
                        ? Color.white.opacity(0.06)
                        : Color.black.opacity(0.04))

            borderColor.frame(height: 1)

            ForEach(Array(rows.enumerated()), id: \.offset) { rowIdx, row in
                HStack(spacing: 0) {
                    ForEach(0..<headers.count, id: \.self) { col in
                        Text(inlineMarkdown(col < row.count ? row[col] : ""))
                            .font(.body)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if col < headers.count - 1 {
                            borderColor.frame(width: 1)
                        }
                    }
                }
                .background(rowIdx % 2 == 1
                            ? (colorScheme == .dark
                               ? Color.white.opacity(0.03)
                               : Color.black.opacity(0.02))
                            : Color.clear)
                if rowIdx < rows.count - 1 {
                    borderColor.frame(height: 1)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    // MARK: - Inline markdown with extensions

    private func inlineMarkdown(_ text: String) -> AttributedString {
        var processed = text

        // ==highlight== → uses a placeholder we'll style after
        // ^superscript^ and ~subscript~ — replace with unicode approximation
        // Footnote references [^N] → superscript number
        processed = applyInlineExtensions(processed)

        let opts = AttributedString.MarkdownParsingOptions(
            allowsExtendedAttributes: true,
            interpretedSyntax: .inlineOnly
        )
        var result: AttributedString
        if let parsed = try? AttributedString(markdown: processed, options: opts) {
            result = parsed
        } else {
            result = AttributedString(processed)
        }

        // Apply highlight styling (look for text between ‹HL› markers)
        applyHighlightStyling(&result)

        // Autolink bare URLs
        autolinkURLs(in: &result, source: processed)

        return result
    }

    private func applyInlineExtensions(_ text: String) -> String {
        var result = text

        // ==highlight== → ‹HL›text‹/HL›  (temporary markers)
        let highlightPattern = try? NSRegularExpression(pattern: #"==(.*?)=="#)
        if let matches = highlightPattern?.matches(in: result, range: NSRange(result.startIndex..., in: result)) {
            for match in matches.reversed() {
                guard let fullRange = Range(match.range, in: result),
                      let innerRange = Range(match.range(at: 1), in: result) else { continue }
                let inner = String(result[innerRange])
                result.replaceSubrange(fullRange, with: "‹HL›\(inner)‹/HL›")
            }
        }

        // ^superscript^ → Unicode superscript (limited)
        let supPattern = try? NSRegularExpression(pattern: #"\^([^\^]+)\^"#)
        if let matches = supPattern?.matches(in: result, range: NSRange(result.startIndex..., in: result)) {
            for match in matches.reversed() {
                guard let fullRange = Range(match.range, in: result),
                      let innerRange = Range(match.range(at: 1), in: result) else { continue }
                let inner = String(result[innerRange])
                result.replaceSubrange(fullRange, with: toSuperscript(inner))
            }
        }

        // ~subscript~ (single tilde, not ~~strikethrough~~)
        let subPattern = try? NSRegularExpression(pattern: #"(?<!~)~(?!~)([^~]+)(?<!~)~(?!~)"#)
        if let matches = subPattern?.matches(in: result, range: NSRange(result.startIndex..., in: result)) {
            for match in matches.reversed() {
                guard let fullRange = Range(match.range, in: result),
                      let innerRange = Range(match.range(at: 1), in: result) else { continue }
                let inner = String(result[innerRange])
                result.replaceSubrange(fullRange, with: toSubscript(inner))
            }
        }

        // Footnote references [^N] → superscript with link
        let fnPattern = try? NSRegularExpression(pattern: #"\[\^(\w+)\]"#)
        if let matches = fnPattern?.matches(in: result, range: NSRange(result.startIndex..., in: result)) {
            for match in matches.reversed() {
                guard let fullRange = Range(match.range, in: result),
                      let idRange = Range(match.range(at: 1), in: result) else { continue }
                let fnId = String(result[idRange])
                // Don't replace footnote definition lines
                if !result.hasPrefix("[^\(fnId)]:") {
                    result.replaceSubrange(fullRange, with: "[\(toSuperscript(fnId))](\(fnId)#fn-\(fnId))")
                }
            }
        }

        return result
    }

    private func applyHighlightStyling(_ result: inout AttributedString) {
        let plain = String(result.characters)
        let startMarker = "‹HL›"
        let endMarker = "‹/HL›"

        var searchStart = plain.startIndex
        while let markerStart = plain.range(of: startMarker, range: searchStart..<plain.endIndex),
              let markerEnd = plain.range(of: endMarker, range: markerStart.upperBound..<plain.endIndex) {

            let contentRange = markerStart.upperBound..<markerEnd.lowerBound
            if let attrContentStart = AttributedString.Index(contentRange.lowerBound, within: result),
               let attrContentEnd = AttributedString.Index(contentRange.upperBound, within: result) {
                result[attrContentStart..<attrContentEnd].backgroundColor =
                    colorScheme == .dark ? .yellow.opacity(0.3) : .yellow.opacity(0.4)
            }

            // Remove markers
            if let attrEndStart = AttributedString.Index(markerEnd.lowerBound, within: result),
               let attrEndEnd = AttributedString.Index(markerEnd.upperBound, within: result) {
                result.removeSubrange(attrEndStart..<attrEndEnd)
            }
            let updatedPlain = String(result.characters)
            if let newMarkerStart = updatedPlain.range(of: startMarker, range: searchStart..<updatedPlain.endIndex),
               let attrStartStart = AttributedString.Index(newMarkerStart.lowerBound, within: result),
               let attrStartEnd = AttributedString.Index(newMarkerStart.upperBound, within: result) {
                result.removeSubrange(attrStartStart..<attrStartEnd)
            }

            let currentPlain = String(result.characters)
            searchStart = currentPlain.index(searchStart, offsetBy: 1, limitedBy: currentPlain.endIndex) ?? currentPlain.endIndex
        }
    }

    private func autolinkURLs(in result: inout AttributedString, source: String) {
        let plain = String(result.characters)
        let urlPattern = try? NSRegularExpression(pattern: #"(?<!\(|\"|\[)https?://[^\s\)\]>\"']+"#)
        guard let matches = urlPattern?.matches(in: plain, range: NSRange(plain.startIndex..., in: plain)) else { return }
        for match in matches {
            guard let range = Range(match.range, in: plain),
                  let attrStart = AttributedString.Index(range.lowerBound, within: result),
                  let attrEnd = AttributedString.Index(range.upperBound, within: result) else { continue }
            let urlString = String(plain[range])
            if result[attrStart..<attrEnd].link == nil,
               let url = URL(string: urlString) {
                result[attrStart..<attrEnd].link = url
                result[attrStart..<attrEnd].foregroundColor = .accentColor
            }
        }
    }

    // MARK: - Super/subscript helpers

    private static let superscriptMap: [Character: String] = [
        "0": "\u{2070}", "1": "\u{00B9}", "2": "\u{00B2}", "3": "\u{00B3}",
        "4": "\u{2074}", "5": "\u{2075}", "6": "\u{2076}", "7": "\u{2077}",
        "8": "\u{2078}", "9": "\u{2079}", "+": "\u{207A}", "-": "\u{207B}",
        "=": "\u{207C}", "(": "\u{207D}", ")": "\u{207E}", "n": "\u{207F}",
        "i": "\u{2071}",
    ]

    private static let subscriptMap: [Character: String] = [
        "0": "\u{2080}", "1": "\u{2081}", "2": "\u{2082}", "3": "\u{2083}",
        "4": "\u{2084}", "5": "\u{2085}", "6": "\u{2086}", "7": "\u{2087}",
        "8": "\u{2088}", "9": "\u{2089}", "+": "\u{208A}", "-": "\u{208B}",
        "=": "\u{208C}", "(": "\u{208D}", ")": "\u{208E}",
    ]

    private func toSuperscript(_ text: String) -> String {
        String(text.map { Self.superscriptMap[$0].map { Character($0) } ?? $0 })
    }

    private func toSubscript(_ text: String) -> String {
        String(text.map { Self.subscriptMap[$0].map { Character($0) } ?? $0 })
    }

    // MARK: - Heading helpers

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: .system(size: 28, weight: .bold)
        case 2: .system(size: 24, weight: .bold)
        case 3: .system(size: 20, weight: .semibold)
        case 4: .system(size: 18, weight: .semibold)
        case 5: .system(size: 16, weight: .medium)
        case 6: .system(size: 14, weight: .medium)
        default: .system(size: 14, weight: .medium)
        }
    }

    private func headingSlug(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
    }

    // MARK: - Callout types

    enum CalloutKind: String, CaseIterable {
        case note = "Note"
        case tip = "Tip"
        case important = "Important"
        case warning = "Warning"
        case caution = "Caution"

        var icon: String {
            switch self {
            case .note: "info.circle.fill"
            case .tip: "lightbulb.fill"
            case .important: "exclamationmark.circle.fill"
            case .warning: "exclamationmark.triangle.fill"
            case .caution: "flame.fill"
            }
        }

        var color: Color {
            switch self {
            case .note: .blue
            case .tip: .green
            case .important: .purple
            case .warning: .orange
            case .caution: .red
            }
        }

        static func from(_ tag: String) -> CalloutKind? {
            let lower = tag.lowercased()
            return allCases.first { $0.rawValue.lowercased() == lower }
        }
    }

    // MARK: - Block model

    private enum Block {
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

    // MARK: - Footnote collector

    private struct FootnoteDef {
        let id: String
        let text: String
    }

    private func collectFootnoteDefinitions(_ markdown: String) -> [FootnoteDef] {
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

    // MARK: - Block parser

    private func parseBlocks(_ markdown: String) -> [Block] {
        let lines = markdown.components(separatedBy: "\n")
        var blocks: [Block] = []
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
                codeBuffer.append(line)
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

    // MARK: - Line parsers

    private func parseHeading(_ line: String) -> (Int, String)? {
        for level in (1...6).reversed() {
            let prefix = String(repeating: "#", count: level) + " "
            if line.hasPrefix(prefix) {
                return (level, String(line.dropFirst(prefix.count)))
            }
        }
        return nil
    }

    private func isHorizontalRule(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3 else { return false }
        return trimmed.allSatisfy({ $0 == "-" })
            || trimmed.allSatisfy({ $0 == "*" })
            || trimmed.allSatisfy({ $0 == "_" })
    }

    private func parseTaskItem(_ line: String) -> (String, Bool)? {
        let trimmed = line.trimmingCharacters(in: .init(charactersIn: " \t"))
        if trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("- [X] ") {
            return (String(trimmed.dropFirst(6)), true)
        }
        if trimmed.hasPrefix("- [ ] ") {
            return (String(trimmed.dropFirst(6)), false)
        }
        return nil
    }

    private func parseUnorderedListItem(_ line: String) -> (String, Int)? {
        var indent = 0
        var idx = line.startIndex
        while idx < line.endIndex && (line[idx] == " " || line[idx] == "\t") {
            indent += line[idx] == "\t" ? 1 : 0
            if line[idx] == " " {
                // Count groups of 2 spaces as one indent level
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

    private func parseOrderedListItem(_ line: String) -> (Int, String)? {
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

    private func parseCalloutStart(_ line: String) -> CalloutKind? {
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

    private func stripBlockquotePrefix(_ line: String) -> String {
        if line.hasPrefix("> ") { return String(line.dropFirst(2)) }
        if line.hasPrefix(">") { return String(line.dropFirst(1)) }
        return line
    }

    private func isFootnoteDefinition(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let pattern = try? NSRegularExpression(pattern: #"^\[\^\w+\]:"#)
        let ns = trimmed as NSString
        return pattern?.firstMatch(in: trimmed, range: NSRange(location: 0, length: ns.length)) != nil
    }

    private func isTableRow(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("|") && trimmed.hasSuffix("|") && trimmed.count > 1
    }

    private func isTableSeparator(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("|") && trimmed.hasSuffix("|") else { return false }
        let inner = trimmed.dropFirst().dropLast()
        return inner.allSatisfy { $0 == "-" || $0 == "|" || $0 == ":" || $0 == " " }
            && inner.contains("-")
    }

    private func parseTableCells(_ line: String) -> [String] {
        var trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("|") { trimmed = String(trimmed.dropFirst()) }
        if trimmed.hasSuffix("|") { trimmed = String(trimmed.dropLast()) }
        return trimmed.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private func parseImage(_ line: String) -> (String, String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("![") else { return nil }
        guard let closeBracket = trimmed.range(of: "](") else { return nil }
        guard trimmed.hasSuffix(")") else { return nil }
        let alt = String(trimmed[trimmed.index(trimmed.startIndex, offsetBy: 2)..<closeBracket.lowerBound])
        let src = String(trimmed[closeBracket.upperBound..<trimmed.index(before: trimmed.endIndex)])
        return (alt, src)
    }
}
