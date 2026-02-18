import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - UTType extension

extension UTType {
    /// Markdown plain-text document type.
    static let markdown = UTType(
        exportedAs: "net.daringfireball.markdown",
        conformingTo: .plainText
    )
}

// MARK: - MarkdownDocument

/// A SwiftUI `FileDocument` that stores a single Markdown text file.
///
/// This is the source of truth for document content. The `DocumentGroup` scene
/// manages the document lifecycle (open, save, close, undo).
struct MarkdownDocument: FileDocument {

    // MARK: Supported content types

    static var readableContentTypes: [UTType] {
        [.markdown, .plainText]
    }

    static var writableContentTypes: [UTType] {
        [.markdown, .plainText]
    }

    // MARK: Properties

    /// The raw Markdown text content.
    var text: String

    // MARK: Initialization

    init(text: String = Self.defaultContent) {
        self.text = text
    }

    // MARK: FileDocument conformance

    init(configuration: ReadConfiguration) throws {
        guard
            let data = configuration.file.regularFileContents,
            let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.text = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = text.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        return FileWrapper(regularFileWithContents: data)
    }

    // MARK: Default content

    static let defaultContent = """
    # Welcome to Typemark

    Start writing your Markdown here. The preview updates automatically.

    ## Features

    - **Bold** and *italic* text
    - `Inline code` and fenced code blocks
    - [Links](https://example.com) and images
    - Blockquotes and lists
    - Headings H1–H6

    ## Code Example

    ```swift
    let greeting = "Hello, Markdown!"
    print(greeting)
    ```

    ## Blockquote

    > Great things are built one line at a time.

    ---

    Happy writing!
    """
}
