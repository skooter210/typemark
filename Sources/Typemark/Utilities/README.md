# Utilities

Stateless helper functions and services.

## Contents

- `SyntaxHighlighter.swift` — Applies color attributes to raw Markdown text for display in the editor pane. Uses regex patterns to identify Markdown syntax elements.
- `MarkdownFormatter.swift` — Pure functions for inserting Markdown formatting around selected text (bold, italic, heading, link, code). Used by toolbar buttons and keyboard shortcuts.

## Conventions

- All functions are pure (no side effects) where possible.
- No SwiftUI imports — utilities work on `String` and `AttributedString` only.
- Regex patterns are pre-compiled as static properties for performance.
