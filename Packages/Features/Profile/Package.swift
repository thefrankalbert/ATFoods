// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Profile",
    platforms: [.iOS(.v17)],
    products: [.library(name: "Profile", targets: ["Profile"])],
    dependencies: [
        .package(path: "../../Core/DesignSystem"),
        .package(path: "../../Core/Models"),
        .package(path: "../../Core/Networking"),
    ],
    targets: [
        .target(
            name: "Profile",
            dependencies: [
                .product(name: "DesignSystem", package: "DesignSystem"),
                .product(name: "Models", package: "Models"),
                .product(name: "Networking", package: "Networking"),
            ],
            path: "Sources/Profile",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "ProfileTests",
            dependencies: ["Profile"],
            path: "Tests/ProfileTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
