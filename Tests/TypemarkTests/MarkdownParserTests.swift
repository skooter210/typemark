import XCTest
@testable import TypemarkCore

final class MarkdownParserBlockTests: XCTestCase {

    // MARK: - Headings

    func testParsesH1ThroughH6() {
        for level in 1...6 {
            let prefix = String(repeating: "#", count: level)
            let blocks = MarkdownParser.parseBlocks("\(prefix) Title \(level)")
            XCTAssertEqual(blocks, [.heading("Title \(level)", level)])
        }
    }

    func testSevenHashesIsNotHeading() {
        let blocks = MarkdownParser.parseBlocks("####### Not a heading")
        XCTAssertEqual(blocks, [.paragraph("####### Not a heading")])
    }

    func testHeadingWithoutSpaceIsParagraph() {
        let blocks = MarkdownParser.parseBlocks("##NoSpace")
        XCTAssertEqual(blocks, [.paragraph("##NoSpace")])
    }

    // MARK: - Code blocks

    func testCodeBlockWithLanguage() {
        let md = "```swift\nlet x = 1\n```"
        let blocks = MarkdownParser.parseBlocks(md)
        XCTAssertEqual(blocks, [.codeBlock("let x = 1", "swift")])
    }

    func testCodeBlockWithoutLanguage() {
        let md = "```\nhello\nworld\n```"
        let blocks = MarkdownParser.parseBlocks(md)
        XCTAssertEqual(blocks, [.codeBlock("hello\nworld", "")])
    }

    func testUnclosedCodeFence() {
        let md = "```python\nprint('hi')"
        let blocks = MarkdownParser.parseBlocks(md)
        XCTAssertEqual(blocks, [.codeBlock("print('hi')", "python")])
    }

    func testCodeBlockCapsAt10000Lines() {
        var lines = ["```"]
        for i in 0..<10_500 {
            lines.append("line \(i)")
        }
        lines.append("```")
        let blocks = MarkdownParser.parseBlocks(lines.joined(separator: "\n"))
        if case .codeBlock(let code, _) = blocks.first {
            let lineCount = code.components(separatedBy: "\n").count
            XCTAssertEqual(lineCount, 10_000)
        } else {
            XCTFail("Expected code block")
        }
    }

    // MARK: - Horizontal rules

    func testHorizontalRulesAllMarkers() {
        for marker in ["---", "***", "___", "-----"] {
            let blocks = MarkdownParser.parseBlocks(marker)
            XCTAssertEqual(blocks, [.horizontalRule], "Failed for: \(marker)")
        }
    }

    func testTwoDashesNotHR() {
        let blocks = MarkdownParser.parseBlocks("--")
        XCTAssertEqual(blocks, [.paragraph("--")])
    }

    // MARK: - Blockquotes

    func testSingleBlockquote() {
        let blocks = MarkdownParser.parseBlocks("> Hello world")
        XCTAssertEqual(blocks, [.blockquote(["Hello world"])])
    }

    func testMultiLineBlockquote() {
        let md = "> Line 1\n> Line 2\n> Line 3"
        let blocks = MarkdownParser.parseBlocks(md)
        XCTAssertEqual(blocks, [.blockquote(["Line 1", "Line 2", "Line 3"])])
    }

    func testBlockquoteNoSpace() {
        let blocks = MarkdownParser.parseBlocks(">tight")
        XCTAssertEqual(blocks, [.blockquote(["tight"])])
    }

    // MARK: - Callouts

    func testAllCalloutTypes() {
        let types: [(String, CalloutKind)] = [
            ("NOTE", .note), ("TIP", .tip), ("IMPORTANT", .important),
            ("WARNING", .warning), ("CAUTION", .caution),
        ]
        for (tag, kind) in types {
            let md = "> [!\(tag)]\n> Some content"
            let blocks = MarkdownParser.parseBlocks(md)
            XCTAssertEqual(blocks, [.callout(kind, ["Some content"])], "Failed for: \(tag)")
        }
    }

    func testCaseInsensitiveCallout() {
        let md = "> [!Note]\n> Details"
        let blocks = MarkdownParser.parseBlocks(md)
        XCTAssertEqual(blocks, [.callout(.note, ["Details"])])
    }

