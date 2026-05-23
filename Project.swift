// Project.swift
import ProjectDescription

let project = Project(
    name: "ATFood",
    organizationName: "ATTable",
    options: .options(
        defaultKnownRegions: ["fr"],
        developmentRegion: "fr"
    ),
    packages: [
        .local(path: "Packages/Core/DesignSystem"),
        .local(path: "Packages/Core/Models"),
        .local(path: "Packages/Core/Networking"),
        .local(path: "Packages/Features/Auth"),
        .local(path: "Packages/Features/Home"),
        .local(path: "Packages/Features/Capture"),
        .local(path: "Packages/Features/Form"),
    ],
    settings: .settings(
        base: [
            "SWIFT_STRICT_CONCURRENCY": "complete",
            "SWIFT_VERSION": "6.0",
        ]
    ),
    targets: [
        .target(
            name: "ATFood",
            destinations: .iOS,
            product: .app,
            bundleId: "com.attable.atfood",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": .dictionary([:]),
                "NSCameraUsageDescription": .string("At Food utilise l'appareil photo pour photographier vos plats."),
                "NSPhotoLibraryUsageDescription": .string("At Food accède à votre galerie pour importer des photos de plats."),
            ]),
            sources: ["App/**"],
            dependencies: [
                .package(product: "DesignSystem"),
                .package(product: "Auth"),
                .package(product: "Home"),
                .package(product: "Capture"),
                .package(product: "Form"),
            ]
        ),
        .target(
            name: "ATFoodUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "com.attable.atfood.uitests",
            deploymentTargets: .iOS("17.0"),
            sources: ["UITests/**"],
            dependencies: [
                .target(name: "ATFood"),
            ]
        )
    ]
)
