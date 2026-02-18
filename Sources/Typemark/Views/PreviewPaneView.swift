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
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
            .onChange(of: scrollTarget) { _, target in
                if let target {
                    withAnimation {
                        proxy.scrollTo(target, anchor: .top)
                    }
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

    // MARK: - Block parser

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
            case .blockquote(let text):
                blockquoteView(text)
                    .padding(.vertical, 4)
            case .horizontalRule:
                Divider()
                    .padding(.vertical, 12)
            case .listItem(let text, let ordered, let number):
                listItemView(text, ordered: ordered, number: number)
                    .padding(.vertical, 2)
            case .table(let headers, let rows):
                tableView(headers: headers, rows: rows)
                    .padding(.vertical, 8)
            case .image(let alt, let source):
                imageView(alt: alt, source: source)
                    .padding(.vertical, 8)
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
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(colorScheme == .dark
                          ? Color.white.opacity(0.06)
                          : Color.black.opacity(0.04))
            )
    }

    private func blockquoteView(_ text: String) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 3)
            Text(inlineMarkdown(text))
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(.leading, 4)
    }

    private func listItemView(_ text: String, ordered: Bool, number: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(ordered ? "\(number)." : "\u{2022}")
                .foregroundStyle(.secondary)
                .frame(width: 20, alignment: .trailing)
            Text(inlineMarkdown(text))
                .font(.body)
                .foregroundStyle(.primary)
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
            // Header row
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

            // Data rows
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

    // MARK: - Inline markdown

    private func inlineMarkdown(_ text: String) -> AttributedString {
        let opts = AttributedString.MarkdownParsingOptions(
            allowsExtendedAttributes: true,
            interpretedSyntax: .inlineOnly
        )
        if let parsed = try? AttributedString(markdown: text, options: opts) {
            return parsed
        }
        return AttributedString(text)
    }

    // MARK: - Heading font

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: .system(size: 28, weight: .bold)
        case 2: .system(size: 24, weight: .bold)
        case 3: .system(size: 20, weight: .semibold)
        case 4: .system(size: 18, weight: .semibold)
        case 5: .system(size: 16, weight: .medium)
        default: .system(size: 14, weight: .medium)
        }
    }

    // MARK: - Block model

    private enum Block {
        case heading(String, Int)
        case codeBlock(String, String)
        case blockquote(String)
        case horizontalRule
        case listItem(String, ordered: Bool, number: Int)
        case table(headers: [String], rows: [[String]])
        case image(alt: String, source: String)
        case paragraph(String)
    }

    private func parseBlocks(_ markdown: String) -> [Block] {
        let lines = markdown.components(separatedBy: "\n")
        var blocks: [Block] = []
        var i = 0
        var inFencedCode = false
        var codeBuffer: [String] = []
        var codeLanguage = ""

        while i < lines.count {
            let line = lines[i]

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

            // Table: detect header | separator | rows
            if isTableRow(line),
               i + 1 < lines.count,
               isTableSeparator(lines[i + 1]) {
                let headers = parseTableCells(line)
                i += 2 // skip header + separator
                var rows: [[String]] = []
                while i < lines.count, isTableRow(lines[i]) {
                    rows.append(parseTableCells(lines[i]))
                    i += 1
                }
                blocks.append(.table(headers: headers, rows: rows))
                continue
            }

            if let (alt, src) = parseImage(line) {
                blocks.append(.image(alt: alt, source: src))
            } else if let (level, text) = parseHeading(line) {
                blocks.append(.heading(text, level))
            } else if line.hasPrefix("> ") {
                blocks.append(.blockquote(String(line.dropFirst(2))))
            } else if isHorizontalRule(line) {
                blocks.append(.horizontalRule)
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") {
                blocks.append(.listItem(String(line.dropFirst(2)), ordered: false, number: 0))
            } else if let (num, rest) = parseOrderedListItem(line) {
                blocks.append(.listItem(rest, ordered: true, number: num))
            } else {
                blocks.append(.paragraph(line))
            }

            i += 1
        }

        return blocks
    }

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

    private func headingSlug(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
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

    private func parseOrderedListItem(_ line: String) -> (Int, String)? {
        guard let dot = line.firstIndex(of: ".") else { return nil }
        let numStr = String(line[line.startIndex..<dot])
        guard let num = Int(numStr) else { return nil }
        let afterDot = line.index(after: dot)
        guard afterDot < line.endIndex, line[afterDot] == " " else { return nil }
        return (num, String(line[line.index(after: afterDot)...]))
    }
}
