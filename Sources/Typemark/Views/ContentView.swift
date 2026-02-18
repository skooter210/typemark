import SwiftUI

public struct ContentView: View {

    @Binding var document: MarkdownDocument
    var fileURL: URL?

    public init(document: Binding<MarkdownDocument>, fileURL: URL? = nil) {
        self._document = document
        self.fileURL = fileURL
    }

    @State private var viewModel = EditorViewModel()
    @State private var outlineScrollTarget: String? = nil
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    public var body: some View {
        Group {
#if os(macOS)
            macOSLayout
#else
            iPadLayout
#endif
        }
        .onAppear {
            viewModel.markdownText = document.text
            viewModel.documentURL = fileURL
        }
        .onChange(of: viewModel.markdownText) { _, newValue in
            document.text = newValue
        }
        .onChange(of: document.text) { _, newValue in
            if newValue != viewModel.markdownText {
                viewModel.markdownText = newValue
            }
        }
        .markdownToolbar(viewModel: viewModel)
    }

    // MARK: - macOS layout

    @ViewBuilder
    private var macOSLayout: some View {
        HStack(spacing: 0) {
            if viewModel.showOutline {
                outlineSidebar
                    .frame(width: 220)
                Divider()
            }

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
    }

    // MARK: - iPad layout

    @ViewBuilder
    private var iPadLayout: some View {
        if horizontalSizeClass == .compact || !viewModel.showPreview {
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
                    case .editor: EditorPaneView(viewModel: viewModel)
                    case .preview: PreviewPaneView(viewModel: viewModel)
                    }
                }
            }
        } else {
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

    // MARK: - Outline sidebar

    private var outlineSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Outline")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(viewModel.headings.enumerated()), id: \.offset) { _, heading in
                        Button {
                            outlineScrollTarget = heading.slug
                        } label: {
                            Text(heading.text)
                                .font(heading.level <= 2 ? .body.bold() : .body)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .padding(.leading, CGFloat(heading.level - 1) * 12)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .background(.ultraThinMaterial)
    }
}
