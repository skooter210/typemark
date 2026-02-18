# Typemark

A native macOS and iPadOS Markdown editor and live preview app built with SwiftUI and Swift 6.

**Bundle ID:** `com.typemark.app`

## Features

- Split-pane interface: write Markdown on the left, see the rendered preview on the right
- Live preview using Apple's native `AttributedString(markdown:)` API
- Syntax highlighting in the editor pane
- Document-based app: open, save, and manage multiple `.md` files via native file dialogs
- Formatting toolbar with common actions (bold, italic, heading, link, code block)
- Keyboard shortcuts: Cmd+B (bold), Cmd+I (italic), Cmd+K (link), Cmd+` (code)
- Dark mode support (follows system appearance)
- Adaptive layout for macOS (resizable split view) and iPadOS (navigation split view)

## Supported Markdown

- Headings (H1–H6)
- Bold and italic text
- Inline code and fenced code blocks
- Unordered and ordered lists
- Blockquotes
- Links and images
- Horizontal rules
- Strikethrough

## Requirements

- macOS 26 or later
- iPadOS 26 or later
- Xcode 16+ (for building)
- Swift 6.0+

## Building

This project uses Swift Package Manager. No Xcode project file is required.

```bash
# Build
swift build

# Run (macOS)
swift run

# Open in Xcode
open Package.swift
```

## Project Structure

```
typemark/
├── Package.swift                     # SPM manifest
├── Sources/
│   └── Typemark/
│       ├── App/                      # Entry point and app configuration
│       │   └── TypemarkApp.swift
│       ├── Views/                    # SwiftUI views
│       │   ├── ContentView.swift
│       │   ├── EditorPaneView.swift
│       │   ├── PreviewPaneView.swift
│       │   └── ToolbarView.swift
│       ├── Models/                   # Data models
│       │   ├── MarkdownDocument.swift
│       │   └── EditorViewModel.swift
│       └── Utilities/                # Helpers
│           ├── SyntaxHighlighter.swift
│           └── MarkdownFormatter.swift
├── CLAUDE.md                         # Developer guide
└── README.md
```

## Architecture

The app follows a document-based architecture using SwiftUI's `DocumentGroup` scene:

- `MarkdownDocument` conforms to `FileDocument` and holds the markdown text as the source of truth
- `EditorViewModel` (using `@Observable`) bridges the document model to the views
- `ContentView` renders an adaptive split layout depending on platform
- The preview pane uses `AttributedString(markdown:)` for zero-dependency Markdown rendering

## License

MIT
