import XCTest
@testable import TypemarkCore

final class EditorViewModelTests: XCTestCase {

    // MARK: - Statistics

    @MainActor
    func testWordCount() {
        let vm = EditorViewModel()
        vm.markdownText = "Hello world foo bar"
        XCTAssertEqual(vm.wordCount, 4)
    }

    @MainActor
    func testWordCountIgnoresExtraWhitespace() {
        let vm = EditorViewModel()
        vm.markdownText = "  Hello   world  \n\n  foo  "
        XCTAssertEqual(vm.wordCount, 3)
    }

    @MainActor
    func testWordCountEmpty() {
        let vm = EditorViewModel()
        vm.markdownText = ""
        XCTAssertEqual(vm.wordCount, 0)
    }

    @MainActor
    func testCharacterCount() {
        let vm = EditorViewModel()
        vm.markdownText = "Hello"
        XCTAssertEqual(vm.characterCount, 5)
    }

    @MainActor
    func testReadingTimeMinimum() {
        let vm = EditorViewModel()
        vm.markdownText = "Short"
        XCTAssertEqual(vm.readingTime, "1 min read")
    }

    @MainActor
    func testReadingTimeScaling() {
        let vm = EditorViewModel()
        vm.markdownText = Array(repeating: "word", count: 476).joined(separator: " ")
        XCTAssertEqual(vm.readingTime, "2 min read")
    }

    // MARK: - Outline headings

    @MainActor
    func testHeadingsOutline() {
        let vm = EditorViewModel()
        vm.markdownText = "# Title\n## Section\n### Sub"
        let headings = vm.headings
        XCTAssertEqual(headings.count, 3)
        XCTAssertEqual(headings[0].level, 1)
        XCTAssertEqual(headings[0].text, "Title")
        XCTAssertEqual(headings[0].slug, "title")
        XCTAssertEqual(headings[1].level, 2)
        XCTAssertEqual(headings[2].level, 3)
    }

    @MainActor
    func testNoHeadingsInPlainText() {
        let vm = EditorViewModel()
        vm.markdownText = "Just plain text"
        XCTAssertTrue(vm.headings.isEmpty)
    }

    // MARK: - Formatting actions

    @MainActor
    func testApplyInlineFormat() {
        let vm = EditorViewModel()
        vm.markdownText = "Hello "
        vm.applyInlineFormat(prefix: "**", suffix: "**", placeholder: "bold")
        XCTAssertEqual(vm.markdownText, "Hello **bold**")
    }

    @MainActor
    func testApplyHeading() {
        let vm = EditorViewModel()
        vm.markdownText = "Intro"
        vm.applyHeading(level: 2)
        XCTAssertEqual(vm.markdownText, "Intro\n## ")
    }

    @MainActor
    func testInsertLink() {
        let vm = EditorViewModel()
        vm.markdownText = ""
        vm.insertLink()
        XCTAssertEqual(vm.markdownText, "[link text](url)")
    }

    @MainActor
    func testInsertCodeBlock() {
        let vm = EditorViewModel()
        vm.markdownText = ""
        vm.insertCodeBlock()
        XCTAssertTrue(vm.markdownText.contains("```"))
    }

    @MainActor
    func testInsertBlockquote() {
        let vm = EditorViewModel()
        vm.markdownText = ""
        vm.insertBlockquote()
        XCTAssertTrue(vm.markdownText.contains("> "))
    }

    @MainActor
    func testInsertStrikethrough() {
        let vm = EditorViewModel()
        vm.markdownText = ""
        vm.insertStrikethrough()
        XCTAssertEqual(vm.markdownText, "~~text~~")
    }

    @MainActor
    func testInsertHighlight() {
        let vm = EditorViewModel()
        vm.markdownText = ""
        vm.insertHighlight()
        XCTAssertEqual(vm.markdownText, "==highlighted==")
    }

    @MainActor
    func testInsertTaskList() {
        let vm = EditorViewModel()
        vm.markdownText = ""
        vm.insertTaskList()
        XCTAssertTrue(vm.markdownText.contains("- [ ] "))
    }

    @MainActor
    func testInsertTable() {
        let vm = EditorViewModel()
        vm.markdownText = ""
        vm.insertTable()
        XCTAssertTrue(vm.markdownText.contains("| Column 1 | Column 2 |"))
        XCTAssertTrue(vm.markdownText.contains("|----------|----------|"))
    }

    @MainActor
    func testInsertHorizontalRule() {
        let vm = EditorViewModel()
        vm.markdownText = ""
        vm.insertHorizontalRule()
        XCTAssertTrue(vm.markdownText.contains("---"))
    }

    @MainActor
    func testInsertImage() {
        let vm = EditorViewModel()
        vm.markdownText = ""
        vm.insertImage()
        XCTAssertEqual(vm.markdownText, "![alt text](image.png)")
    }

    // MARK: - Checkbox toggle

    @MainActor
    func testToggleCheckboxOn() {
        let vm = EditorViewModel()
        vm.markdownText = "- [ ] Task one\n- [ ] Task two"
        vm.toggleCheckbox(at: "Task one")
        XCTAssertTrue(vm.markdownText.contains("- [x] Task one"))
        XCTAssertTrue(vm.markdownText.contains("- [ ] Task two"))
    }

    @MainActor
    func testToggleCheckboxOff() {
        let vm = EditorViewModel()
        vm.markdownText = "- [x] Done task"
        vm.toggleCheckbox(at: "Done task")
        XCTAssertTrue(vm.markdownText.contains("- [ ] Done task"))
    }

    @MainActor
    func testToggleCheckboxMissing() {
        let vm = EditorViewModel()
        vm.markdownText = "- [ ] Real task"
        vm.toggleCheckbox(at: "Fake task")
        XCTAssertEqual(vm.markdownText, "- [ ] Real task")
    }

    // MARK: - Export

    @MainActor
    func testExportHTML() {
        let vm = EditorViewModel()
        vm.markdownText = "# Test"
        let html = vm.exportHTML()
        XCTAssertTrue(html.contains("<h1>Test</h1>"))
        XCTAssertTrue(html.contains("<!DOCTYPE html>"))
    }

    // MARK: - Default state

    @MainActor
    func testDefaultState() {
        let vm = EditorViewModel()
        XCTAssertEqual(vm.markdownText, "")
        XCTAssertTrue(vm.showPreview)
        XCTAssertFalse(vm.showOutline)
        XCTAssertFalse(vm.focusMode)
        XCTAssertNil(vm.documentURL)
        XCTAssertEqual(vm.selectedPane, .editor)
    }
}
