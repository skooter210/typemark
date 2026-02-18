// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MarkdownEditor",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
    ],
    targets: [
        .executableTarget(
            name: "MarkdownEditor",
            path: "Sources/MarkdownEditor",
            exclude: [
                "App/README.md",
                "Views/README.md",
                "Models/README.md",
                "Utilities/README.md",
            ]
        ),
    ]
)
