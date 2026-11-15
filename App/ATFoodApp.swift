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

    /// Crash reporting runs only in builds distributed by Apple (TestFlight, App Store), when a DSN is configured
    /// (SENTRY_DSN, Sentry project "atfood-ios", separate from the web SaaS). Debug builds (Xcode, simulator, UI tests) and cable installs never
    /// send anything: a test session must not look like a production outage.
    private func startCrashReporting() {
        #if !DEBUG
        // A build installed from Xcode onto a device carries its provisioning profile; store and TestFlight builds do not.
        // Those cable installs are tests too: stay silent.
        guard Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") == nil,
              let dsn = Bundle.main.object(forInfoDictionaryKey: "SentryDSN") as? String, !dsn.isEmpty else { return }
        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = "production"
            options.sendDefaultPii = false          // no emails / IPs: matches the privacy manifest
            options.attachScreenshot = false        // screens can show menus and prices
            options.tracesSampleRate = 0.1
            options.initialScope = { scope in
                scope.setTag(value: "atfood-ios", key: "app")   // tells app events from the web SaaS ones
                return scope
            }
        }
        #endif
    }
}
