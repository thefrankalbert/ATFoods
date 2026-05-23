// App/RootView.swift
import SwiftUI
import DesignSystem
import Models
import Networking
import Auth
import Home
import Capture
import Form
import Drafts
import AIRetouch
import Profile

// MARK: — Navigation state

// Class-backed navigator: mutations from any captured closure reach the same instance,
// bypassing the @State struct-copy issue in navigationDestination closures.
@MainActor @Observable final class AppNavigator {
    var homeStore: HomeStore?
    var captureStore: CaptureStore?
    var formStore: FormStore?
    var draftsStore: DraftsStore?
    var aiRetouchStore: AIRetouchStore?
    var profileStore: ProfileStore?
    var showUpgradeSheet: Bool = false
}

// MARK: — Route

public enum ATFRoute: Hashable {
    case restaurantPicker
    case home
    case camera
    case photoPreview
    case attachDish
    case dishForm
    case drafts
    case aiRetouch(dishID: UUID)
    case backgrounds(dishID: UUID)
    case credits
    case profile
    case offline
}

// MARK: — Root

@MainActor
struct RootView: View {
    @State private var hasSeenOnboarding = false
    @State private var path: [ATFRoute] = []
    @State private var toast: ATFToastData?

    private let networking: any ATFNetworking = MockNetworking()

    @State private var authStore = AuthStore()
    // AppNavigator is a class — mutations from captured closures always reach the same instance
    @State private var nav = AppNavigator()

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
        .sheet(isPresented: $nav.showUpgradeSheet) {
            UpgradeSheet { nav.showUpgradeSheet = false }
        }
    }

    // MARK: — Route destinations

    @ViewBuilder
    private func routeView(_ route: ATFRoute) -> some View {
        switch route {
        case .restaurantPicker:
            RestaurantPickerView(store: authStore) {
                if let restaurant = authStore.selectedRestaurant {
                    // nav is a class — mutation reaches the real instance from any closure context
                    nav.homeStore = HomeStore(restaurant: restaurant)
                    path = [.home]
                }
            }
            .navigationBarHidden(true)

        case .home:
            if let store = nav.homeStore {
                HomeView(
                    store: store,
                    networking: networking,
                    onCamera: {
                        nav.captureStore = CaptureStore(restaurant: store.restaurant)
                        path.append(.camera)
                    },
                    onDrafts: {
                        nav.draftsStore = DraftsStore(restaurantID: store.restaurant.id)
                        path.append(.drafts)
                    },
                    onProfile: {
                        if let user = authStore.currentUser,
                           let restaurant = authStore.selectedRestaurant {
                            nav.profileStore = ProfileStore(user: user, restaurant: restaurant)
                            path.append(.profile)
                        }
                    }
                )
                .navigationBarHidden(true)
            }

        case .camera:
            if let store = nav.captureStore {
                CameraView(store: store, onCapture: {
                    path.append(.photoPreview)
                }, onClose: {
                    path.removeLast()
                })
                .navigationBarHidden(true)
            }

        case .photoPreview:
            if let store = nav.captureStore {
                PhotoPreviewView(store: store, onRetake: {
                    path.removeLast()
                }, onUse: {
                    path.append(.attachDish)
                })
                .navigationBarHidden(true)
            }

        case .attachDish:
            if let store = nav.captureStore {
                AttachDishView(
                    store: store,
                    networking: networking,
                    onNewDish: {
                        nav.formStore = FormStore(
                            restaurant: store.restaurant,
                            capturedImage: store.capturedImage
                        )
                        path.append(.dishForm)
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
            if let store = nav.formStore {
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

        case .drafts:
            if let store = nav.draftsStore {
                DraftsView(
                    store: store,
                    networking: networking,
                    onAIRetouch: { dishID in
                        let draft = store.drafts.first { $0.id == dishID }
                        nav.aiRetouchStore = AIRetouchStore(
                            dishID: dishID,
                            originalURL: draft?.photoURL,
                            creditsBalance: nav.profileStore?.creditsBalance ?? 5
                        )
                        path.append(.aiRetouch(dishID: dishID))
                    },
                    onBack: { path.removeLast() }
                )
                .navigationBarHidden(true)
            }

        case .aiRetouch(let dishID):
            if let store = nav.aiRetouchStore {
                AIRetouchView(
                    store: store,
                    networking: networking,
                    onSelectBackground: { path.append(.backgrounds(dishID: dishID)) },
                    onBack: { path.removeLast() },
                    onUpgrade: { nav.showUpgradeSheet = true }
                )
                .navigationBarHidden(true)
            }

        case .backgrounds(_):
            if let store = nav.aiRetouchStore {
                BackgroundsView(
                    store: store,
                    networking: networking,
                    onApplied: { path.removeLast() },
                    onBack: { path.removeLast() }
                )
                .navigationBarHidden(true)
            }

        case .credits:
            if let store = nav.profileStore {
                CreditsView(
                    store: store,
                    onUpgrade: { nav.showUpgradeSheet = true },
                    onBack: { path.removeLast() }
                )
                .navigationBarHidden(true)
            }

        case .profile:
            if let store = nav.profileStore {
                ProfileView(
                    store: store,
                    networking: networking,
                    onCredits: { path.append(.credits) },
                    onUpgrade: { nav.showUpgradeSheet = true },
                    onOffline: { path.append(.offline) },
                    onSignOut: {
                        Task {
                            await store.signOut(networking: networking)
                            authStore.currentUser = nil
                            authStore.selectedRestaurant = nil
                            authStore.restaurants = []
                            nav.homeStore = nil
                            nav.draftsStore = nil
                            nav.profileStore = nil
                            path = []
                        }
                    },
                    onBack: { path.removeLast() }
                )
                .navigationBarHidden(true)
            }

        case .offline:
            OfflineView(
                pendingCount: 0,
                onRetry: { path.removeLast() },
                onBack: { path.removeLast() }
            )
            .navigationBarHidden(true)
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
