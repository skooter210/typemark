# MEMORY.md — MarkdownEditor Project State

## Current State
COMPLETE. All source files written, build verified clean (zero errors, zero warnings).

## Architecture Overview

```
DocumentGroup (App Scene)  [MarkdownEditorApp.swift]
    └── ContentView (adaptive split layout)
            ├── macOS: HSplitView
            │     ├── EditorPaneView  (ZStack: TextEditor + syntax-highlighted overlay)
            │     └── PreviewPaneView (ScrollView + block-by-block AttributedString)
            └── iPad: NavigationSplitView or segmented Picker
                  ├── EditorPaneView
                  └── PreviewPaneView

MarkdownDocument (FileDocument)  — source of truth for file content
EditorViewModel (@Observable, @MainActor) — bridges document ↔ views
SyntaxHighlighter (enum) — stateless, NSRegularExpression-based
MarkdownFormatter (enum) — pure string transformation functions
MarkdownToolbarContent (ToolbarContent) — formatting toolbar
```

## Tech Stack

- Swift 6.2.3, SwiftUI (macOS 26+, iPadOS 26+)
- swift-tools-version: 6.2 (required for .macOS(.v26) / .iOS(.v26))
- SPM executable target, no .xcodeproj
- AttributedString(markdown:) for inline preview parsing
- @Observable macro for state management

## File Registry

| File | Description |
|---|---|
| `Package.swift` | SPM manifest; swift-tools-version 6.2; MarkdownEditor executable; excludes README.mds |
| `.gitignore` | Swift/Xcode/macOS standard ignores |
| `CLAUDE.md` | Build commands, coding standards, architecture, decision log |
| `MEMORY.md` | This file |
| `README.md` | User-facing project documentation |
| `Sources/MarkdownEditor/App/MarkdownEditorApp.swift` | @main, DocumentGroup scene, menu commands |
| `Sources/MarkdownEditor/Models/MarkdownDocument.swift` | FileDocument; UTType.markdown; read/write UTF-8 |
| `Sources/MarkdownEditor/Models/EditorViewModel.swift` | @Observable @MainActor; formatting actions |
| `Sources/MarkdownEditor/Views/ContentView.swift` | Adaptive split layout; syncs document ↔ viewModel |
| `Sources/MarkdownEditor/Views/EditorPaneView.swift` | ZStack TextEditor + attributed overlay for highlighting |
| `Sources/MarkdownEditor/Views/PreviewPaneView.swift` | Block-by-block Markdown renderer using AttributedString |
| `Sources/MarkdownEditor/Views/ToolbarView.swift` | MarkdownToolbarContent + keyboard shortcuts |
| `Sources/MarkdownEditor/Utilities/SyntaxHighlighter.swift` | NSRegularExpression patterns → AttributedString colors |
| `Sources/MarkdownEditor/Utilities/MarkdownFormatter.swift` | Pure string helpers for bold/italic/link/etc. |
| `Sources/MarkdownEditor/App/README.md` | App group description (excluded from SPM target) |
| `Sources/MarkdownEditor/Views/README.md` | Views group description (excluded from SPM target) |
| `Sources/MarkdownEditor/Models/README.md` | Models group description (excluded from SPM target) |
| `Sources/MarkdownEditor/Utilities/README.md` | Utilities group description (excluded from SPM target) |

## Decision Log

| Decision | Choice | Rationale |
|---|---|---|
| swift-tools-version | 6.2 | Required for .macOS(.v26) / .iOS(.v26) platform specifiers |
| README.md in source dirs | excluded via Package.swift | SPM warns about unhandled non-Swift files; exclude to keep build clean |
| SyntaxHighlighter Range conversion | explicit NSRange→String.Index→AttributedString.Index | Avoids ambiguous init conflict between custom extensions and Foundation |
| navigationBarTitleDisplayMode | wrapped in #if !os(macOS) | API is iOS-only; macOS build fails without platform guard |
| Preview rendering | block-by-block custom parser + AttributedString(markdown:) for inline | AttributedString(markdown:) handles inline well; headings/code blocks need manual rendering |
| TextEditor highlighting | ZStack overlay | SwiftUI TextEditor doesn't expose attributed text; overlay provides visual highlighting |

## Known Issues / Limitations

- Syntax highlighting overlay and TextEditor cursor can visually misalign for very long lines (monospace font mitigates this)
- AttributedString(markdown:) interpretedSyntax .inlineOnly doesn't render block elements; handled by custom block parser
- `swift run` launches but SwiftUI apps require display/WindowServer; best run via Xcode or swift run on macOS with display

## Next Tasks Queue

1. Add unit test target for MarkdownFormatter and SyntaxHighlighter
2. Add iCloud document sync (NSUbiquitousItemIsUploadedKey)
3. Add export to HTML action
4. Add word/character count in status bar
5. Add find & replace panel
