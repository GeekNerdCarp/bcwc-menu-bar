// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BCWCMenuBar",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "BCWCMenuBar", targets: ["BCWCMenuBar"])
    ],
    targets: [
        .executableTarget(
            name: "BCWCMenuBar",
            path: "Sources/BCWCMenuBar"
        )
    ]
)
