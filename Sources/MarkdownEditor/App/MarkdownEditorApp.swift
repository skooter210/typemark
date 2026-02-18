import SwiftUI

// MARK: - MarkdownEditorApp

/// Application entry point.
///
/// Uses `DocumentGroup` to provide a native document-based experience:
/// - File > New creates a fresh Markdown document.
/// - File > Open presents the standard file picker filtered to `.md` files.
/// - File > Save / Save As write back via `MarkdownDocument.fileWrapper(configuration:)`.
/// - Undo/Redo history is managed automatically by the document system.
@main
struct MarkdownEditorApp: App {

    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            ContentView(document: file.$document)
#if os(macOS)
                .frame(minWidth: 700, minHeight: 500)
#endif
        }
#if os(macOS)
        .commands {
            // Replace the default "Help" with project-specific help.
            CommandGroup(replacing: .help) {
                Link("MarkdownEditor Documentation",
                     destination: URL(string: "https://daringfireball.net/projects/markdown/")!)
            }

            // Add additional formatting commands to the Edit menu.
            CommandGroup(after: .pasteboard) {
                Divider()
                Text("Markdown Formatting")
                    .foregroundStyle(.secondary)
            }
        }
        .defaultSize(width: 1100, height: 700)
#endif
    }
}
