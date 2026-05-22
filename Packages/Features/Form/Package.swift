// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Form",
    platforms: [.iOS(.v17)],
    products: [.library(name: "Form", targets: ["Form"])],
    dependencies: [
        .package(path: "../../Core/DesignSystem"),
        .package(path: "../../Core/Models"),
        .package(path: "../../Core/Networking"),
    ],
    targets: [
        .target(
            name: "Form",
            dependencies: [
                .product(name: "DesignSystem", package: "DesignSystem"),
                .product(name: "Models", package: "Models"),
                .product(name: "Networking", package: "Networking"),
            ],
            path: "Sources/Form",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
