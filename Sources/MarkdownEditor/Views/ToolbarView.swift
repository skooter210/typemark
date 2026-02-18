import SwiftUI

// MARK: - ToolbarContent for MarkdownEditor

/// Provides toolbar items for the Markdown editor scene.
///
/// Uses `.toolbar` modifier pattern — call `markdownToolbar(viewModel:)` on a view.
struct MarkdownToolbarContent: ToolbarContent {

    @Bindable var viewModel: EditorViewModel

    var body: some ToolbarContent {
        // Leading group: formatting actions
        ToolbarItemGroup(placement: toolbarLeadingPlacement) {
            headingMenu
            Divider()
            boldButton
            italicButton
            Divider()
            codeButton
            linkButton
            Divider()
            blockquoteButton
        }

        // Trailing group: view toggle
        ToolbarItemGroup(placement: .automatic) {
            previewToggle
        }
    }

    // MARK: - Heading menu

    private var headingMenu: some View {
        Menu {
            ForEach(1...6, id: \.self) { level in
                Button {
                    viewModel.applyHeading(level: level)
                } label: {
                    Label(
                        "Heading \(level)",
                        systemImage: "textformat.size.larger"
                    )
                }
            }
        } label: {
            Label("Heading", systemImage: "textformat.size")
        }
        .help("Insert heading")
    }

    // MARK: - Format buttons

    private var boldButton: some View {
        Button {
            viewModel.applyInlineFormat(prefix: "**", suffix: "**", placeholder: "bold text")
        } label: {
            Label("Bold", systemImage: "bold")
        }
        .help("Bold (Cmd+B)")
        .keyboardShortcut("b", modifiers: .command)
    }

    private var italicButton: some View {
        Button {
            viewModel.applyInlineFormat(prefix: "*", suffix: "*", placeholder: "italic text")
        } label: {
            Label("Italic", systemImage: "italic")
        }
        .help("Italic (Cmd+I)")
        .keyboardShortcut("i", modifiers: .command)
    }

    private var codeButton: some View {
        Button {
            viewModel.insertCodeBlock()
        } label: {
            Label("Code", systemImage: "chevron.left.forwardslash.chevron.right")
        }
        .help("Insert code block (Cmd+`)")
        .keyboardShortcut("`", modifiers: .command)
    }

    private var linkButton: some View {
        Button {
            viewModel.insertLink()
        } label: {
            Label("Link", systemImage: "link")
        }
        .help("Insert link (Cmd+K)")
        .keyboardShortcut("k", modifiers: .command)
    }

    private var blockquoteButton: some View {
        Button {
            viewModel.insertBlockquote()
        } label: {
            Label("Blockquote", systemImage: "text.quote")
        }
        .help("Insert blockquote")
    }

    // MARK: - Preview toggle

    private var previewToggle: some View {
        Button {
            viewModel.showPreview.toggle()
        } label: {
            Label(
                viewModel.showPreview ? "Hide Preview" : "Show Preview",
                systemImage: viewModel.showPreview ? "rectangle.lefthalf.filled" : "rectangle"
            )
        }
        .help("Toggle preview pane")
        .keyboardShortcut("p", modifiers: [.command, .shift])
    }

    // MARK: - Platform placement

    private var toolbarLeadingPlacement: ToolbarItemPlacement {
#if os(macOS)
        .principal
#else
        .bottomBar
#endif
    }
}

// MARK: - View extension for ergonomic usage

extension View {
    func markdownToolbar(viewModel: EditorViewModel) -> some View {
        toolbar {
            MarkdownToolbarContent(viewModel: viewModel)
        }
    }
}
