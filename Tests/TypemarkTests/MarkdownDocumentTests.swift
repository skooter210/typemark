import XCTest
@testable import TypemarkCore

final class MarkdownDocumentTests: XCTestCase {

    func testDefaultContent() {
        let doc = MarkdownDocument()
        XCTAssertEqual(doc.text, MarkdownDocument.defaultContent)
        XCTAssertFalse(doc.text.isEmpty)
    }

    func testCustomText() {
        let doc = MarkdownDocument(text: "# My Doc")
        XCTAssertEqual(doc.text, "# My Doc")
    }

    func testDefaultContentContainsKeyFeatures() {
        let content = MarkdownDocument.defaultContent
        XCTAssertTrue(content.contains("# Welcome to Typemark"))
        XCTAssertTrue(content.contains("**Bold**"))
        XCTAssertTrue(content.contains("*italic*"))
        XCTAssertTrue(content.contains("~~Strikethrough~~"))
        XCTAssertTrue(content.contains("==highlighted=="))
        XCTAssertTrue(content.contains("```swift"))
        XCTAssertTrue(content.contains("- [x]"))
        XCTAssertTrue(content.contains("- [ ]"))
        XCTAssertTrue(content.contains("> [!NOTE]"))
        XCTAssertTrue(content.contains("[^1]"))
        XCTAssertTrue(content.contains("---"))
    }

    func testTextToDataRoundTrip() {
        let doc = MarkdownDocument(text: "Hello, world! 🌍🚀")
        let data = doc.text.data(using: .utf8)!
        let roundTripped = String(data: data, encoding: .utf8)
        XCTAssertEqual(roundTripped, "Hello, world! 🌍🚀")
    }

    func testTextMutability() {
        var doc = MarkdownDocument(text: "Original")
        doc.text = "Modified"
        XCTAssertEqual(doc.text, "Modified")
    }

    func testEmptyDocument() {
        let doc = MarkdownDocument(text: "")
        XCTAssertEqual(doc.text, "")
    }
}
