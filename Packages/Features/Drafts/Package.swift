// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Drafts",
    platforms: [.iOS(.v17)],
    products: [.library(name: "Drafts", targets: ["Drafts"])],
    dependencies: [
        .package(path: "../../Core/DesignSystem"),
        .package(path: "../../Core/Models"),
        .package(path: "../../Core/Networking"),
    ],
    targets: [
        .target(
            name: "Drafts",
            dependencies: [
                .product(name: "DesignSystem", package: "DesignSystem"),
                .product(name: "Models", package: "Models"),
                .product(name: "Networking", package: "Networking"),
            ],
            path: "Sources/Drafts",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "DraftsTests",
            dependencies: ["Drafts"],
            path: "Tests/DraftsTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
