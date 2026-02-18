import Foundation

enum HTMLExporter {

    static func export(_ markdown: String) -> String {
        let bodyHTML = convertToHTML(markdown)
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Typemark Export</title>
        <style>
        \(css)
        </style>
        </head>
        <body>
        <article>
        \(bodyHTML)
        </article>
        </body>
        </html>
        """
    }

    private static func convertToHTML(_ markdown: String) -> String {
        let lines = markdown.components(separatedBy: "\n")
        var html: [String] = []
        var i = 0
        var inCode = false
        var codeBuffer: [String] = []
        var codeLang = ""

        while i < lines.count {
            let line = lines[i]

            if line.hasPrefix("```") {
                if inCode {
                    let escaped = codeBuffer.joined(separator: "\n").htmlEscaped
                    html.append("<pre><code class=\"language-\(codeLang)\">\(escaped)</code></pre>")
                    inCode = false
                    codeBuffer = []
                    codeLang = ""
                } else {
                    inCode = true
                    codeLang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                }
                i += 1
                continue
            }

            if inCode {
                codeBuffer.append(line)
                i += 1
                continue
            }

            // Headings
            var matched = false
            for level in (1...6).reversed() {
                let prefix = String(repeating: "#", count: level) + " "
                if line.hasPrefix(prefix) {
                    let text = String(line.dropFirst(prefix.count)).htmlEscaped
                    html.append("<h\(level)>\(inlineHTML(text))</h\(level)>")
                    matched = true
                    break
                }
            }
            if matched { i += 1; continue }

            // HR
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.count >= 3 && (trimmed.allSatisfy { $0 == "-" } || trimmed.allSatisfy { $0 == "*" } || trimmed.allSatisfy { $0 == "_" }) {
                html.append("<hr>")
                i += 1
                continue
            }

            // Task items
            if trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("- [X] ") {
                html.append("<p><input type=\"checkbox\" checked disabled> \(inlineHTML(String(trimmed.dropFirst(6))))</p>")
                i += 1; continue
            }
            if trimmed.hasPrefix("- [ ] ") {
                html.append("<p><input type=\"checkbox\" disabled> \(inlineHTML(String(trimmed.dropFirst(6))))</p>")
                i += 1; continue
            }

            // Blockquote
            if line.hasPrefix(">") {
                let content = line.hasPrefix("> ") ? String(line.dropFirst(2)) : String(line.dropFirst(1))
                html.append("<blockquote><p>\(inlineHTML(content))</p></blockquote>")
                i += 1; continue
            }

            // List items
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
                html.append("<li>\(inlineHTML(String(trimmed.dropFirst(2))))</li>")
                i += 1; continue
            }

            // Empty line
            if trimmed.isEmpty {
                html.append("")
                i += 1; continue
            }

            // Paragraph
            html.append("<p>\(inlineHTML(line))</p>")
            i += 1
        }

        if inCode {
            let escaped = codeBuffer.joined(separator: "\n").htmlEscaped
            html.append("<pre><code class=\"language-\(codeLang)\">\(escaped)</code></pre>")
        }

        return html.joined(separator: "\n")
    }

    private static func inlineHTML(_ text: String) -> String {
        var result = text
        // Bold
        result = result.replacingOccurrences(
            of: #"\*\*(.+?)\*\*"#, with: "<strong>$1</strong>",
            options: .regularExpression)
        // Italic
        result = result.replacingOccurrences(
            of: #"\*(.+?)\*"#, with: "<em>$1</em>",
            options: .regularExpression)
        // Strikethrough
        result = result.replacingOccurrences(
            of: #"~~(.+?)~~"#, with: "<del>$1</del>",
            options: .regularExpression)
        // Highlight
        result = result.replacingOccurrences(
            of: #"==(.+?)=="#, with: "<mark>$1</mark>",
            options: .regularExpression)
        // Inline code
        result = result.replacingOccurrences(
            of: #"`([^`]+)`"#, with: "<code>$1</code>",
            options: .regularExpression)
        // Links
        result = result.replacingOccurrences(
            of: #"\[([^\]]+)\]\(([^)]+)\)"#, with: "<a href=\"$2\">$1</a>",
            options: .regularExpression)
        // Images
        result = result.replacingOccurrences(
            of: #"!\[([^\]]*)\]\(([^)]+)\)"#, with: "<img src=\"$2\" alt=\"$1\">",
            options: .regularExpression)
        return result
    }

    private static let css = """
    :root { color-scheme: light dark; }
    body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
        max-width: 800px;
        margin: 40px auto;
        padding: 0 20px;
        line-height: 1.6;
        color: #1d1d1f;
        background: #fff;
    }
    @media (prefers-color-scheme: dark) {
        body { color: #f5f5f7; background: #1d1d1f; }
        pre { background: #2d2d2f; }
        code { background: #2d2d2f; }
        blockquote { border-color: #48484a; }
        hr { border-color: #48484a; }
        table, th, td { border-color: #48484a; }
        mark { background: rgba(255, 230, 0, 0.3); }
    }
    h1, h2, h3, h4, h5, h6 { margin-top: 1.5em; margin-bottom: 0.5em; }
    h1 { font-size: 2em; }
    h2 { font-size: 1.5em; }
    h3 { font-size: 1.25em; }
    pre {
        background: #f5f5f7;
        border-radius: 8px;
        padding: 16px;
        overflow-x: auto;
    }
    code {
        font-family: 'SF Mono', Menlo, monospace;
        font-size: 0.9em;
        background: #f5f5f7;
        padding: 2px 6px;
        border-radius: 4px;
    }
    pre code { background: none; padding: 0; }
    blockquote {
        border-left: 3px solid #d1d1d6;
        margin-left: 0;
        padding-left: 16px;
        color: #636366;
    }
    table { border-collapse: collapse; width: 100%; margin: 1em 0; }
    th, td {
        border: 1px solid #d1d1d6;
        padding: 8px 12px;
        text-align: left;
    }
    th { font-weight: 600; background: #f5f5f7; }
    mark { background: rgba(255, 230, 0, 0.4); padding: 2px 4px; border-radius: 2px; }
    hr { border: none; border-top: 1px solid #d1d1d6; margin: 2em 0; }
    img { max-width: 100%; border-radius: 8px; }
    a { color: #007AFF; }
    del { color: #8e8e93; }
    input[type="checkbox"] { margin-right: 8px; }
    """
}

private extension String {
    var htmlEscaped: String {
        self.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
