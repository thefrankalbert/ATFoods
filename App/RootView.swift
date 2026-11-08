// App/RootView.swift
import SwiftUI
import DesignSystem
import Models
import Networking
import ATFAuth
import Home
import Capture
import Form
import Drafts
import Profile

// MARK: — Navigation state

// Class-backed navigator: mutations from any captured closure reach the same instance,
// bypassing the @State struct-copy issue in navigationDestination closures.
@MainActor @Observable final class AppNavigator {
    var homeStore: HomeStore?
    var captureStore: CaptureStore?
    var formStore: FormStore?
    var draftsStore: DraftsStore?
    var profileStore: ProfileStore?
}

// MARK: — Route

public enum ATFRoute: Hashable {
    case restaurantPicker
    case home
    case camera
    case photoPreview
    case attachDish
    case attachDraft(Draft)
    case dishForm
    case drafts
    case profile
}

private struct AppError: LocalizedError {
    let errorDescription: String?
    init(_ message: String) { errorDescription = message }
}

private enum StorageKey {
    static let hasSeenOnboarding = "hasSeenOnboarding"
    static let lastRestaurantID = "lastRestaurantID"
}

// MARK: — Root

@MainActor
struct RootView: View {
    @AppStorage(StorageKey.hasSeenOnboarding) private var hasSeenOnboarding = false
    @AppStorage(StorageKey.lastRestaurantID) private var lastRestaurantID = ""
    @State private var isRestoringSession = true
    @State private var path: [ATFRoute] = []
    @State private var toast: ATFToastData?
    @State private var toastTask: Task<Void, Never>?

    private let networking: any ATFNetworking = Env.isUITesting
        ? MockNetworking()
        : SupabaseNetworking(url: Env.supabaseURL, anonKey: Env.supabaseAnonKey)

    @State private var authStore = AuthStore()
    // AppNavigator is a class — mutations from captured closures always reach the same instance
    @State private var nav = AppNavigator()

