import Foundation
import SwiftUI
import UniformTypeIdentifiers

public extension UTType {
    static let markdown = UTType(
        exportedAs: "net.daringfireball.markdown",
        conformingTo: .plainText
    )
}

public struct MarkdownDocument: FileDocument {

    public static var readableContentTypes: [UTType] {
        [.markdown, .plainText]
    }

    public static var writableContentTypes: [UTType] {
        [.markdown, .plainText]
    }

    public var text: String

    public init(text: String = Self.defaultContent) {
        self.text = text
    }

    public init(configuration: ReadConfiguration) throws {
        guard
            let data = configuration.file.regularFileContents,
            let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.text = string
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = text.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        return FileWrapper(regularFileWithContents: data)
    }

    public static let defaultContent = """
# Welcome to Typemark

Start writing your Markdown here. The preview updates automatically.

## Features

- **Bold** and *italic* text
- ~~Strikethrough~~ and ==highlighted== text
- `Inline code` and fenced code blocks
- [Links](https://example.com) and images
- Blockquotes and lists
- Headings H1–H6
- Tables with column alignment
- Task lists with interactive checkboxes
- Footnotes[^1]
- Superscript^sup^ and subscript~sub~

## Task List

- [x] Create the editor
- [x] Add live preview
- [ ] Write something amazing

## Code Example

```swift
let greeting = "Hello, Markdown!"
print(greeting)
```

## Callouts

> [!NOTE]
> This is a helpful note.

> [!TIP]
> Try toggling focus mode with Cmd+Shift+F.

> Great things are built one line at a time.

---

[^1]: Footnotes appear at the bottom of the preview.

Happy writing!
"""
}
