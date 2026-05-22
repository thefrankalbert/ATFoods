// App/RootView.swift
import SwiftUI
import DesignSystem
import Models
import Networking

// MARK: — Route

public enum ATFRoute: Hashable {
    case login
    case restaurantPicker
    case home
    case camera
    case photoPreview(photoID: UUID)
    case attachDish(photoID: UUID)
    case dishForm(photoID: UUID?)
}

// MARK: — Root

@MainActor
struct RootView: View {
    @State private var path: [ATFRoute] = []
    @State private var toast: ATFToastData?
    private let networking: any ATFNetworking = MockNetworking()

    var body: some View {
        ZStack(alignment: .top) {
            NavigationStack(path: $path) {
                // Placeholder until OnboardingView is implemented in Task 7
                Color.atfBg
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 16) {
                            ATFWordmark(size: 32)
                            Text("ATFood — loading…")
                                .font(.atfSubhead)
                                .foregroundStyle(Color.atfText3)
                        }
                    )
                    .navigationBarHidden(true)
                    .navigationDestination(for: ATFRoute.self) { route in
                        routePlaceholder(route)
                    }
            }

            if let toast {
                ATFToastOverlay(toast: toast)
                    .padding(.top, 64)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
                    .onTapGesture { self.toast = nil }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: toast != nil)
    }

    @ViewBuilder
    private func routePlaceholder(_ route: ATFRoute) -> some View {
        switch route {
        case .login:
            Text("Login — Task 6").font(.atfBody).foregroundStyle(Color.atfText2)
        case .restaurantPicker:
            Text("RestaurantPicker — Task 8").font(.atfBody).foregroundStyle(Color.atfText2)
        case .home:
            Text("Home — Task 9").font(.atfBody).foregroundStyle(Color.atfText2)
        case .camera:
            Text("Camera — Task 10").font(.atfBody).foregroundStyle(Color.atfText2)
        case .photoPreview:
            Text("PhotoPreview — Task 11").font(.atfBody).foregroundStyle(Color.atfText2)
        case .attachDish:
            Text("AttachDish — Task 11").font(.atfBody).foregroundStyle(Color.atfText2)
        case .dishForm:
            Text("DishForm — Task 12").font(.atfBody).foregroundStyle(Color.atfText2)
        }
    }

    func showToast(_ message: String) {
        toast = ATFToastData(message)
        Task {
            try? await Task.sleep(for: .seconds(3))
            toast = nil
        }
    }

    func popToHome() {
        if let idx = path.firstIndex(of: .home) {
            path = Array(path[...idx])
        } else {
            path = [.home]
        }
    }
}