    init() {
        // UI tests always start from a fresh install state.
        if Env.isUITesting {
            UserDefaults.standard.removeObject(forKey: StorageKey.hasSeenOnboarding)
            UserDefaults.standard.removeObject(forKey: StorageKey.lastRestaurantID)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            if !hasSeenOnboarding {
                OnboardingView { hasSeenOnboarding = true }
            } else if isRestoringSession {
                splash
            } else {
                NavigationStack(path: $path) {
                    LoginView(store: authStore, networking: networking) {
                        openRestaurant()
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
        .task { await restoreSession() }
    }

    private var splash: some View {
        VStack(spacing: 20) {
            ATFWordmark(size: 28)
            ProgressView().tint(Color.atfAccent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.atfBg.ignoresSafeArea())
    }

    // MARK: — Session

    /// Reopens the app where the user left it: same account, same restaurant.
    private func restoreSession() async {
        defer { isRestoringSession = false }
        guard let user = await networking.restoreSession() else { return }
        authStore.currentUser = user
        await authStore.loadRestaurants(networking: networking)   // failure → picker shows error + retry
        authStore.selectedRestaurant = authStore.restaurants.first { $0.id.uuidString == lastRestaurantID }
        openRestaurant()
    }

    /// After login or restore: straight to Home if a restaurant is known (or the only one), else the picker.
    private func openRestaurant() {
        if authStore.selectedRestaurant == nil, authStore.restaurants.count == 1 {
            authStore.selectedRestaurant = authStore.restaurants.first
        }
        if let restaurant = authStore.selectedRestaurant {
            lastRestaurantID = restaurant.id.uuidString
            nav.homeStore = HomeStore(restaurant: restaurant)
            path = [.home]
        } else {
            path = [.restaurantPicker]
        }
    }

    /// Clears local state; the network sign-out is done by the caller (ProfileStore shows its spinner).
    private func clearSession() {
        authStore.currentUser = nil
        authStore.selectedRestaurant = nil
        authStore.restaurants = []
        authStore.password = ""
        lastRestaurantID = ""
        nav.homeStore = nil
        nav.captureStore = nil
        nav.formStore = nil
        nav.draftsStore = nil
        nav.profileStore = nil
        path = []
    }

    // MARK: — Route destinations

    @ViewBuilder
    private func routeView(_ route: ATFRoute) -> some View {
        switch route {
        case .restaurantPicker:
            RestaurantPickerView(
                store: authStore,
                onContinue: { openRestaurant() },
                onRetry: { await authStore.loadRestaurants(networking: networking) },
                onSignOut: {
                    Task {
                        try? await networking.signOut()
                        clearSession()
                    }
                }
            )
            .navigationBarHidden(true)

        case .home:
            if let store = nav.homeStore {
                HomeView(
                    store: store,
                    networking: networking,
                    onCamera: {
                        nav.captureStore = CaptureStore(restaurant: store.restaurant)
                        nav.formStore = nil
                        path.append(.camera)
                    },
                    onDrafts: {
                        nav.draftsStore = DraftsStore(restaurantID: store.restaurant.id)
                        path.append(.drafts)
                    },
                    onProfile: {
                        if let user = authStore.currentUser {
                            nav.profileStore = ProfileStore(user: user, restaurant: store.restaurant)
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
                    store.reset()   // rejected photo must not linger as the camera thumbnail
                    nav.formStore = nil
                    path.removeLast()
                }, onUse: {
                    path.append(.attachDish)
                })
                .navigationBarHidden(true)
            }

        case .attachDish:
            if let store = nav.captureStore {
                AttachDishView(
                    restaurant: store.restaurant,
                    networking: networking,
                    onNewDish: {
                        guard let image = store.capturedImage else { return }
                        // Dish already created in this capture session (photo upload failed): reuse that form
                        // with the current photo (it may have been cropped / whitened since). Never a duplicate.
                        // formStore is cleared on retake, new capture, draft saved and dish saved.
                        if let form = nav.formStore, form.isDishCreated, case .captured = form.photo {
                            form.photo = .captured(image)
                        } else {
                            nav.formStore = FormStore(restaurant: store.restaurant, photo: .captured(image))
                        }
                        path.append(.dishForm)
                    },
                    attach: { item in
                        guard let data = await store.capturedImage?.uploadJPEG() else {
                            throw AppError("Photo invalide. Reprends la photo.")
                        }
                        _ = try await networking.attachPhoto(imageData: data, toDishID: item.id, restaurantID: store.restaurant.id)
                    },
                    saveDraft: {
                        guard let data = await store.capturedImage?.uploadJPEG() else {
                            throw AppError("Photo invalide. Reprends la photo.")
                        }
                        _ = try await networking.saveDraft(imageData: data, restaurantID: store.restaurant.id)
                        showToast("Brouillon enregistré. Photo suivante !")
                        store.reset()
                        nav.formStore = nil
                        popTo(.camera)
                    },
                    onAttached: {
                        showToast("Photo attachée !")
                        popTo(.home)
                    },
                    onBack: { path.removeLast() }
                )
                .navigationBarHidden(true)
            }

        case .attachDraft(let draft):
            if let restaurant = nav.homeStore?.restaurant {
                AttachDishView(
                    restaurant: restaurant,
                    networking: networking,
                    onNewDish: {
                        var sameDraft = false
                        if case .draft(let previous) = nav.formStore?.photo { sameDraft = previous.id == draft.id }
                        if !(sameDraft && nav.formStore?.isDishCreated == true) {
                            nav.formStore = FormStore(restaurant: restaurant, photo: .draft(draft))
                        }
                        path.append(.dishForm)
                    },
                    attach: { item in
                        _ = try await networking.attachDraft(draft, toDishID: item.id, restaurantID: restaurant.id)
                    },
                    onAttached: {
                        showToast("Photo attachée !")
                        popTo(.drafts)
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
                        nav.formStore = nil
                        if case .draft = store.photo { popTo(.drafts) } else { popTo(.home) }
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
                    onSelect: { draft in
                        nav.formStore = nil
                        path.append(.attachDraft(draft))
                    },
                    onBack: { path.removeLast() }
                )
                .navigationBarHidden(true)
            }

        case .profile:
            if let store = nav.profileStore {
                ProfileView(
                    store: store,
                    networking: networking,
                    onSwitchRestaurant: authStore.restaurants.count > 1 ? {
                        path = [.restaurantPicker]
                    } : nil,
                    onSignOut: { clearSession() },
                    onBack: { path.removeLast() }
                )
                .navigationBarHidden(true)
            }
        }
    }

    // MARK: — Helpers

    private func showToast(_ message: String) {
        toast = ATFToastData(message)
        toastTask?.cancel()   // a newer toast restarts the timer instead of being cleared early
        toastTask = Task {
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled { toast = nil }
        }
    }

    /// Pops back to the last occurrence of `route` (Home if absent).
    private func popTo(_ route: ATFRoute) {
        if let idx = path.lastIndex(of: route) {
            path = Array(path[...idx])
        } else if let idx = path.firstIndex(of: .home) {
            path = Array(path[...idx])
        } else {
            path = [.home]
        }
    }
}
