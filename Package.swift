// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DontBeSedentary",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "DontBeSedentary",
            path: "Sources",
            exclude: ["Info.plist"]
        )
    ]
)
