// Tuist/Project.swift
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
                "UIAppFonts": .array([
                    .string("InstrumentSerif-Regular.ttf"),
                    .string("InstrumentSerif-Italic.ttf"),
                ]),
            ]),
            sources: ["App/**"],
            dependencies: [
                .package(product: "DesignSystem"),
            ]
        )
    ]
)
