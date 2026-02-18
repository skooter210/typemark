# Models

Data models and view models for the application.

## Contents

- `MarkdownDocument.swift` — Implements `FileDocument` protocol. Holds the raw Markdown text and handles file read/write for `.md` files.
- `EditorViewModel.swift` — `@Observable` class that acts as the coordinator between the document, editor pane, and preview pane.

## Conventions

- `FileDocument` conformance: use `UTType.plainText` with preferred extension `md`.
- `@Observable` view models: mark as `@MainActor` to ensure UI-safe access.
- No business logic in `FileDocument`; formatting helpers live in `Utilities/`.
