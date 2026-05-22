// App/RootView.swift
import SwiftUI
import DesignSystem
import Models
import Networking
import Auth
import Home
import Capture
import Form

// MARK: — Route

public enum ATFRoute: Hashable {
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
    @State private var hasSeenOnboarding = false
    @State private var path: [ATFRoute] = []
    @State private var toast: ATFToastData?

    private let networking: any ATFNetworking = MockNetworking()

    @State private var authStore = AuthStore()
    @State private var homeStore: HomeStore? = nil
    @State private var captureStore: CaptureStore? = nil
    @State private var formStore: FormStore? = nil

    var body: some View {
        ZStack(alignment: .top) {
            if !hasSeenOnboarding {
                OnboardingView { hasSeenOnboarding = true }
            } else {
                NavigationStack(path: $path) {
                    LoginView(store: authStore, networking: networking) {
                        path.append(.restaurantPicker)
                    }
                    .navigationBarHidden(true)
                    .navigationDestination(for: ATFRoute.self) { route in
                        routeView(route)
                    }
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

    // MARK: — Route destinations

    @ViewBuilder
    private func routeView(_ route: ATFRoute) -> some View {
        switch route {
        case .restaurantPicker:
            RestaurantPickerView(store: authStore) {
                if let restaurant = authStore.selectedRestaurant {
                    homeStore = HomeStore(restaurant: restaurant)
                    path = [.home]
                }
            }
            .navigationBarHidden(true)

        case .home:
            if let store = homeStore {
                HomeView(store: store, networking: networking) {
                    captureStore = CaptureStore(restaurant: store.restaurant)
                    path.append(.camera)
                }
                .navigationBarHidden(true)
            }

        case .camera:
            if let store = captureStore {
                CameraView(store: store, onCapture: {
                    path.append(.photoPreview(photoID: UUID()))
                }, onClose: {
                    path.removeLast()
                })
                .navigationBarHidden(true)
            }

        case .photoPreview:
            if let store = captureStore {
                PhotoPreviewView(store: store, onRetake: {
                    path.removeLast()
                }, onUse: {
                    path.append(.attachDish(photoID: UUID()))
                })
                .navigationBarHidden(true)
            }

        case .attachDish:
            if let store = captureStore {
                AttachDishView(
                    store: store,
                    networking: networking,
                    onNewDish: {
                        formStore = FormStore(restaurant: store.restaurant)
                        path.append(.dishForm(photoID: nil))
                    },
                    onAttached: {
                        showToast("Photo attachée !")
                        popToHome()
                    },
                    onBack: { path.removeLast() }
                )
                .navigationBarHidden(true)
            }

        case .dishForm:
            if let store = formStore {
                DishFormView(
                    store: store,
                    networking: networking,
                    onSaved: {
                        showToast("Plat enregistré !")
                        popToHome()
                    },
                    onBack: { path.removeLast() }
                )
                .navigationBarHidden(true)
            }
        }
    }

    // MARK: — Helpers

    private func showToast(_ message: String) {
        toast = ATFToastData(message)
        Task {
            try? await Task.sleep(for: .seconds(3))
            toast = nil
        }
    }

    private func popToHome() {
        if let idx = path.firstIndex(of: .home) {
            path = Array(path[...idx])
        } else {
            path = [.home]
        }
    }
}
