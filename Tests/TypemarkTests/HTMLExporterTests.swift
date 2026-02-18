import XCTest
@testable import TypemarkCore

final class HTMLExporterTests: XCTestCase {

    // MARK: - Basic structure

    func testDocumentStructure() {
        let html = HTMLExporter.export("Hello")
        XCTAssertTrue(html.contains("<!DOCTYPE html>"))
        XCTAssertTrue(html.contains("<html lang=\"en\">"))
        XCTAssertTrue(html.contains("<meta charset=\"UTF-8\">"))
        XCTAssertTrue(html.contains("<article>"))
        XCTAssertTrue(html.contains("</html>"))
    }

    func testIncludesCSS() {
        let html = HTMLExporter.export("Hello")
        XCTAssertTrue(html.contains("<style>"))
        XCTAssertTrue(html.contains("font-family"))
    }

    // MARK: - Headings

    func testHeadings() {
        let html = HTMLExporter.export("# Title\n## Subtitle")
        XCTAssertTrue(html.contains("<h1>Title</h1>"))
        XCTAssertTrue(html.contains("<h2>Subtitle</h2>"))
    }

    func testHeadingEscaping() {
        let html = HTMLExporter.export("# Title <script>alert(1)</script>")
        XCTAssertTrue(html.contains("&lt;script&gt;"))
        XCTAssertFalse(html.contains("<script>"))
    }

    // MARK: - Code blocks

    func testCodeBlocks() {
        let md = "```swift\nlet x = 1\n```"
        let html = HTMLExporter.export(md)
        XCTAssertTrue(html.contains("<pre><code class=\"language-swift\">"))
        XCTAssertTrue(html.contains("let x = 1"))
    }

    func testCodeBlockEscaping() {
        let md = "```\n<div>test</div>\n```"
        let html = HTMLExporter.export(md)
        XCTAssertTrue(html.contains("&lt;div&gt;test&lt;/div&gt;"))
        XCTAssertFalse(html.contains("<div>test</div>"))
    }

    func testCodeLanguageSanitization() {
        let md = "```\"><script>alert(1)</script>\nhack\n```"
        let html = HTMLExporter.export(md)
        XCTAssertFalse(html.contains("<script>"))
    }

    func testEmptyLanguageNoClassAttribute() {
        let md = "```\ncode\n```"
        let html = HTMLExporter.export(md)
        XCTAssertTrue(html.contains("<pre><code>"))
        XCTAssertFalse(html.contains("class=\"language-\""))
    }

    // MARK: - Inline formatting

    func testBoldText() {
        let html = HTMLExporter.export("**bold**")
        XCTAssertTrue(html.contains("<strong>bold</strong>"))
    }

    func testItalicText() {
        let html = HTMLExporter.export("*italic*")
        XCTAssertTrue(html.contains("<em>italic</em>"))
    }

    func testStrikethroughText() {
        let html = HTMLExporter.export("~~deleted~~")
        XCTAssertTrue(html.contains("<del>deleted</del>"))
    }

    func testHighlightText() {
        let html = HTMLExporter.export("==highlighted==")
        XCTAssertTrue(html.contains("<mark>highlighted</mark>"))
    }

    func testInlineCode() {
        let html = HTMLExporter.export("`code`")
        XCTAssertTrue(html.contains("<code>code</code>"))
    }

    // MARK: - XSS prevention (CRIT-2)

    func testParagraphXSS() {
        let html = HTMLExporter.export("<script>alert('xss')</script>")
        XCTAssertFalse(html.contains("<script>"))
        XCTAssertTrue(html.contains("&lt;script&gt;"))
    }

    func testBlockquoteXSS() {
        let html = HTMLExporter.export("> <img onerror=alert(1)>")
        XCTAssertFalse(html.contains("<img onerror"))
    }

    func testListItemXSS() {
        let html = HTMLExporter.export("- <script>evil</script>")
        XCTAssertFalse(html.contains("<script>evil</script>"))
    }

    func testTaskItemXSS() {
        let html = HTMLExporter.export("- [x] <b onmouseover=alert(1)>hover</b>")
        XCTAssertFalse(html.contains("<b onmouseover"))
    }

    func testJavascriptURLBlocked() {
        let html = HTMLExporter.export("[click](javascript:alert(1))")
        XCTAssertFalse(html.contains("javascript:"))
        XCTAssertTrue(html.contains("click"))
    }

    func testDataURLBlocked() {
        let html = HTMLExporter.export("![img](data:text/html,<script>)")
        XCTAssertFalse(html.contains("data:text/html"))
    }

    func testVbscriptBlocked() {
        let html = HTMLExporter.export("[click](vbscript:exec)")
        XCTAssertFalse(html.contains("vbscript:"))
    }

    func testSafeHttpsLinksPreserved() {
        let html = HTMLExporter.export("[link](https://example.com)")
        XCTAssertTrue(html.contains("<a href=\"https://example.com\">link</a>"))
    }

    func testRelativeLinksPreserved() {
        let html = HTMLExporter.export("[doc](readme.md)")
        XCTAssertTrue(html.contains("<a href=\"readme.md\">doc</a>"))
    }

    // MARK: - HTML escaping

    func testHtmlEscapedCoversAll() {
        let input = "<div class=\"test\">&'value'"
        let escaped = input.htmlEscaped
        XCTAssertTrue(escaped.contains("&lt;"))
        XCTAssertTrue(escaped.contains("&gt;"))
        XCTAssertTrue(escaped.contains("&amp;"))
        XCTAssertTrue(escaped.contains("&quot;"))
        XCTAssertTrue(escaped.contains("&#39;"))
    }

    // MARK: - Special elements

    func testHorizontalRules() {
        let html = HTMLExporter.export("---")
        XCTAssertTrue(html.contains("<hr>"))
    }

    func testTaskItems() {
        let html = HTMLExporter.export("- [x] Done\n- [ ] Todo")
        XCTAssertTrue(html.contains("checked"))
        XCTAssertTrue(html.contains("type=\"checkbox\""))
    }

    func testBlockquotes() {
        let html = HTMLExporter.export("> Quote")
        XCTAssertTrue(html.contains("<blockquote>"))
    }

    func testListItems() {
        let html = HTMLExporter.export("- Item")
        XCTAssertTrue(html.contains("<li>"))
    }

    func testEmptyLines() {
        let html = HTMLExporter.export("\n\n")
        XCTAssertTrue(html.contains("<article>"))
    }

    func testUnclosedCodeFenceInExport() {
        let md = "```python\nprint('hi')"
        let html = HTMLExporter.export(md)
        XCTAssertTrue(html.contains("<pre><code"))
        XCTAssertTrue(html.contains("print(&#39;hi&#39;)"))
    }
}
