// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Typemark",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
    ],
    targets: [
        .target(
            name: "TypemarkCore",
            path: "Sources/Typemark",
            exclude: [
                "App/TypemarkApp.swift",
                "App/README.md",
                "Views/README.md",
                "Models/README.md",
                "Utilities/README.md",
            ]
        ),
        .executableTarget(
            name: "Typemark",
            dependencies: ["TypemarkCore"],
            path: "Sources/TypemarkApp"
        ),
        .testTarget(
            name: "TypemarkTests",
            dependencies: ["TypemarkCore"],
            path: "Tests/TypemarkTests"
        ),
    ]
)
