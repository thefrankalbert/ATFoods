// App/ATFoodApp.swift
import SwiftUI
import DesignSystem
import Sentry

@main
struct ATFoodApp: App {
    init() {
        // Thumbnails and photos stay on disk between launches: lists scroll without re-downloading on mobile data.
        URLCache.shared = URLCache(memoryCapacity: 50_000_000, diskCapacity: 300_000_000)
        startCrashReporting()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }

    /// Crash reporting is on only when a DSN is configured (build setting SENTRY_DSN) and outside UI tests.
    private func startCrashReporting() {
        guard !Env.isUITesting,
              let dsn = Bundle.main.object(forInfoDictionaryKey: "SentryDSN") as? String,
              !dsn.isEmpty else { return }
        SentrySDK.start { options in
            options.dsn = dsn
            options.sendDefaultPii = false          // no emails / IPs: matches the privacy manifest
            options.attachScreenshot = false        // screens can show menus and prices
            options.tracesSampleRate = 0.1
            options.initialScope = { scope in
                scope.setTag(value: "atfood-ios", key: "app")   // shared project with the web SaaS
                return scope
            }
            #if DEBUG
            options.environment = "debug"
            #else
            options.environment = "production"
            #endif
        }
    }
}
