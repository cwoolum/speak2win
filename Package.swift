// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Speak2",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.9.0")
    ],
    targets: [
        .executableTarget(
            name: "Speak2",
            dependencies: ["WhisperKit"],
            path: "Sources",
            resources: [
                .process("../Resources")
            ]
        )
    ]
)
