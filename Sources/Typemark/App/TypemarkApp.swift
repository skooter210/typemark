import SwiftUI

@main
struct TypemarkApp: App {

    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            ContentView(document: file.$document, fileURL: file.fileURL)
#if os(macOS)
                .frame(minWidth: 700, minHeight: 500)
#endif
        }
#if os(macOS)
        .commands {
            CommandGroup(replacing: .help) {
                Link("Typemark Documentation",
                     destination: URL(string: "https://daringfireball.net/projects/markdown/")!)
            }

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
