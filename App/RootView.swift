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

// MARK: - Navigation state

// Class-backed navigator: mutations from any captured closure reach the same instance,
// bypassing the @State struct-copy issue in navigationDestination closures.
@MainActor @Observable final class AppNavigator {
    var homeStore: HomeStore?
    var captureStore: CaptureStore?
    var formStore: FormStore?          // new dish (create flow)
    var dishEditStore: FormStore?      // dish card (edit flow), independent of the create flow
    var draftsStore: DraftsStore?
    var profileStore: ProfileStore?
}

// MARK: - Route

public enum ATFRoute: Hashable {
    case restaurantPicker
    case home
    case camera
    case photoPreview
    case attachDish
    case attachDraft(Draft)
    case dishForm
    case dishEdit
    case drafts
    case profile
}

private struct AppError: UserFacingError {
    let errorDescription: String?
    init(_ message: String) { errorDescription = message }
}

private enum StorageKey {
    static let hasSeenOnboarding = "hasSeenOnboarding"
    static let lastRestaurantID = "lastRestaurantID"
}

// MARK: - Root

@MainActor
struct RootView: View {
    @AppStorage(StorageKey.hasSeenOnboarding) private var hasSeenOnboarding = false
    @AppStorage(StorageKey.lastRestaurantID) private var lastRestaurantID = ""
    @State private var isRestoringSession = true
    @State private var path: [ATFRoute] = []
    @State private var toast: ATFToastData?
    @State private var toastTask: Task<Void, Never>?

    private let networking: any ATFNetworking = {
        #if DEBUG
        if Env.isUITesting { return MockNetworking() }   // mock is not compiled in Release
        #endif
        return SupabaseNetworking(url: Env.supabaseURL, anonKey: Env.supabaseAnonKey)
    }()

    @State private var authStore = AuthStore()
    // AppNavigator is a class: mutations from captured closures always reach the same instance
    @State private var nav = AppNavigator()

    init() {
        // UI tests always start from a fresh install state.
        #if DEBUG
        if Env.isUITesting {
            UserDefaults.standard.removeObject(forKey: StorageKey.hasSeenOnboarding)
            UserDefaults.standard.removeObject(forKey: StorageKey.lastRestaurantID)
        }
        #endif
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
        // Session revoked elsewhere (password changed on the web, account removed): back to login.
        .task {
            for await _ in networking.signedOutEvents() where authStore.currentUser != nil { clearSession() }
        }
        // Native back button and back swipe change `path` without calling us: clean up here, once.
        .onChange(of: path) { old, new in leftScreens(old: old, new: new) }
    }

    private func leftScreens(old: [ATFRoute], new: [ATFRoute]) {
        if old.contains(.photoPreview), !new.contains(.photoPreview) {
            nav.captureStore?.reset()   // rejected photo must not come back on the next shot
            nav.formStore = nil
        }
        if old.last == .restaurantPicker, new.last == .profile {
            authStore.selectedRestaurant = nav.homeStore?.restaurant   // picker left without switching
        }
    }

    private var splash: some View {
        VStack(spacing: 20) {
            ATFWordmark(size: 28)
            ProgressView().tint(Color.atfAccent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.atfBg.ignoresSafeArea())
    }

    // MARK: - Session

    /// Reopens the app where the user left it: same account, same restaurant.
    private func restoreSession() async {
        defer { isRestoringSession = false }
        // The Keychain outlives an uninstall: a fresh install must not reopen the previous owner's account.
        if !hasSeenOnboarding {
            try? await networking.signOut()
            return
        }
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
        authStore.email = ""       // shared device: the next person does not see the previous account
        authStore.password = ""
        lastRestaurantID = ""
        nav.homeStore = nil
        nav.captureStore = nil
        nav.formStore = nil
        nav.dishEditStore = nil
        nav.draftsStore = nil
        nav.profileStore = nil
        path = []
    }

    // MARK: - Route destinations

    @ViewBuilder
    private func routeView(_ route: ATFRoute) -> some View {
        switch route {
        case .restaurantPicker:
            RestaurantPickerView(
                store: authStore,
                onContinue: { openRestaurant() },
                onRetry: {
                    await authStore.loadRestaurants(networking: networking)
                    // Restore after an offline start: go straight back to the last restaurant.
                    guard path == [.restaurantPicker], authStore.restaurantsError == nil else { return }
                    authStore.selectedRestaurant = authStore.restaurants.first { $0.id.uuidString == lastRestaurantID }
                    if authStore.selectedRestaurant != nil || authStore.restaurants.count == 1 { openRestaurant() }
                },
                onSignOut: {
                    Task {
                        try? await networking.signOut()
                        clearSession()
                    }
                },
                // Opened from the profile: allow going back without switching.
                canGoBack: path.count > 1
            )

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
                    },
                    onDish: { item in
                        nav.dishEditStore = FormStore(restaurant: store.restaurant, editing: item)
                        path.append(.dishEdit)
                    }
                )
                .navigationBarBackButtonHidden(true)   // Home has its own (visible) toolbar
            }

