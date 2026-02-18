import SwiftUI

struct EditorPaneView: View {

    @Bindable var viewModel: EditorViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TextEditor(text: $viewModel.markdownText)
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.hidden)
            .padding(8)
            .background(backgroundColor)
    }

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.12, green: 0.12, blue: 0.14)
            : Color(red: 1.0, green: 1.0, blue: 1.0)
    }
}
