// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BCWCMenuBar",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "BCWCMenuBar", targets: ["BCWCMenuBar"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.10.1")
    ],
    targets: [
        .executableTarget(
            name: "BCWCMenuBar",
            dependencies: [.product(name: "Sparkle", package: "Sparkle")],
            path: "Sources/BCWCMenuBar",
            linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])]
        )
    ]
)
