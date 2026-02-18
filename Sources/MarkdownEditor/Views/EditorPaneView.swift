import SwiftUI

// MARK: - EditorPaneView

/// The left pane of the split editor. Displays a raw Markdown `TextEditor`
/// with a syntax-highlighted overlay rendered on top.
///
/// Architecture note:
/// SwiftUI's `TextEditor` does not expose NSTextView/UITextView's attributed text
/// directly. We therefore use a ZStack approach:
///   1. An invisible `TextEditor` captures user input and cursor interaction.
///   2. A `Text(AttributedString)` overlay provides syntax coloring.
/// This gives us editable text + visual highlighting without AppKit bridging.
struct EditorPaneView: View {

    // MARK: Dependencies

    @Bindable var viewModel: EditorViewModel

    // MARK: Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: Body

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Underlying text editor (captures input)
            TextEditor(text: $viewModel.markdownText)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.clear)           // transparent text — overlay does the rendering
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))

            // Syntax-highlighted overlay (read-only)
            Text(highlighted)
                .font(.system(.body, design: .monospaced))
                .textSelection(.disabled)
                .allowsHitTesting(false)           // pass touches through to TextEditor
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(editorBackground)
    }

    // MARK: Computed

    private var highlighted: AttributedString {
        SyntaxHighlighter.highlight(viewModel.markdownText, colorScheme: colorScheme)
    }

    private var editorBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.13, green: 0.13, blue: 0.15)
            : Color(red: 0.97, green: 0.97, blue: 0.98)
    }
}
