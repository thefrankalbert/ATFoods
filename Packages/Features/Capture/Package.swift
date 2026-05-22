// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Capture",
    platforms: [.iOS(.v17)],
    products: [.library(name: "Capture", targets: ["Capture"])],
    dependencies: [
        .package(path: "../../Core/DesignSystem"),
        .package(path: "../../Core/Models"),
        .package(path: "../../Core/Networking"),
    ],
    targets: [
        .target(
            name: "Capture",
            dependencies: [
                .product(name: "DesignSystem", package: "DesignSystem"),
                .product(name: "Models", package: "Models"),
                .product(name: "Networking", package: "Networking"),
            ],
            path: "Sources/Capture",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "CaptureTests",
            dependencies: ["Capture"],
            path: "Tests/CaptureTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
