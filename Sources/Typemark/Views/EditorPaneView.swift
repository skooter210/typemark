import SwiftUI

public struct EditorPaneView: View {

    @Bindable var viewModel: EditorViewModel
    @Environment(\.colorScheme) private var colorScheme

    public var body: some View {
        VStack(spacing: 0) {
            TextEditor(text: $viewModel.markdownText)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(8)
                .opacity(viewModel.focusMode ? 0.35 : 1.0)

            // Status bar
            HStack(spacing: 16) {
                Text("\(viewModel.wordCount) words")
                Text("\(viewModel.characterCount) chars")
                Text(viewModel.readingTime)
                Spacer()
                if viewModel.focusMode {
                    Text("Focus Mode")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                colorScheme == .dark
                    ? Color.white.opacity(0.04)
                    : Color.black.opacity(0.03)
            )
        }
        .background(backgroundColor)
    }

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.12, green: 0.12, blue: 0.14)
            : Color(red: 1.0, green: 1.0, blue: 1.0)
    }
}
