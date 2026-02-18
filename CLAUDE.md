# CLAUDE.md — Typemark

## Build Commands

```bash
# Build the project
swift build

# Run the app (macOS only via SwiftUI App lifecycle)
swift run

# Clean build artifacts
swift package clean

# Resolve dependencies
swift package resolve

# Open in Xcode (generates Xcode project from Package.swift)
open Package.swift
```

## Tech Stack

| Technology | Version | Purpose |
|---|---|---|
| Swift | 6.2.3 | Primary language |
| SwiftUI | iOS/macOS 26+ | UI framework |
| Swift Package Manager | 6.2 (swift-tools-version) | Build system |
| AttributedString | Built-in | Markdown rendering |
| Observation | Built-in (@Observable) | State management |

## Architecture Pattern

**Document-Based App (MVVM variant)**

- `DocumentGroup` scene manages file lifecycle (open/save/new)
- `MarkdownDocument` implements `FileDocument` — the model layer
- `EditorViewModel` (using `@Observable`) — coordinator between editor and preview
- Views are pure SwiftUI — no UIKit/AppKit dependencies

## Bundle ID

`com.typemark.app`

## Coding Standards

### Naming Conventions
- Types: `UpperCamelCase` — `MarkdownDocument`, `EditorView`
- Properties/methods: `lowerCamelCase` — `markdownText`, `insertBold()`
- Constants: `lowerCamelCase` — `defaultContent`
- Files: Match the primary type they contain — `MarkdownDocument.swift`

### File Organization
```
Sources/Typemark/
├── App/            # @main entry point, App struct, scene configuration
├── Views/          # All SwiftUI views
├── Models/         # Data models (FileDocument, etc.)
└── Utilities/      # Helpers: syntax highlighting, markdown parsing
```

### Import Ordering
1. Swift standard library (if needed)
2. Apple frameworks (SwiftUI, Foundation, UniformTypeIdentifiers)
3. Third-party (none currently)
4. Internal modules (none — single target)

### Error Handling
- File I/O errors: propagate via `throws` to `FileDocument` conformance
- User-facing errors: use SwiftUI's `.alert` modifier with descriptive messages
- Never `fatalError` in production paths; use `throws` or `Result`

### Swift Concurrency
- `@MainActor` on all View-related state
- `Sendable` conformance where required by Swift 6 strict concurrency
- Prefer `async/await` over callbacks for any async operations

### SwiftUI Patterns
- Use `@Observable` macro (not `ObservableObject`) for view models
- `@State` for local view state, `@Bindable` for observable objects
- Avoid `@EnvironmentObject`; prefer explicit dependency injection
- Use `.focusedSceneValue` / `.focusedValue` for menu-action plumbing

## Key Decisions Log

| Decision | Choice | Rationale |
|---|---|---|
| App name | Typemark | Unique, not taken on App Store |
| Bundle ID | `com.typemark.app` | Clean, professional namespace |
| Markdown rendering | `AttributedString(markdown:)` | Native Apple API, zero dependencies |
| State management | `@Observable` macro | Swift 5.9+ standard, ergonomic |
| Build system | SPM only (no .xcodeproj) | Portable; Xcode can open Package.swift |
| Syntax highlighting | Manual regex → AttributedString | No third-party deps; minimal bundle |
| Platform target | macOS 26, iOS 26 | Latest SwiftUI APIs |
| Architecture | DocumentGroup + FileDocument | Native document-based app; free undo/file management |
