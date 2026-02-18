import SwiftUI

// MARK: - ContentView

/// Root view for the Markdown editor. Renders an adaptive split-pane layout:
/// - macOS: `HSplitView` with resizable divider
/// - iPadOS: `NavigationSplitView` with sidebar/detail columns
///
/// The view owns an `EditorViewModel` and injects it into child views.
struct ContentView: View {

    // MARK: Document binding

    @Binding var document: MarkdownDocument
    var fileURL: URL?

    // MARK: View model

    @State private var viewModel = EditorViewModel()

    // MARK: Environment

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: Body

    var body: some View {
        // Keep view model in sync with document.
        // Document is the source of truth; view model mirrors it.
        Group {
#if os(macOS)
            macOSLayout
#else
            iPadLayout
#endif
        }
        // Sync: document → viewModel on appear
        .onAppear {
            viewModel.markdownText = document.text
            viewModel.documentURL = fileURL
        }
        // Sync: viewModel → document on every change
        .onChange(of: viewModel.markdownText) { _, newValue in
            document.text = newValue
        }
        // Sync: document → viewModel if external changes occur (e.g., file revert)
        .onChange(of: document.text) { _, newValue in
            if newValue != viewModel.markdownText {
                viewModel.markdownText = newValue
            }
        }
        .markdownToolbar(viewModel: viewModel)
    }

    // MARK: macOS layout

    @ViewBuilder
    private var macOSLayout: some View {
        if viewModel.showPreview {
            HSplitView {
                EditorPaneView(viewModel: viewModel)
                    .frame(minWidth: 280)

                PreviewPaneView(viewModel: viewModel)
                    .frame(minWidth: 280)
            }
        } else {
            EditorPaneView(viewModel: viewModel)
        }
    }

    // MARK: iPad layout

    @ViewBuilder
    private var iPadLayout: some View {
        if horizontalSizeClass == .compact || !viewModel.showPreview {
            // Compact: show picker to switch between panes
            VStack(spacing: 0) {
                Picker("Pane", selection: $viewModel.selectedPane) {
                    ForEach(EditorViewModel.Pane.allCases, id: \.self) { pane in
                        Text(pane.rawValue).tag(pane)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                Group {
                    switch viewModel.selectedPane {
                    case .editor:
                        EditorPaneView(viewModel: viewModel)
                    case .preview:
                        PreviewPaneView(viewModel: viewModel)
                    }
                }
            }
        } else {
            // Regular width: side-by-side
            NavigationSplitView {
                EditorPaneView(viewModel: viewModel)
                    .navigationTitle("Editor")
#if !os(macOS)
                    .navigationBarTitleDisplayMode(.inline)
#endif
            } detail: {
                PreviewPaneView(viewModel: viewModel)
                    .navigationTitle("Preview")
#if !os(macOS)
                    .navigationBarTitleDisplayMode(.inline)
#endif
            }
        }
    }
}
