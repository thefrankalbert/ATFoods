// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Home",
    platforms: [.iOS(.v17)],
    products: [.library(name: "Home", targets: ["Home"])],
    dependencies: [
        .package(path: "../../Core/DesignSystem"),
        .package(path: "../../Core/Models"),
        .package(path: "../../Core/Networking"),
    ],
    targets: [
        .target(
            name: "Home",
            dependencies: [
                .product(name: "DesignSystem", package: "DesignSystem"),
                .product(name: "Models", package: "Models"),
                .product(name: "Networking", package: "Networking"),
            ],
            path: "Sources/Home",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "HomeTests",
            dependencies: ["Home"],
            path: "Tests/HomeTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
