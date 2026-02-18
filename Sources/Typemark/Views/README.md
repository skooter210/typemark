# Views

All SwiftUI view files live here.

## Contents

- `ContentView.swift` — Root view; renders the split-pane layout (HSplitView on macOS, NavigationSplitView on iPadOS).
- `EditorPaneView.swift` — Left pane containing the raw Markdown TextEditor with syntax highlighting overlay.
- `PreviewPaneView.swift` — Right pane displaying the rendered Markdown using AttributedString.
- `ToolbarView.swift` — Toolbar buttons for formatting actions; injected into the scene toolbar.

## Conventions

- Each file contains exactly one primary View type.
- Views are pure SwiftUI — no UIKit/AppKit unless absolutely necessary.
- Use `@Bindable` to bind to `@Observable` view models.
- View-specific state uses `@State`; shared state passes through the view model.
