// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AIRetouch",
    platforms: [.iOS(.v17)],
    products: [.library(name: "AIRetouch", targets: ["AIRetouch"])],
    dependencies: [
        .package(path: "../../Core/DesignSystem"),
        .package(path: "../../Core/Models"),
        .package(path: "../../Core/Networking"),
    ],
    targets: [
        .target(
            name: "AIRetouch",
            dependencies: [
                .product(name: "DesignSystem", package: "DesignSystem"),
                .product(name: "Models", package: "Models"),
                .product(name: "Networking", package: "Networking"),
            ],
            path: "Sources/AIRetouch",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "AIRetouchTests",
            dependencies: ["AIRetouch"],
            path: "Tests/AIRetouchTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
