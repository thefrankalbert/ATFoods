// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Networking",
    platforms: [.iOS(.v17)],
    products: [.library(name: "Networking", targets: ["Networking"])],
    dependencies: [
        .package(path: "../Models"),
    ],
    targets: [
        .target(
            name: "Networking",
            dependencies: [.product(name: "Models", package: "Models")],
            path: "Sources/Networking",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
