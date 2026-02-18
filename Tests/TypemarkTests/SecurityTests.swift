import XCTest
@testable import TypemarkCore

final class SecurityTests: XCTestCase {

    // MARK: - Image path traversal (CRIT-1)

    func testParseImageAcceptsRelativePaths() {
        let result = MarkdownParser.parseImage("![img](images/photo.png)")
        XCTAssertEqual(result?.0, "img")
        XCTAssertEqual(result?.1, "images/photo.png")
    }

    func testParseImageExtractsPathTraversal() {
        let result = MarkdownParser.parseImage("![img](../../etc/passwd)")
        XCTAssertEqual(result?.1, "../../etc/passwd")
        // Security: loadImage in view layer blocks ".." in paths
    }

    // MARK: - URL scheme safety (HIGH-1)

    func testBlockJavascriptURL() {
        let html = HTMLExporter.export("[xss](javascript:alert(document.cookie))")
        XCTAssertFalse(html.contains("javascript:"))
    }

    func testBlockJavascriptURLMixedCase() {
        let html = HTMLExporter.export("[xss](JavaScript:alert(1))")
        XCTAssertFalse(html.contains("JavaScript:"))
    }

    func testBlockDataURI() {
        let html = HTMLExporter.export("![x](data:image/svg+xml,<svg onload=alert(1)>)")
        XCTAssertFalse(html.contains("data:image"))
    }

    func testAllowHttps() {
        let html = HTMLExporter.export("[safe](https://example.com)")
        XCTAssertTrue(html.contains("href=\"https://example.com\""))
    }

    func testAllowHttp() {
        let html = HTMLExporter.export("[link](http://example.com)")
        XCTAssertTrue(html.contains("href=\"http://example.com\""))
    }

    func testAllowRelativeURL() {
        let html = HTMLExporter.export("[doc](./readme.md)")
        XCTAssertTrue(html.contains("href=\"./readme.md\""))
    }

    func testAllowAnchorURL() {
        let html = HTMLExporter.export("[section](#heading)")
        XCTAssertTrue(html.contains("href=\"#heading\""))
    }

    // MARK: - HTML injection prevention (CRIT-2)

    func testScriptInParagraph() {
        let html = HTMLExporter.export("<script>document.location='http://evil.com'</script>")
        XCTAssertFalse(html.contains("<script>"))
    }

    func testEventHandlerEscaped() {
        let html = HTMLExporter.export("<img src=x onerror=alert(1)>")
        // The < and > are escaped, so the tag can't execute
        XCTAssertFalse(html.contains("<img src"))
        XCTAssertTrue(html.contains("&lt;img"))
    }

    func testHTMLInListItems() {
        let html = HTMLExporter.export("- <iframe src='evil.com'></iframe>")
        XCTAssertFalse(html.contains("<iframe"))
    }

    func testHTMLInBlockquotes() {
        let html = HTMLExporter.export("> <form action='evil'>")
        XCTAssertFalse(html.contains("<form"))
    }

    func testHTMLInTaskItems() {
        let html = HTMLExporter.export("- [x] <script>bad</script>")
        XCTAssertFalse(html.contains("<script>"))
    }

    // MARK: - Code language injection (CRIT-3)

    func testCodeLangSpecialChars() {
        let md = "```a]b\"><script>alert(1)</script>\ncode\n```"
        let html = HTMLExporter.export(md)
        XCTAssertFalse(html.contains("<script>"))
    }

    // MARK: - HTML escaping

    func testSingleQuoteEscaped() {
        let escaped = "it's a test".htmlEscaped
        XCTAssertEqual(escaped, "it&#39;s a test")
    }

    func testAmpersandEscapedFirst() {
        let escaped = "&lt;".htmlEscaped
        XCTAssertEqual(escaped, "&amp;lt;")
    }

    func testAllDangerousCharsEscaped() {
        let input = "<>&\"'"
        let escaped = input.htmlEscaped
        XCTAssertFalse(escaped.contains("<"))
        XCTAssertFalse(escaped.contains(">"))
        XCTAssertTrue(escaped.contains("&lt;"))
        XCTAssertTrue(escaped.contains("&gt;"))
        XCTAssertTrue(escaped.contains("&quot;"))
        XCTAssertTrue(escaped.contains("&#39;"))
    }
}
