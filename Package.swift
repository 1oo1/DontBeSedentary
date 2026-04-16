// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DontBeSedentary",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "DontBeSedentary",
            path: "Sources",
            exclude: ["Info.plist"]
        )
    ]
)