    func testUnknownCalloutFallsBackToBlockquote() {
        let md = "> [!UNKNOWN]\n> Content"
        let blocks = MarkdownParser.parseBlocks(md)
        XCTAssertEqual(blocks, [.blockquote(["[!UNKNOWN]", "Content"])])
    }

    // MARK: - Lists

    func testUnorderedListMarkers() {
        for marker in ["- ", "* ", "+ "] {
            let blocks = MarkdownParser.parseBlocks("\(marker)Item")
            XCTAssertEqual(blocks, [.listItem("Item", ordered: false, number: 0, indent: 0)],
                           "Failed for marker: \(marker)")
        }
    }

    func testIndentedListItems() {
        let blocks = MarkdownParser.parseBlocks("    - Nested")
        if case .listItem(let text, _, _, let indent) = blocks.first {
            XCTAssertEqual(text, "Nested")
            XCTAssertEqual(indent, 2)
        } else {
            XCTFail("Expected list item")
        }
    }

    func testOrderedListItems() {
        let blocks = MarkdownParser.parseBlocks("1. First\n2. Second")
        XCTAssertEqual(blocks, [
            .listItem("First", ordered: true, number: 1, indent: 0),
            .listItem("Second", ordered: true, number: 2, indent: 0),
        ])
    }

    // MARK: - Task items

    func testTaskItems() {
        let md = "- [ ] Todo\n- [x] Done\n- [X] Also done"
        let blocks = MarkdownParser.parseBlocks(md)
        XCTAssertEqual(blocks, [
            .taskItem("Todo", checked: false),
            .taskItem("Done", checked: true),
            .taskItem("Also done", checked: true),
        ])
    }

    // MARK: - Tables

    func testBasicTable() {
        let md = "| A | B |\n|---|---|\n| 1 | 2 |"
        let blocks = MarkdownParser.parseBlocks(md)
        XCTAssertEqual(blocks, [.table(headers: ["A", "B"], rows: [["1", "2"]])])
    }

    func testMultiRowTable() {
        let md = "| H1 | H2 |\n|---|---|\n| a | b |\n| c | d |"
        let blocks = MarkdownParser.parseBlocks(md)
        XCTAssertEqual(blocks, [.table(headers: ["H1", "H2"], rows: [["a", "b"], ["c", "d"]])])
    }

    func testNonTablePipeIsParagraph() {
        let blocks = MarkdownParser.parseBlocks("| only one line |")
        XCTAssertEqual(blocks, [.paragraph("| only one line |")])
    }

    // MARK: - Images

    func testImageBlock() {
        let blocks = MarkdownParser.parseBlocks("![Alt text](image.png)")
        XCTAssertEqual(blocks, [.image(alt: "Alt text", source: "image.png")])
    }

    func testImageEmptyAlt() {
        let blocks = MarkdownParser.parseBlocks("![](photo.jpg)")
        XCTAssertEqual(blocks, [.image(alt: "", source: "photo.jpg")])
    }

    // MARK: - Footnotes

    func testFootnoteDefinitionProducesRef() {
        let blocks = MarkdownParser.parseBlocks("[^1]: Footnote text")
        XCTAssertEqual(blocks, [.footnoteRef(id: "", text: "")])
    }

    func testCollectsFootnoteDefinitions() {
        let md = "Some text\n[^1]: First note\n[^2]: Second note"
        let defs = MarkdownParser.collectFootnoteDefinitions(md)
        XCTAssertEqual(defs.count, 2)
        XCTAssertEqual(defs[0].id, "1")
        XCTAssertEqual(defs[0].text, "First note")
        XCTAssertEqual(defs[1].id, "2")
        XCTAssertEqual(defs[1].text, "Second note")
    }

    // MARK: - Paragraphs

    func testPlainParagraph() {
        let blocks = MarkdownParser.parseBlocks("Hello world")
        XCTAssertEqual(blocks, [.paragraph("Hello world")])
    }

