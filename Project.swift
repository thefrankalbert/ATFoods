// Project.swift
import ProjectDescription

// Sign in with Apple: needs the paid Apple Developer Program team (a Personal Team cannot sign this entitlement)
// and the Apple provider enabled on Supabase with client ID com.attable.atfood. Turn on with the team switch below.
let signInWithApple = false

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
        // ponytail: exact pin. Package.resolved is not committed, so a range let CI pick each new Sentry release and
        // download its large binaries (9.35.0 timed out the job). Bump this line by hand to update Sentry.
        .remote(url: "https://github.com/getsentry/sentry-cocoa.git", requirement: .exact("9.33.0")),
    ],
    settings: .settings(
        base: [
            "SWIFT_STRICT_CONCURRENCY": "complete",
            "SWIFT_VERSION": "6.0",
            // Bump CURRENT_PROJECT_VERSION on every TestFlight / App Store upload.
            "MARKETING_VERSION": "1.0.0",
            "CURRENT_PROJECT_VERSION": "1",
            "CODE_SIGN_STYLE": "Automatic",
            // XK5L7S88SQ = Frank Albert (Personal Team): installs on a device. App Store upload needs the
            // paid Apple Developer Program team ID instead.
            "DEVELOPMENT_TEAM": "XK5L7S88SQ",
            // Crash reporting (public client key): Sentry project atfood-ios, separate from the web SaaS.
            "SENTRY_DSN": "https://45662e65d94b1ec596d839ba19a0aaeb@o4510850246508544.ingest.de.sentry.io/4512434663325776",
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
                // System prompts (Google sign-in sheet) use the bundle name: same spelling as the home screen.
                "CFBundleName": .string("Atfood"),
                "CFBundleShortVersionString": .string("$(MARKETING_VERSION)"),
                "CFBundleVersion": .string("$(CURRENT_PROJECT_VERSION)"),
                "UILaunchScreen": .dictionary(["UIColorName": .string("LaunchBackground")]),
                "UISupportedInterfaceOrientations": .array([.string("UIInterfaceOrientationPortrait")]),
                // On iPad the iPhone app runs in a window: portrait-only shows it turned sideways when the iPad is held
                // in landscape. All orientations keep it upright.
                "UISupportedInterfaceOrientations~ipad": .array([
                    .string("UIInterfaceOrientationPortrait"), .string("UIInterfaceOrientationPortraitUpsideDown"),
                    .string("UIInterfaceOrientationLandscapeLeft"), .string("UIInterfaceOrientationLandscapeRight"),
                ]),
                // Tokens are light-only (Home and camera are dark by design): no white-on-white in dark mode.
                "UIUserInterfaceStyle": .string("Light"),
                "ITSAppUsesNonExemptEncryption": .boolean(false),
                "NSCameraUsageDescription": .string("Atfood utilise l'appareil photo pour photographier vos plats et les publier sur votre menu."),
                "SentryDSN": .string("$(SENTRY_DSN)"),
                "ATFSignInWithApple": .boolean(signInWithApple),
            ]),
            sources: ["App/**"],
            resources: ["App/Resources/**"],
            entitlements: signInWithApple
                ? .dictionary(["com.apple.developer.applesignin": .array([.string("Default")])]) : nil,
            scripts: [
                // Release builds send their debug symbols to Sentry so App Store crash reports show file and line.
                // Auth: ~/.sentryclirc (org token, outside the repo). Skipped on CI and when sentry-cli is missing.
                .post(
                    script: """
                    if [ "$CONFIGURATION" != "Release" ] || [ -n "$CI" ]; then exit 0; fi
                    export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
                    if ! command -v sentry-cli >/dev/null; then
                      echo "warning: sentry-cli not installed (brew install getsentry/tools/sentry-cli): crash symbols not sent to Sentry"
                      exit 0
                    fi
                    sentry-cli debug-files upload --org odc-digital-solub --project atfood-ios --include-sources "$DWARF_DSYM_FOLDER_PATH" \\
                      || echo "warning: crash symbols upload to Sentry failed"
                    """,
                    name: "Upload debug symbols to Sentry",
                    inputPaths: ["${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}"],
                    basedOnDependencyAnalysis: false
                ),
            ],
            dependencies: [
                .package(product: "DesignSystem"),
                .package(product: "ATFAuth"),
                .package(product: "Home"),
                .package(product: "Capture"),
                .package(product: "Form"),
                .package(product: "Drafts"),
                .package(product: "Profile"),
                .package(product: "Sentry"),
            ],
            // The symbols upload reads ~/.sentryclirc and the dSYM folder: not possible inside the script sandbox.
            settings: .settings(base: ["ENABLE_USER_SCRIPT_SANDBOXING": "NO"])
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