        case .camera:
            if let store = nav.captureStore {
                CameraView(store: store, onCapture: {
                    guard path.last == .camera else { return }   // capture finished after the user left the camera
                    path.append(.photoPreview)
                })
            }

        case .photoPreview:
            if let store = nav.captureStore {
                PhotoPreviewView(store: store, onRetake: {
                    path.removeLast()   // cleanup happens in leftScreen(_:), shared with the back swipe
                }, onUse: {
                    path.append(.attachDish)
                })
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
                            throw AppError("Photo illisible. Reprenez la photo.")
                        }
                        let url = try await networking.attachPhoto(imageData: data, toDishID: item.id, restaurantID: store.restaurant.id)
                        if store.targetDish != nil { nav.dishEditStore?.photoReplaced(with: url) }
                    },
                    // Batch shooting only makes sense from Home, not when replacing one dish's photo.
                    saveDraft: store.targetDish != nil ? nil : {
                        guard let data = await store.capturedImage?.uploadJPEG() else {
                            throw AppError("Photo illisible. Reprenez la photo.")
                        }
                        _ = try await networking.saveDraft(imageData: data, restaurantID: store.restaurant.id)
                        showToast("Brouillon enregistré. Photo suivante.")
                        store.reset()
                        nav.formStore = nil
                        popTo(.camera)
                    },
                    onAttached: {
                        if store.targetDish != nil {
                            showToast("Photo remplacée")
                            popTo(.dishEdit)
                        } else {
                            showToast("Photo attachée")
                            popTo(.home)
                        }
                    },
                    fixedDish: store.targetDish
                )
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
                        showToast("Photo attachée")
                        popTo(.drafts)
                    }
                )
            }

        case .dishForm:
            if let store = nav.formStore {
                DishFormView(
                    store: store,
                    networking: networking,
                    onSaved: {
                        showToast("Plat enregistré")
                        if case .draft = store.photo { popTo(.drafts) } else { popTo(.home) }
                    }
                )
            }

        case .dishEdit:
            if let store = nav.dishEditStore {
                DishFormView(
                    store: store,
                    networking: networking,
                    onSaved: {
                        showToast("Plat mis à jour")
                        popTo(.home)
                    },
                    onChangePhoto: {
                        guard let dish = store.editing else { return }
                        nav.captureStore = CaptureStore(restaurant: store.restaurant, targetDish: dish)
                        path.append(.camera)
                    }
                )
            }

        case .drafts:
            if let store = nav.draftsStore {
                DraftsView(
                    store: store,
                    networking: networking,
                    onSelect: { draft in
                        // Keep the form of a dish already created from this draft (photo attach failed): no duplicate.
                        if case .draft(let previous) = nav.formStore?.photo, previous.id == draft.id,
                           nav.formStore?.isDishCreated == true {} else { nav.formStore = nil }
                        path.append(.attachDraft(draft))
                    }
                )
            }

        case .profile:
            if let store = nav.profileStore {
                ProfileView(
                    store: store,
                    networking: networking,
                    onSwitchRestaurant: authStore.restaurants.count > 1 ? {
                        path.append(.restaurantPicker)
                    } : nil,
                    onSignOut: { clearSession() }
                )
            }
        }
    }

    // MARK: - Helpers

    private func showToast(_ message: String) {
        toast = ATFToastData(message)
        AccessibilityNotification.Announcement(message).post()   // VoiceOver hears confirmations too
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
