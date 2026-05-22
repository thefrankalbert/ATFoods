// App/ATFoodApp.swift
import SwiftUI
import DesignSystem

@main
struct ATFoodApp: App {
    init() {
        registerDesignSystemFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
