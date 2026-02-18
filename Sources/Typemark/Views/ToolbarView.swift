import SwiftUI

struct MarkdownToolbarContent: ToolbarContent {

    @Bindable var viewModel: EditorViewModel

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: toolbarLeadingPlacement) {
            headingMenu
            Divider()
            boldButton
            italicButton
            strikethroughButton
            highlightButton
            Divider()
            codeButton
            linkButton
            imageButton
            Divider()
            blockquoteButton
            tableButton
            taskListButton
            hrButton
        }

        ToolbarItemGroup(placement: .automatic) {
            outlineToggle
            focusToggle
            previewToggle
            exportMenu
        }
    }

    private var headingMenu: some View {
        Menu {
            ForEach(1...6, id: \.self) { level in
                Button("H\(level)") { viewModel.applyHeading(level: level) }
            }
        } label: {
            Label("Heading", systemImage: "textformat.size")
        }
        .help("Insert heading")
    }

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

    private var strikethroughButton: some View {
        Button {
            viewModel.insertStrikethrough()
        } label: {
            Label("Strikethrough", systemImage: "strikethrough")
        }
        .help("Strikethrough (Cmd+Shift+X)")
        .keyboardShortcut("x", modifiers: [.command, .shift])
    }

    private var highlightButton: some View {
        Button {
            viewModel.insertHighlight()
        } label: {
            Label("Highlight", systemImage: "highlighter")
        }
        .help("Highlight (Cmd+Shift+H)")
        .keyboardShortcut("h", modifiers: [.command, .shift])
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

    private var imageButton: some View {
        Button {
            viewModel.insertImage()
        } label: {
            Label("Image", systemImage: "photo")
        }
        .help("Insert image")
    }

    private var blockquoteButton: some View {
        Button {
            viewModel.insertBlockquote()
        } label: {
            Label("Blockquote", systemImage: "text.quote")
        }
        .help("Insert blockquote")
    }

    private var tableButton: some View {
        Button {
            viewModel.insertTable()
        } label: {
            Label("Table", systemImage: "tablecells")
        }
        .help("Insert table")
    }

    private var taskListButton: some View {
        Button {
            viewModel.insertTaskList()
        } label: {
            Label("Task List", systemImage: "checklist")
        }
        .help("Insert task list")
    }

    private var hrButton: some View {
        Button {
            viewModel.insertHorizontalRule()
        } label: {
            Label("Horizontal Rule", systemImage: "minus")
        }
        .help("Insert horizontal rule")
    }

    private var outlineToggle: some View {
        Button {
            viewModel.showOutline.toggle()
        } label: {
            Label(
                viewModel.showOutline ? "Hide Outline" : "Show Outline",
                systemImage: "list.bullet.indent"
            )
        }
        .help("Toggle document outline (Cmd+Shift+O)")
        .keyboardShortcut("o", modifiers: [.command, .shift])
    }

    private var focusToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.focusMode.toggle()
            }
        } label: {
            Label(
                viewModel.focusMode ? "Exit Focus" : "Focus Mode",
                systemImage: viewModel.focusMode ? "eye.fill" : "eye"
            )
        }
        .help("Toggle focus mode (Cmd+Shift+F)")
        .keyboardShortcut("f", modifiers: [.command, .shift])
    }

    private var previewToggle: some View {
        Button {
            viewModel.showPreview.toggle()
        } label: {
            Label(
                viewModel.showPreview ? "Hide Preview" : "Show Preview",
                systemImage: viewModel.showPreview ? "rectangle.lefthalf.filled" : "rectangle"
            )
        }
        .help("Toggle preview (Cmd+Shift+P)")
        .keyboardShortcut("p", modifiers: [.command, .shift])
    }

    private var exportMenu: some View {
        Menu {
            Button("Export HTML…") { exportHTML() }
            Button("Export PDF…") { exportPDF() }
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
        }
        .help("Export document")
    }

    private func exportHTML() {
        let html = viewModel.exportHTML()
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.html]
        panel.nameFieldStringValue = "document.html"
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? html.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    private func exportPDF() {
        let html = viewModel.exportHTML()
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "document.pdf"
        panel.begin { response in
            if response == .OK, let url = panel.url {
                PDFRenderer.render(html: html, to: url)
            }
        }
    }

    private var toolbarLeadingPlacement: ToolbarItemPlacement {
#if os(macOS)
        .principal
#else
        .bottomBar
#endif
    }
}

extension View {
    func markdownToolbar(viewModel: EditorViewModel) -> some View {
        toolbar {
            MarkdownToolbarContent(viewModel: viewModel)
        }
    }
}