    func testEmptyLine() {
        let blocks = MarkdownParser.parseBlocks("")
        XCTAssertEqual(blocks, [.paragraph("")])
    }

    // MARK: - Mixed content

    func testMixedContent() {
        let md = "# Title\n\nSome text\n\n- Item 1\n- Item 2\n\n```\ncode\n```\n\n---"
        let blocks = MarkdownParser.parseBlocks(md)
        XCTAssertEqual(blocks[0], .heading("Title", 1))
        XCTAssertEqual(blocks[2], .paragraph("Some text"))
        XCTAssertEqual(blocks[4], .listItem("Item 1", ordered: false, number: 0, indent: 0))
        XCTAssertEqual(blocks[5], .listItem("Item 2", ordered: false, number: 0, indent: 0))
        XCTAssertTrue(blocks.contains(.horizontalRule))
    }
}

final class MarkdownParserLineTests: XCTestCase {

    func testHeadingSlug() {
        XCTAssertEqual(MarkdownParser.headingSlug("Hello World"), "hello-world")
        XCTAssertEqual(MarkdownParser.headingSlug("My (Great) Title!"), "my-great-title")
        XCTAssertEqual(MarkdownParser.headingSlug("under_score"), "under_score")
    }

    func testTableRowDetection() {
        XCTAssertTrue(MarkdownParser.isTableRow("| a | b |"))
        XCTAssertTrue(MarkdownParser.isTableRow("|x|"))
        XCTAssertFalse(MarkdownParser.isTableRow("| only left"))
        XCTAssertFalse(MarkdownParser.isTableRow("no pipes"))
        XCTAssertFalse(MarkdownParser.isTableRow("|"))
    }

    func testTableSeparator() {
        XCTAssertTrue(MarkdownParser.isTableSeparator("|---|---|"))
        XCTAssertTrue(MarkdownParser.isTableSeparator("| --- | --- |"))
        XCTAssertTrue(MarkdownParser.isTableSeparator("|:---:|:---|"))
        XCTAssertFalse(MarkdownParser.isTableSeparator("| abc | def |"))
    }

    func testTableCells() {
        XCTAssertEqual(MarkdownParser.parseTableCells("| Hello | World |"), ["Hello", "World"])
        XCTAssertEqual(MarkdownParser.parseTableCells("|a|b|c|"), ["a", "b", "c"])
    }

    func testParseImage() {
        let result = MarkdownParser.parseImage("![logo](assets/logo.png)")
        XCTAssertEqual(result?.0, "logo")
        XCTAssertEqual(result?.1, "assets/logo.png")
        XCTAssertNil(MarkdownParser.parseImage("Not an image"))
        XCTAssertNil(MarkdownParser.parseImage("![incomplete]("))
    }

    func testHorizontalRuleEdgeCases() {
        XCTAssertTrue(MarkdownParser.isHorizontalRule("  ---  "))
        XCTAssertFalse(MarkdownParser.isHorizontalRule("--"))
        XCTAssertFalse(MarkdownParser.isHorizontalRule("-*-"))
    }

    func testStripBlockquotePrefix() {
        XCTAssertEqual(MarkdownParser.stripBlockquotePrefix("> text"), "text")
        XCTAssertEqual(MarkdownParser.stripBlockquotePrefix(">text"), "text")
        XCTAssertEqual(MarkdownParser.stripBlockquotePrefix("no quote"), "no quote")
    }

    func testFootnoteDetection() {
        XCTAssertTrue(MarkdownParser.isFootnoteDefinition("[^1]: Note"))
        XCTAssertTrue(MarkdownParser.isFootnoteDefinition("[^abc]: Note"))
        XCTAssertFalse(MarkdownParser.isFootnoteDefinition("[^]: No id"))
        XCTAssertFalse(MarkdownParser.isFootnoteDefinition("Not a footnote"))
    }

    func testCalloutFromCase() {
        XCTAssertEqual(CalloutKind.from("note"), .note)
        XCTAssertEqual(CalloutKind.from("NOTE"), .note)
        XCTAssertEqual(CalloutKind.from("Note"), .note)
        XCTAssertNil(CalloutKind.from("invalid"))
    }
}
