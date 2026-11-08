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
        .local(path: "Packages/Features/Drafts"),
        .local(path: "Packages/Features/Profile"),
        .remote(url: "https://github.com/getsentry/sentry-cocoa.git", requirement: .upToNextMajor(from: "9.33.0")),
    ],
    settings: .settings(
        base: [
            "SWIFT_STRICT_CONCURRENCY": "complete",
            "SWIFT_VERSION": "6.0",
            // Bump CURRENT_PROJECT_VERSION on every TestFlight / App Store upload.
            "MARKETING_VERSION": "1.0.0",
            "CURRENT_PROJECT_VERSION": "1",
            "CODE_SIGN_STYLE": "Automatic",
            // Set your Apple Developer Team ID here (Xcode > Settings > Accounts) before archiving.
            "DEVELOPMENT_TEAM": "",
            // Crash reporting: paste the Sentry DSN of the iOS project. Empty = reporting off.
            "SENTRY_DSN": "",
        ]
    ),
    targets: [
        .target(
            name: "ATFood",
            destinations: [.iPhone],   // phone companion: no iPad / Mac layouts
            product: .app,
            bundleId: "com.attable.atfood",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": .string("Atfood"),
                "CFBundleShortVersionString": .string("$(MARKETING_VERSION)"),
                "CFBundleVersion": .string("$(CURRENT_PROJECT_VERSION)"),
                "UILaunchScreen": .dictionary(["UIColorName": .string("LaunchBackground")]),
                "UISupportedInterfaceOrientations": .array([.string("UIInterfaceOrientationPortrait")]),
                "UIRequiresFullScreen": .boolean(true),
                // Tokens are light-only (Home and camera are dark by design): no white-on-white in dark mode.
                "UIUserInterfaceStyle": .string("Light"),
                "ITSAppUsesNonExemptEncryption": .boolean(false),
                "NSCameraUsageDescription": .string("Atfood utilise l'appareil photo pour photographier vos plats et les publier sur votre menu."),
                "SentryDSN": .string("$(SENTRY_DSN)"),
            ]),
            sources: ["App/**"],
            resources: ["App/Resources/**"],
            dependencies: [
                .package(product: "DesignSystem"),
                .package(product: "ATFAuth"),
                .package(product: "Home"),
                .package(product: "Capture"),
                .package(product: "Form"),
                .package(product: "Drafts"),
                .package(product: "Profile"),
                .package(product: "Sentry"),
            ]
        ),
        .target(
            name: "ATFoodUITests",
            destinations: [.iPhone],
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
