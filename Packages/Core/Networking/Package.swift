// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Networking",
    platforms: [.iOS(.v17)],
    products: [.library(name: "Networking", targets: ["Networking"])],
    dependencies: [
        .package(path: "../Models"),
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "Networking",
            dependencies: [
                .product(name: "Models", package: "Models"),
                .product(name: "Supabase", package: "supabase-swift"),
            ],
            path: "Sources/Networking",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "NetworkingTests",
            dependencies: ["Networking"],
            path: "Tests/NetworkingTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
