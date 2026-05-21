// App/ContentView.swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.93, blue: 0.91)
                .ignoresSafeArea()
            Text("ATFood — Plan 2 pending")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}
