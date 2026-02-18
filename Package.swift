// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Typemark",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
    ],
    targets: [
        .executableTarget(
            name: "Typemark",
            path: "Sources/Typemark",
            exclude: [
                "App/README.md",
                "Views/README.md",
                "Models/README.md",
                "Utilities/README.md",
            ]
        ),
    ]
)
