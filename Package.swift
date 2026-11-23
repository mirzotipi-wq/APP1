// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LightingCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "LightingCore", targets: ["LightingCore"])],
    targets: [
        .target(name: "LightingCore"),
        .testTarget(name: "LightingCoreTests", dependencies: ["LightingCore"])
    ]
)
