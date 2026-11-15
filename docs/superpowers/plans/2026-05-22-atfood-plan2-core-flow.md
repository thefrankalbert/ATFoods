# At Food iOS: Plan 2: Core Flow: Auth + Home + Capture + Form

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implémenter les 9 écrans S01, S09 : navigation, stores @Observable, maquettes pixel-perfect vs prototype. Mock data partout: wiring Supabase réel en Plan 3. Zéro warning strict concurrency après chaque tâche.

**Architecture:** App target → features [Auth, Home, Capture, Form] → core [DesignSystem, Models, Networking]. RootView (App) possède `NavigationStack<[ATFRoute]>` + toast overlay + `CaptureStore` (partagé via `.environment()`).

**Tech Stack:** Swift 6 · SwiftUI · iOS 17+ · @Observable (pas ObservableObject) · AVFoundation · Tuist 4 · `SWIFT_STRICT_CONCURRENCY = complete`

---

## Fichiers créés / modifiés dans ce plan

```
ATFood/
├── Project.swift                                       ← modifié
├── App/
│   ├── ATFoodApp.swift                                 ← modifié
│   └── RootView.swift                                  ← nouveau
└── Packages/
    ├── Core/
    │   ├── DesignSystem/Sources/DesignSystem/Components/
    │   │   ├── ATFFoodCard.swift                       ← nouveau
    │   │   └── ATFSkeleton.swift                       ← nouveau
    │   ├── Models/
    │   │   ├── Package.swift
    │   │   └── Sources/Models/
    │   │       ├── MenuItem.swift
    │   │       ├── Restaurant.swift
    │   │       └── Draft.swift
    │   └── Networking/
    │       ├── Package.swift
    │       └── Sources/Networking/
    │           ├── ATFNetworking.swift
    │           └── MockNetworking.swift
    └── Features/
        ├── Auth/
        │   ├── Package.swift
        │   └── Sources/Auth/
        │       ├── AuthStore.swift
        │       ├── OnboardingView.swift
        │       ├── LoginView.swift
        │       └── RestaurantPickerView.swift
        ├── Home/
        │   ├── Package.swift
        │   └── Sources/Home/
        │       ├── HomeStore.swift
        │       └── HomeView.swift
        ├── Capture/
        │   ├── Package.swift
        │   └── Sources/Capture/
        │       ├── CaptureStore.swift
        │       ├── CameraPreviewLayer.swift
        │       ├── CameraView.swift
        │       ├── PhotoPreviewView.swift
        │       └── AttachDishView.swift
        └── Form/
            ├── Package.swift
            └── Sources/Form/
                ├── FormStore.swift
                ├── DishFormView.swift
                └── NewCategorySheet.swift
```

---

## Task 1: Tuist: Project.swift + squelettes packages

**Files:**
- Modify: `Project.swift`
- Create: `Packages/Core/Models/Package.swift`
- Create: `Packages/Core/Networking/Package.swift`
- Create: `Packages/Features/Auth/Package.swift`
- Create: `Packages/Features/Home/Package.swift`
- Create: `Packages/Features/Capture/Package.swift`
- Create: `Packages/Features/Form/Package.swift`

- [ ] **Créer l'arborescence**

```bash
mkdir -p Packages/Core/Models/Sources/Models
mkdir -p Packages/Core/Networking/Sources/Networking
mkdir -p Packages/Features/Auth/Sources/Auth
mkdir -p Packages/Features/Home/Sources/Home
mkdir -p Packages/Features/Capture/Sources/Capture
mkdir -p Packages/Features/Form/Sources/Form
```

- [ ] **Mettre à jour `Project.swift`**

```swift
// Project.swift
import ProjectDescription

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
    ],
    settings: .settings(
        base: [
            "SWIFT_STRICT_CONCURRENCY": "complete",
            "SWIFT_VERSION": "6.0",
        ]
    ),
    targets: [
        .target(
            name: "ATFood",
            destinations: .iOS,
            product: .app,
            bundleId: "com.attable.atfood",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": .dictionary([:]),
                "NSCameraUsageDescription": .string("At Food utilise l'appareil photo pour photographier vos plats."),
                "NSPhotoLibraryUsageDescription": .string("At Food accède à votre galerie pour importer des photos de plats."),
            ]),
            sources: ["App/**"],
            dependencies: [
                .package(product: "Auth"),
                .package(product: "Home"),
                .package(product: "Capture"),
                .package(product: "Form"),
            ]
        )
    ]
)
```

- [ ] **Créer `Packages/Core/Models/Package.swift`**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Models",
    platforms: [.iOS(.v17)],
    products: [.library(name: "Models", targets: ["Models"])],
    targets: [
        .target(
            name: "Models",
            path: "Sources/Models",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
```

- [ ] **Créer `Packages/Core/Networking/Package.swift`**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Networking",
    platforms: [.iOS(.v17)],
    products: [.library(name: "Networking", targets: ["Networking"])],
    dependencies: [
        .package(path: "../Models"),
    ],
    targets: [
        .target(
            name: "Networking",
            dependencies: [.product(name: "Models", package: "Models")],
            path: "Sources/Networking",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
```

- [ ] **Créer `Packages/Features/Auth/Package.swift`**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Auth",
    platforms: [.iOS(.v17)],
    products: [.library(name: "Auth", targets: ["Auth"])],
    dependencies: [
        .package(path: "../../Core/DesignSystem"),
        .package(path: "../../Core/Models"),
        .package(path: "../../Core/Networking"),
    ],
    targets: [
        .target(
            name: "Auth",
            dependencies: [
                .product(name: "DesignSystem", package: "DesignSystem"),
                .product(name: "Models", package: "Models"),
                .product(name: "Networking", package: "Networking"),
            ],
            path: "Sources/Auth",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
```

- [ ] **Créer `Packages/Features/Home/Package.swift`**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Home",
    platforms: [.iOS(.v17)],
    products: [.library(name: "Home", targets: ["Home"])],
    dependencies: [
        .package(path: "../../Core/DesignSystem"),
        .package(path: "../../Core/Models"),
        .package(path: "../../Core/Networking"),
    ],
    targets: [
        .target(
            name: "Home",
            dependencies: [
                .product(name: "DesignSystem", package: "DesignSystem"),
                .product(name: "Models", package: "Models"),
                .product(name: "Networking", package: "Networking"),
            ],
            path: "Sources/Home",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
```

- [ ] **Créer `Packages/Features/Capture/Package.swift`**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Capture",
    platforms: [.iOS(.v17)],
    products: [.library(name: "Capture", targets: ["Capture"])],
    dependencies: [
        .package(path: "../../Core/DesignSystem"),
        .package(path: "../../Core/Models"),
        .package(path: "../../Core/Networking"),
    ],
    targets: [
        .target(
            name: "Capture",
            dependencies: [
                .product(name: "DesignSystem", package: "DesignSystem"),
                .product(name: "Models", package: "Models"),
                .product(name: "Networking", package: "Networking"),
            ],
            path: "Sources/Capture",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
```

- [ ] **Créer `Packages/Features/Form/Package.swift`**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Form",
    platforms: [.iOS(.v17)],
    products: [.library(name: "Form", targets: ["Form"])],
    dependencies: [
        .package(path: "../../Core/DesignSystem"),
        .package(path: "../../Core/Models"),
        .package(path: "../../Core/Networking"),
    ],
    targets: [
        .target(
            name: "Form",
            dependencies: [
                .product(name: "DesignSystem", package: "DesignSystem"),
                .product(name: "Models", package: "Models"),
                .product(name: "Networking", package: "Networking"),
            ],
            path: "Sources/Form",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
```

- [ ] **Créer fichiers stub pour chaque module vide**

SPM refuse de compiler un target vide. Créer un fichier minimal dans chaque module :

```swift
// Packages/Core/Models/Sources/Models/Placeholder.swift
public enum _ModelsPlaceholder {}
```

```swift
// Packages/Core/Networking/Sources/Networking/Placeholder.swift
public enum _NetworkingPlaceholder {}
```

```swift
// Packages/Features/Auth/Sources/Auth/Placeholder.swift
public enum _AuthPlaceholder {}
```

```swift
// Packages/Features/Home/Sources/Home/Placeholder.swift
public enum _HomePlaceholder {}
```

```swift
// Packages/Features/Capture/Sources/Capture/Placeholder.swift
public enum _CapturePlaceholder {}
```

```swift
// Packages/Features/Form/Sources/Form/Placeholder.swift
public enum _FormPlaceholder {}
```

- [ ] **Régénérer le projet Xcode**

```bash
tuist generate
```

- [ ] **Build check**

```bash
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Commit**

```bash
git add Project.swift Packages/Core/Models Packages/Core/Networking \
        Packages/Features/Auth Packages/Features/Home \
        Packages/Features/Capture Packages/Features/Form
git commit -m "chore: add SPM feature modules skeleton + update Tuist project"
```

---

## Task 2: Data Models: MenuItem, Restaurant, Draft

**Files:**
- Delete: `Packages/Core/Models/Sources/Models/Placeholder.swift`
- Create: `Packages/Core/Models/Sources/Models/MenuItem.swift`
- Create: `Packages/Core/Models/Sources/Models/Restaurant.swift`
- Create: `Packages/Core/Models/Sources/Models/Draft.swift`

- [ ] **Créer `MenuItem.swift`**

```swift
// Packages/Core/Models/Sources/Models/MenuItem.swift
import Foundation

public struct MenuItem: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var price: Int          // FCFA
    public var category: MenuCategory
    public var photoURL: URL?
    public var isAvailable: Bool
    public var isFeatured: Bool
    public var description: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        price: Int,
        category: MenuCategory,
        photoURL: URL? = nil,
        isAvailable: Bool = true,
        isFeatured: Bool = false,
        description: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id; self.name = name; self.price = price
        self.category = category; self.photoURL = photoURL
        self.isAvailable = isAvailable; self.isFeatured = isFeatured
        self.description = description; self.createdAt = createdAt
    }

    public var priceFormatted: String {
        let t = price / 1000
        let r = price % 1000
        if t > 0, r > 0 { return "\(t) \(String(format: "%03d", r)) FCFA" }
        if t > 0 { return "\(t) 000 FCFA" }
        return "\(price) FCFA"
    }
}

public enum MenuCategory: String, CaseIterable, Sendable, Hashable {
    case entree     = "Entrée"
    case plat       = "Plat"
    case grillades  = "Grillades"
    case specialite = "Spécialité"
    case boisson    = "Boisson"
    case dessert    = "Dessert"
    public var displayName: String { rawValue }
}

public extension MenuItem {
    static let mocks: [MenuItem] = [
        MenuItem(name: "Mafé bœuf",      price: 3800, category: .plat,
                 photoURL: URL(string: "https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=400"),
                 isFeatured: true),
        MenuItem(name: "Thieboudienne",  price: 4500, category: .plat,
                 photoURL: URL(string: "https://images.unsplash.com/photo-1547928576-b822bc410bdf?w=400")),
        MenuItem(name: "Ndolé crevettes", price: 4200, category: .specialite),
        MenuItem(name: "Brochettes mixtes", price: 2800, category: .grillades),
        MenuItem(name: "Salade maison",  price: 1500, category: .entree),
        MenuItem(name: "Jus de bissap", price: 800,  category: .boisson),
        MenuItem(name: "Koki", price: 1200, category: .specialite),
    ]
}
```

- [ ] **Créer `Restaurant.swift`**

```swift
// Packages/Core/Models/Sources/Models/Restaurant.swift
import Foundation

public struct Restaurant: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var city: String
    public var role: RestaurantRole
    public var dishCount: Int
    public var photoURL: URL?

    public init(
        id: UUID = UUID(),
        name: String,
        city: String,
        role: RestaurantRole = .owner,
        dishCount: Int = 0,
        photoURL: URL? = nil
    ) {
        self.id = id; self.name = name; self.city = city
        self.role = role; self.dishCount = dishCount; self.photoURL = photoURL
    }
}

public enum RestaurantRole: String, Sendable { case owner = "Gérant", manager = "Manager" }

public struct AppUser: Sendable {
    public let id: UUID
    public var name: String
    public var email: String
    public var plan: AppPlan
    public init(id: UUID = UUID(), name: String, email: String, plan: AppPlan = .starter) {
        self.id = id; self.name = name; self.email = email; self.plan = plan
    }
    public static let mock = AppUser(name: "Mariam", email: "mariam@chezflora.cm")
}

public enum AppPlan: String, Sendable { case starter, pro }

public extension Restaurant {
    static let mocks: [Restaurant] = [
        Restaurant(name: "Chez Flora", city: "Douala", role: .owner, dishCount: 47,
                   photoURL: URL(string: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200")),
        Restaurant(name: "Le Maquis du Port", city: "Yaoundé", role: .manager, dishCount: 23),
    ]
}
```

- [ ] **Créer `Draft.swift`**

```swift
// Packages/Core/Models/Sources/Models/Draft.swift
import Foundation

public struct Draft: Identifiable, Sendable {
    public let id: UUID
    public var photoURL: URL
    public var status: DraftStatus
    public var createdAt: Date
    public init(id: UUID = UUID(), photoURL: URL, status: DraftStatus = .pending, createdAt: Date = Date()) {
        self.id = id; self.photoURL = photoURL
        self.status = status; self.createdAt = createdAt
    }
}

public enum DraftStatus: Sendable { case pending, attached }
```

- [ ] **Build check + commit**

```bash
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | tail -3

git add Packages/Core/Models/
git commit -m "feat(models): MenuItem + Restaurant + Draft + mock data"
```

---

## Task 3: Networking: ATFNetworking protocol + MockNetworking

**Files:**
- Delete: `Packages/Core/Networking/Sources/Networking/Placeholder.swift`
- Create: `Packages/Core/Networking/Sources/Networking/ATFNetworking.swift`
- Create: `Packages/Core/Networking/Sources/Networking/MockNetworking.swift`

- [ ] **Créer `ATFNetworking.swift`**

```swift
// Packages/Core/Networking/Sources/Networking/ATFNetworking.swift
import Foundation
import Models

public protocol ATFNetworking: Sendable {
    func signIn(email: String, password: String) async throws -> AppUser
    func signOut() async throws
    func fetchRestaurants(userID: UUID) async throws -> [Restaurant]
    func fetchMenuItems(restaurantID: UUID) async throws -> [MenuItem]
    func createMenuItem(_ item: MenuItem, restaurantID: UUID) async throws -> MenuItem
    func attachPhoto(imageData: Data, toDishID dishID: UUID, restaurantID: UUID) async throws -> URL
}
```

- [ ] **Créer `MockNetworking.swift`**

```swift
// Packages/Core/Networking/Sources/Networking/MockNetworking.swift
import Foundation
import Models

public final class MockNetworking: ATFNetworking {
    public init() {}

    public func signIn(email: String, password: String) async throws -> AppUser {
        try await Task.sleep(for: .milliseconds(700))
        guard email.contains("@"), !password.isEmpty else { throw ATFError.invalidCredentials }
        return AppUser.mock
    }

    public func signOut() async throws {
        try await Task.sleep(for: .milliseconds(200))
    }

    public func fetchRestaurants(userID: UUID) async throws -> [Restaurant] {
        try await Task.sleep(for: .milliseconds(400))
        return Restaurant.mocks
    }

    public func fetchMenuItems(restaurantID: UUID) async throws -> [MenuItem] {
        try await Task.sleep(for: .milliseconds(500))
        return MenuItem.mocks
    }

    public func createMenuItem(_ item: MenuItem, restaurantID: UUID) async throws -> MenuItem {
        try await Task.sleep(for: .milliseconds(600))
        return item
    }

    public func attachPhoto(imageData: Data, toDishID dishID: UUID, restaurantID: UUID) async throws -> URL {
        try await Task.sleep(for: .milliseconds(400))
        return URL(string: "https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=400")!
    }
}

public enum ATFError: Error, LocalizedError, Sendable {
    case invalidCredentials
    case networkUnavailable

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Identifiants invalides."
        case .networkUnavailable: return "Pas de connexion réseau."
        }
    }
}
```

- [ ] **Build check + commit**

```bash
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | tail -3

git add Packages/Core/Networking/
git commit -m "feat(networking): ATFNetworking protocol + MockNetworking"
```

---

## Task 4: DesignSystem: ATFFoodCard + ATFSkeleton

**Files:**
- Create: `Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFFoodCard.swift`
- Create: `Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFSkeleton.swift`

- [ ] **Créer `ATFFoodCard.swift`**

```swift
// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFFoodCard.swift
import SwiftUI

/// Card 148×170pt pour listes horizontales de plats.
/// Prend des valeurs brutes pour garder DesignSystem sans dépendance sur Models.
public struct ATFFoodCard: View {
    let name: String
    let priceFormatted: String
    let photoURL: URL?
    let isAvailable: Bool
    let onTap: () -> Void

    public init(
        name: String,
        priceFormatted: String,
        photoURL: URL? = nil,
        isAvailable: Bool = true,
        onTap: @escaping () -> Void = {}
    ) {
        self.name = name; self.priceFormatted = priceFormatted
        self.photoURL = photoURL; self.isAvailable = isAvailable; self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                ATFAsyncImage(url: photoURL, fallback: Color(hex: "1A1410"),
                              radius: 12, height: 170, width: 148)

                // Gradient bas pour lisibilité texte
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.6)],
                    startPoint: .center, endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if !isAvailable {
                    VStack {
                        HStack {
                            Spacer()
                            ATFBadge("Indispo", kind: .soft).padding(8)
                        }
                        Spacer()
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.atfCaption)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(priceFormatted)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.75))
                }
                .padding(10)
            }
            .frame(width: 148, height: 170)
        }
        .buttonStyle(ATFScaleButtonStyle())
    }
}

#Preview("ATFFoodCard") {
    HStack(spacing: 12) {
        ATFFoodCard(
            name: "Mafé bœuf", priceFormatted: "3 800 FCFA",
            photoURL: URL(string: "https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=400")
        )
        ATFFoodCard(name: "Thieboudienne", priceFormatted: "4 500 FCFA", isAvailable: false)
        ATFFoodCard(name: "Ndolé crevettes", priceFormatted: "4 200 FCFA")
    }
    .padding()
    .background(Color.atfSurface)
}
```

- [ ] **Créer `ATFSkeleton.swift`**

```swift
// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFSkeleton.swift
import SwiftUI

public struct ATFSkeleton: View {
    let width: CGFloat?
    let height: CGFloat
    let radius: CGFloat
    @State private var phase: CGFloat = 0

    public init(width: CGFloat? = nil, height: CGFloat = 20, radius: CGFloat = 8) {
        self.width = width; self.height = height; self.radius = radius
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(Color.atfSurface2)
            .overlay(shimmer)
            .clipped()
            .frame(width: width, height: height)
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }

    private var shimmer: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, Color.white.opacity(0.45), .clear],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(width: geo.size.width * 0.55)
            .offset(x: phase * (geo.size.width + geo.size.width * 0.55) - geo.size.width * 0.55)
        }
    }
}

#Preview("ATFSkeleton") {
    VStack(alignment: .leading, spacing: 12) {
        ATFSkeleton(height: 170).frame(width: 148)
        ATFSkeleton(width: .infinity, height: 52)
        ATFSkeleton(width: 160, height: 16)
        ATFSkeleton(width: 100, height: 13)
    }
    .padding()
}
```

- [ ] **Build check + commit**

```bash
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | tail -3

git add Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFFoodCard.swift \
        Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFSkeleton.swift
git commit -m "feat(design-system): ATFFoodCard + ATFSkeleton shimmer"
```

---

## Task 5: Navigation: ATFRoute + RootView + update ATFoodApp

**Files:**
- Create: `App/RootView.swift`
- Modify: `App/ATFoodApp.swift`
- Modify: `App/ContentView.swift` → À supprimer (remplacé par RootView)

- [ ] **Créer `App/RootView.swift`**

```swift
// App/RootView.swift
import SwiftUI
import DesignSystem
import Auth
import Home
import Capture
import Form
import Models
import Networking

public enum ATFRoute: Hashable {
    case login
    case restaurantPicker
    case home
    case camera
    case photoPreview(photoID: UUID)
    case attachDish(photoID: UUID)
    case dishForm(photoID: UUID?)
}

@MainActor
struct RootView: View {
    @State private var path: [ATFRoute] = []
    @State private var toast: ATFToastData?
    @State private var authStore = AuthStore()
    @State private var captureStore = CaptureStore()
    private let networking: any ATFNetworking = MockNetworking()

    var body: some View {
        ZStack(alignment: .top) {
            NavigationStack(path: $path) {
                OnboardingView(onFinish: { path.append(.login) })
                    .navigationBarHidden(true)
                    .navigationDestination(for: ATFRoute.self) { route in
                        routeView(route)
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
        .environment(captureStore)
    }

    @ViewBuilder
    private func routeView(_ route: ATFRoute) -> some View {
        switch route {
        case .login:
            LoginView(store: authStore, networking: networking) {
                path.append(.restaurantPicker)
            }
            .navigationBarHidden(true)

        case .restaurantPicker:
            RestaurantPickerView(store: authStore, networking: networking) {
                path.append(.home)
            }
            .navigationBarHidden(true)

        case .home:
            HomeView(networking: networking, restaurant: authStore.selectedRestaurant) {
                path.append(.camera)
            }
            .navigationBarHidden(true)

        case .camera:
            CameraView { photoID in
                path.append(.photoPreview(photoID: photoID))
            }
            .navigationBarHidden(true)
            .environment(captureStore)

        case .photoPreview(let photoID):
            PhotoPreviewView(
                photoID: photoID,
                onAttach: { path.append(.attachDish(photoID: photoID)) },
                onNewDish: { path.append(.dishForm(photoID: photoID)) },
                onRetake: { path.removeLast() }
            )
            .navigationBarHidden(true)
            .environment(captureStore)

        case .attachDish(let photoID):
            AttachDishView(
                photoID: photoID,
                networking: networking,
                restaurant: authStore.selectedRestaurant
            ) { dishName in
                popToHome()
                showToast("Photo rattachée à « \(dishName) » ✓")
            }
            .navigationBarHidden(true)
            .environment(captureStore)

        case .dishForm(let photoID):
            DishFormView(
                photoID: photoID,
                networking: networking,
                restaurant: authStore.selectedRestaurant
            ) { dishName in
                popToHome()
                showToast("\(dishName) publié sur la carte ✓")
            }
            .navigationBarHidden(true)
            .environment(captureStore)
        }
    }

    private func popToHome() {
        if let idx = path.firstIndex(of: .home) {
            path = Array(path[...idx])
        } else {
            path = [.home]
        }
    }

    private func showToast(_ message: String) {
        toast = ATFToastData(message)
        Task {
            try? await Task.sleep(for: .seconds(3))
            toast = nil
        }
    }
}
```

- [ ] **Mettre à jour `App/ATFoodApp.swift`**

```swift
// App/ATFoodApp.swift
import SwiftUI

@main
struct ATFoodApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
```

- [ ] **Supprimer `App/ContentView.swift`** (remplacé par RootView + feature views)

```bash
rm "App/ContentView.swift"
```

- [ ] **Build check** (compile errors attendus jusqu'aux Tasks suivantes)

```bash
tuist generate
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | grep -E "error:|BUILD"
```

Note : des erreurs "cannot find type" sont attendues pour AuthStore, LoginView, etc. jusqu'à Tasks 6-12. Corriger seulement les erreurs liées à RootView lui-même (import manquant, syntaxe).

- [ ] **Commit (après que tout compile)**

```bash
git add App/
git commit -m "feat: RootView + ATFRoute navigation skeleton + update ATFoodApp"
```

---

## Task 6: Auth: AuthStore + LoginView (S02)

**Files:**
- Delete: `Packages/Features/Auth/Sources/Auth/Placeholder.swift`
- Create: `Packages/Features/Auth/Sources/Auth/AuthStore.swift`
- Create: `Packages/Features/Auth/Sources/Auth/LoginView.swift`

- [ ] **Créer `AuthStore.swift`**

```swift
// Packages/Features/Auth/Sources/Auth/AuthStore.swift
import SwiftUI
import Models
import Networking

@MainActor
@Observable
public final class AuthStore {
    public var email = "mariam@chezflora.cm"
    public var password = ""
    public var isLoading = false
    public var error: String?
    public var currentUser: AppUser?
    public var selectedRestaurant: Restaurant?
    public var restaurants: [Restaurant] = []

    public init() {}

    public func signIn(networking: any ATFNetworking) async {
        isLoading = true
        error = nil
        do {
            currentUser = try await networking.signIn(email: email, password: password)
            if let user = currentUser {
                restaurants = try await networking.fetchRestaurants(userID: user.id)
            }
        } catch {
            self.error = (error as? ATFError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}
```

- [ ] **Créer `LoginView.swift`**: S02

```swift
// Packages/Features/Auth/Sources/Auth/LoginView.swift
import SwiftUI
import DesignSystem

public struct LoginView: View {
    @Bindable var store: AuthStore
    let networking: any ATFNetworking
    let onSuccess: () -> Void

    public init(store: AuthStore, networking: any ATFNetworking, onSuccess: @escaping () -> Void) {
        self.store = store; self.networking = networking; self.onSuccess = onSuccess
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 72)

                // Icône app
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.atfAccent)
                        .frame(width: 72, height: 72)
                        .shadow(color: Color.atfAccent.opacity(0.45), radius: 16, y: 6)
                    ATFIconView(.fork, size: 32, color: .white)
                }

                Spacer().frame(height: 20)

                ATFWordmark(size: 32)

                Text("Vos plats, en deux gestes.")
                    .font(.atfSubhead)
                    .foregroundStyle(Color.atfText3)
                    .padding(.top, 6)

                Spacer().frame(height: 48)

                VStack(spacing: 16) {
                    ATFTextField("Adresse e-mail", text: $store.email,
                                 placeholder: "mariam@chezflora.cm",
                                 rightIcon: .user)

                    ATFTextField("Mot de passe", text: $store.password,
                                 placeholder: "••••••••",
                                 secure: true,
                                 error: store.error)

                    HStack {
                        Spacer()
                        Button("Mot de passe oublié ?") {}
                            .font(.atfSubhead)
                            .foregroundStyle(Color.atfAccent)
                    }

                    ATFButton("Se connecter", kind: .primary, fullWidth: true,
                               loading: store.isLoading) {
                        Task {
                            await store.signIn(networking: networking)
                            if store.currentUser != nil { onSuccess() }
                        }
                    }
                }

                Spacer().frame(height: 32)

                HStack(spacing: 4) {
                    Text("Pas encore À Table ?")
                        .font(.atfSubhead)
                        .foregroundStyle(Color.atfText3)
                    Button("Découvrir") {}
                        .font(.atfSubhead.weight(.semibold))
                        .foregroundStyle(Color.atfAccent)
                }

                Spacer().frame(height: 32)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.atfBg.ignoresSafeArea())
    }
}

#Preview("LoginView") {
    LoginView(store: AuthStore(), networking: MockNetworking()) {}
}
```

- [ ] **Build check + commit**

```bash
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | tail -3

git add Packages/Features/Auth/Sources/Auth/AuthStore.swift \
        Packages/Features/Auth/Sources/Auth/LoginView.swift
git commit -m "feat(auth): AuthStore + LoginView (S02)"
```

---

## Task 7: Auth: OnboardingView (S01)

**Files:**
- Create: `Packages/Features/Auth/Sources/Auth/OnboardingView.swift`

- [ ] **Créer `OnboardingView.swift`**

```swift
// Packages/Features/Auth/Sources/Auth/OnboardingView.swift
import SwiftUI
import DesignSystem

private struct Slide: Identifiable {
    let id: Int
    let imageURL: URL?
    let tag: String
    let title: String
    let titleItalic: String
    let body: String
}

private let slides: [Slide] = [
    Slide(id: 0,
          imageURL: URL(string: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800"),
          tag: "Pour les restaurateurs",
          title: "Publiez vos plats",
          titleItalic: "en 2 gestes.",
          body: "Photo, nom, prix: votre carte en ligne en moins d'une minute."),
    Slide(id: 1,
          imageURL: URL(string: "https://images.unsplash.com/photo-1547592180-85f173990554?w=800"),
          tag: "Shoot rapide",
          title: "Photographiez",
          titleItalic: "comme un pro.",
          body: "Notre cadrage automatique met vos plats en valeur."),
    Slide(id: 2,
          imageURL: URL(string: "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800"),
          tag: "Carte numérique",
          title: "Votre menu,",
          titleItalic: "toujours à jour.",
          body: "Activez ou désactivez un plat en un tap, en temps réel."),
]

public struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var currentIndex = 0
    @State private var kenBurnsScale: CGFloat = 1.0

    public init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    public var body: some View {
        ZStack {
            // Background photo + Ken Burns
            ATFAsyncImage(
                url: slides[currentIndex].imageURL,
                fallback: Color(hex: "1A0F0A"),
                radius: 0,
                height: UIScreen.main.bounds.height,
                width: UIScreen.main.bounds.width,
                overlay: false,
                contentMode: .fill
            )
            .scaleEffect(kenBurnsScale)
            .animation(.linear(duration: 8).repeatForever(autoreverses: true), value: kenBurnsScale)
            .ignoresSafeArea()
            .onAppear { kenBurnsScale = 1.08 }

            // Gradient overlays
            VStack(spacing: 0) {
                LinearGradient(colors: [.black.opacity(0.55), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 180)
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 360)
            }
            .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    ATFWordmark(size: 22, color: .white)
                    Spacer()
                    Button("Passer") { onFinish() }
                        .font(.atfSubhead)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Progress bar
                HStack(spacing: 6) {
                    ForEach(0..<3) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(i <= currentIndex ? Color.white : Color.white.opacity(0.3))
                            .frame(height: 3)
                            .animation(.easeInOut(duration: 0.3), value: currentIndex)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Slide content
                VStack(alignment: .leading, spacing: 16) {
                    // Tag pill
                    Text(slides[currentIndex].tag.uppercased())
                        .font(.atfOverline)
                        .tracking(1.0)
                        .foregroundStyle(Color.atfAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())

                    // Title
                    Group {
                        Text(slides[currentIndex].title + " ")
                            .font(.custom("InstrumentSerif-Regular", size: 42))
                        + Text(slides[currentIndex].titleItalic)
                            .font(.custom("InstrumentSerif-Italic", size: 42))
                            .foregroundColor(Color.atfAccent)
                    }
                    .foregroundStyle(.white)
                    .lineSpacing(2)

                    // Body
                    Text(slides[currentIndex].body)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.white.opacity(0.8))
                        .lineSpacing(4)

                    Spacer().frame(height: 8)

                    // Dots + CTA
                    HStack {
                        // Dots
                        HStack(spacing: 6) {
                            ForEach(0..<3) { i in
                                Circle()
                                    .fill(i == currentIndex ? Color.white : Color.white.opacity(0.3))
                                    .frame(width: i == currentIndex ? 8 : 6, height: i == currentIndex ? 8 : 6)
                                    .animation(.spring(response: 0.3), value: currentIndex)
                            }
                        }
                        Spacer()
                        // CTA
                        Button {
                            if currentIndex < 2 {
                                withAnimation(.easeInOut(duration: 0.3)) { currentIndex += 1 }
                                kenBurnsScale = 1.0
                                withAnimation(.linear(duration: 8).repeatForever(autoreverses: true)) {
                                    kenBurnsScale = 1.08
                                }
                            } else {
                                onFinish()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(currentIndex < 2 ? "Continuer" : "Commencer")
                                    .font(.atfBodyStr)
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 20))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Color.atfAccent)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(ATFScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .statusBarHidden()
    }
}

#Preview("OnboardingView") {
    OnboardingView {}
}
```

Note: `ATFScaleButtonStyle` est interne à DesignSystem: ajouter `public` dans `ATFButton.swift` si nécessaire, ou déplacer le style dans un fichier partagé interne.

- [ ] **Si erreur sur ATFScaleButtonStyle** : ouvrir `ATFButton.swift`, changer `struct ATFScaleButtonStyle` en `public struct ATFScaleButtonStyle`

- [ ] **Build check + commit**

```bash
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | tail -3

git add Packages/Features/Auth/Sources/Auth/OnboardingView.swift
git commit -m "feat(auth): OnboardingView 3 slides + Ken Burns + progress (S01)"
```

---

## Task 8: Auth: RestaurantPickerView (S03)

**Files:**
- Create: `Packages/Features/Auth/Sources/Auth/RestaurantPickerView.swift`

- [ ] **Créer `RestaurantPickerView.swift`**

```swift
// Packages/Features/Auth/Sources/Auth/RestaurantPickerView.swift
import SwiftUI
import DesignSystem
import Models

public struct RestaurantPickerView: View {
    @Bindable var store: AuthStore
    let networking: any ATFNetworking
    let onSelect: () -> Void

    public init(store: AuthStore, networking: any ATFNetworking, onSelect: @escaping () -> Void) {
        self.store = store; self.networking = networking; self.onSelect = onSelect
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 60)

                // Header
                Text("Bonjour \(store.currentUser?.name ?? "")".uppercased())
                    .atfOverlineStyle()
                    .padding(.horizontal, 24)

                Text("Choisis ton\nrestaurant.")
                    .font(.atfDisplaySm)
                    .foregroundStyle(Color.atfText1)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                Spacer().frame(height: 32)

                // Restaurant list
                VStack(spacing: 12) {
                    ForEach(store.restaurants) { resto in
                        restoCard(resto)
                            .padding(.horizontal, 24)
                    }

                    // Ajouter un établissement
                    Button {
                        // Plan 3 : flow création restaurant
                    } label: {
                        HStack {
                            ATFIconView(.plus, size: 18, color: .atfAccent)
                            Text("Ajouter un autre établissement")
                                .font(.atfBody)
                                .foregroundStyle(Color.atfAccent)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: ATFRadius.card)
                                .strokeBorder(Color.atfAccent.opacity(0.4),
                                              style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                        )
                    }
                    .padding(.horizontal, 24)
                }

                Spacer().frame(height: 100)
            }
        }
        .background(Color.atfBg.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            if let selected = store.selectedRestaurant {
                ATFButton(
                    "Continuer avec \(selected.name)",
                    kind: .primary, fullWidth: true,
                    iconRight: .chevRight
                ) { onSelect() }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color.atfBg.ignoresSafeArea())
            }
        }
        .task {
            if store.restaurants.isEmpty, let user = store.currentUser {
                store.restaurants = (try? await networking.fetchRestaurants(userID: user.id)) ?? Restaurant.mocks
            }
        }
    }

    @ViewBuilder
    private func restoCard(_ resto: Restaurant) -> some View {
        let isSelected = store.selectedRestaurant?.id == resto.id

        Button { store.selectedRestaurant = resto } label: {
            ATFCard(elevated: true) {
                HStack(spacing: 14) {
                    ATFAsyncImage(url: resto.photoURL, fallback: Color(hex: "C9551E"),
                                  radius: 10, height: 68, width: 68, overlay: false)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(resto.name).font(.atfBodyStr).foregroundStyle(Color.atfText1)
                        Text(resto.city).font(.atfSubhead).foregroundStyle(Color.atfText3)
                        HStack(spacing: 6) {
                            ATFBadge(resto.role.rawValue, kind: .soft)
                            Text("\(resto.dishCount) plats")
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundStyle(Color.atfText3)
                        }
                    }

                    Spacer()

                    if isSelected {
                        ATFIconView(.checkCircle, size: 22, color: .atfAccent)
                    }
                }
                .padding(14)
            }
        }
        .buttonStyle(.plain)
        .overlay(
            RoundedRectangle(cornerRadius: ATFRadius.card)
                .strokeBorder(isSelected ? Color.atfAccent : Color.clear, lineWidth: 1.5)
        )
        .shadow(
            color: isSelected ? Color.atfAccent.opacity(0.2) : .clear,
            radius: 10, y: 4
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview("RestaurantPickerView") {
    let store = AuthStore()
    store.currentUser = .mock
    store.restaurants = Restaurant.mocks
    store.selectedRestaurant = Restaurant.mocks[0]
    return RestaurantPickerView(store: store, networking: MockNetworking()) {}
}
```

- [ ] **Build check + commit**

```bash
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | tail -3

git add Packages/Features/Auth/Sources/Auth/RestaurantPickerView.swift
git commit -m "feat(auth): RestaurantPickerView: sélection restaurant (S03)"
```

---

## Task 9: Home: HomeStore + HomeView (S04)

**Files:**
- Delete: `Packages/Features/Home/Sources/Home/Placeholder.swift`
- Create: `Packages/Features/Home/Sources/Home/HomeStore.swift`
- Create: `Packages/Features/Home/Sources/Home/HomeView.swift`

- [ ] **Créer `HomeStore.swift`**

```swift
// Packages/Features/Home/Sources/Home/HomeStore.swift
import Foundation
import Models
import Networking

@MainActor
@Observable
public final class HomeStore {
    public var restaurant: Restaurant?
    public var recentItems: [MenuItem] = []
    public var isLoading = false
    public var totalCount = 0
    public var orphanCount = 0   // plats sans photo
    public var weekCount = 0     // nouveaux cette semaine

    public init() {}

    public func load(networking: any ATFNetworking, restaurant: Restaurant?) async {
        guard let restaurant else { return }
        self.restaurant = restaurant
        isLoading = true
        recentItems = (try? await networking.fetchMenuItems(restaurantID: restaurant.id)) ?? []
        totalCount = restaurant.dishCount
        orphanCount = recentItems.filter { $0.photoURL == nil }.count
        weekCount = 6
        isLoading = false
    }
}
```

- [ ] **Créer `HomeView.swift`**

```swift
// Packages/Features/Home/Sources/Home/HomeView.swift
import SwiftUI
import DesignSystem
import Models
import Networking

public struct HomeView: View {
    let networking: any ATFNetworking
    let restaurant: Restaurant?
    let onCamera: () -> Void

    @State private var store = HomeStore()

    public init(networking: any ATFNetworking, restaurant: Restaurant?, onCamera: @escaping () -> Void) {
        self.networking = networking; self.restaurant = restaurant; self.onCamera = onCamera
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                ctaSection
                    .padding(.horizontal, 24)
                    .padding(.top, 28)

                statsRow
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                recentSection
                    .padding(.top, 28)

                Spacer().frame(height: 40)
            }
        }
        .background(Color.atfBg.ignoresSafeArea())
        .task { await store.load(networking: networking, restaurant: restaurant) }
        .refreshable { await store.load(networking: networking, restaurant: restaurant) }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    if let url = store.restaurant?.photoURL {
                        ATFAsyncImage(url: url, fallback: Color.atfAccentMuted,
                                      radius: 8, height: 38, width: 38, overlay: false)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text((store.restaurant?.name ?? ", ").uppercased())
                            .atfOverlineStyle()
                        Text(store.restaurant?.city ?? "")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.atfText3)
                    }
                }
            }
            Spacer()
            // Avatar bouton
            Button {
                // Plan 3 → ProfileView
            } label: {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: "F97316"), Color(hex: "EA6E0A")],
                                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 38, height: 38)
                    Text(String((store.store?.currentUser?.name.prefix(1) ?? "M")))
                        .font(.atfBodyStr)
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private var ctaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                Text("Bonjour,")
                    .atfOverlineStyle()
                Text("Ta carte du jour.")
                    .font(.atfDisplaySm)
                    .foregroundStyle(Color.atfText1)
            }
            .padding(.top, 4)

            Spacer().frame(height: 4)

            // CTA principale: orange
            Button(action: onCamera) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nouvelle photo")
                            .font(.atfBodyStr)
                            .foregroundStyle(.white)
                        Text("Ajoute un plat à ta carte")
                            .font(.atfSubhead)
                            .foregroundStyle(Color.white.opacity(0.75))
                    }
                    Spacer()
                    ATFIconView(.chevRight, size: 20, color: Color.white.opacity(0.8))
                }
                .padding(20)
                .background(Color.atfAccent)
                .clipShape(RoundedRectangle(cornerRadius: ATFRadius.card))
                .shadow(color: Color.atfAccent.opacity(0.35), radius: 12, y: 4)
            }
            .buttonStyle(ATFScaleButtonStyle())

            // Shoot rapide
            Button(action: onCamera) {
                HStack(spacing: 12) {
                    ATFIconView(.scan, size: 20, color: .atfText1)
                    Text("Shoot rapide")
                        .font(.atfBody)
                        .foregroundStyle(Color.atfText1)
                    Spacer()
                    ATFIconView(.chevRight, size: 18, color: .atfText3)
                }
                .padding(16)
                .background(Color.atfSurface)
                .clipShape(RoundedRectangle(cornerRadius: ATFRadius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: ATFRadius.card)
                        .strokeBorder(Color.atfBorder, lineWidth: 1)
                )
            }
            .buttonStyle(ATFScaleButtonStyle())
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statCard(count: store.totalCount, label: "sur la carte", color: nil)
            statCard(count: store.orphanCount, label: "sans photo",
                     color: store.orphanCount > 0 ? .atfWarning : nil)
            statCard(count: store.weekCount, label: "+\(store.weekCount) semaine", color: .atfSuccess)
        }
    }

    private func statCard(count: Int, label: String, color: Color?) -> some View {
        ATFCard {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(count)")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(color ?? Color.atfText1)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.atfText3)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Derniers publiés")
                    .font(.atfHeadline)
                    .foregroundStyle(Color.atfText1)
                Spacer()
            }
            .padding(.horizontal, 24)

            if store.isLoading {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<4, id: \.self) { _ in
                            ATFSkeleton(width: 148, height: 170, radius: 12)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(store.recentItems) { item in
                            ATFFoodCard(
                                name: item.name,
                                priceFormatted: item.priceFormatted,
                                photoURL: item.photoURL,
                                isAvailable: item.isAvailable
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }

            // Badge plats sans photo
            if store.orphanCount > 0 {
                ATFCard {
                    HStack(spacing: 10) {
                        ATFIconView(.cameraSlash, size: 18, color: .atfWarning)
                        Text("\(store.orphanCount) plats sans photo")
                            .font(.atfSubhead.weight(.medium))
                            .foregroundStyle(Color.atfText1)
                        Spacer()
                        ATFIconView(.chevRight, size: 16, color: .atfText3)
                    }
                    .padding(14)
                }
                .padding(.horizontal, 24)
                .padding(.top, 4)
            }
        }
    }
}

// HomeStore reference fix for avatar: store is local, currentUser unavailable here.
// Use restaurant name initial as avatar placeholder.
private extension HomeStore {
    // Workaround: expose dummy reference for avatar initial from restaurant name
    var store: HomeStore? { self }
    var currentUser: (name: String, Void)? { nil }
}

#Preview("HomeView") {
    HomeView(
        networking: MockNetworking(),
        restaurant: Restaurant.mocks[0],
        onCamera: {}
    )
}
```

Note: L'avatar utilise l'initiale du nom de l'utilisateur. Si `HomeStore` n'a pas accès au `currentUser`, utiliser la première lettre du nom du restaurant pour le placeholder ou passer `currentUser` via `HomeView.init`.

**Alternative propre:** Ajouter `var userName: String = ""` à `HomeStore` et le remplir au `load()` depuis AuthStore transmis en paramètre, ou passer `userName: String` dans `HomeView.init`. Implémenter l'option la plus simple sans casser Swift 6.

- [ ] **Simplifier l'avatar** si la solution ci-dessus génère des erreurs :

```swift
// Dans header, remplacer l'avatar complexe par :
Button {} label: {
    ZStack {
        Circle().fill(Color.atfAccentMuted).frame(width: 38, height: 38)
        ATFIconView(.user, size: 20, color: .atfAccent)
    }
}
```

- [ ] **Build check + commit**

```bash
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | tail -3

git add Packages/Features/Home/
git commit -m "feat(home): HomeStore + HomeView avec stats + FoodCards (S04)"
```

---

## Task 10: Capture: CaptureStore + CameraPreviewLayer + CameraView (S05)

**Files:**
- Delete: `Packages/Features/Capture/Sources/Capture/Placeholder.swift`
- Create: `Packages/Features/Capture/Sources/Capture/CaptureStore.swift`
- Create: `Packages/Features/Capture/Sources/Capture/CameraPreviewLayer.swift`
- Create: `Packages/Features/Capture/Sources/Capture/CameraView.swift`

- [ ] **Créer `CaptureStore.swift`**

```swift
// Packages/Features/Capture/Sources/Capture/CaptureStore.swift
import SwiftUI
import AVFoundation

@MainActor
@Observable
public final class CaptureStore {
    // UI state
    public var flashEnabled = true
    public var quickMode = true
    public var shotCount = 0
    public var targetCount = 3
    public var isCapturing = false
    public var capturedPhotos: [UUID: UIImage] = [:]

    // AVFoundation: accès nonisolated pour session queue
    public nonisolated let session = AVCaptureSession()
    nonisolated let sessionQueue = DispatchQueue(label: "com.atfood.camera.session", qos: .userInitiated)
    nonisolated let photoOutput = AVCapturePhotoOutput()

    private var currentDevice: AVCaptureDevice?
    private var currentPosition: AVCaptureDevice.Position = .back

    public init() {}

    public func setupSession() {
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }

    nonisolated private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }

        session.commitConfiguration()
        session.startRunning()
    }

    public func startSession() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    public func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    public func flipCamera() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            let newPosition: AVCaptureDevice.Position = self.currentPosition == .back ? .front : .back
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                  let newInput = try? AVCaptureDeviceInput(device: device) else { return }

            self.session.beginConfiguration()
            if let current = self.session.inputs.first { self.session.removeInput(current) }
            if self.session.canAddInput(newInput) { self.session.addInput(newInput) }
            self.session.commitConfiguration()

            Task { @MainActor in self.currentPosition = newPosition }
        }
    }

    public func capturePhoto() async -> UUID? {
        guard !isCapturing else { return nil }
        isCapturing = true

        return await withCheckedContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else { continuation.resume(returning: nil); return }
                let settings = AVCapturePhotoSettings()
                settings.flashMode = self.flashEnabled ? .on : .off
                let delegate = PhotoDelegate { [weak self] image in
                    guard let self, let image else { continuation.resume(returning: nil); return }
                    let photoID = UUID()
                    Task { @MainActor in
                        self.capturedPhotos[photoID] = image
                        self.shotCount += 1
                        self.isCapturing = false
                    }
                    continuation.resume(returning: photoID)
                }
                self.photoOutput.capturePhoto(with: settings, delegate: delegate)
            }
        }
    }
}

// MARK:: Photo delegate

final class PhotoDelegate: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    let completion: (UIImage?) -> Void
    init(completion: @escaping (UIImage?) -> Void) { self.completion = completion }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            completion(nil); return
        }
        completion(image)
    }
}
```

- [ ] **Créer `CameraPreviewLayer.swift`**

```swift
// Packages/Features/Capture/Sources/Capture/CameraPreviewLayer.swift
import SwiftUI
import AVFoundation

public struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession

    public init(session: AVCaptureSession) { self.session = session }

    public func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.videoPreviewLayer.connection?.videoRotationAngle = 90
        return view
    }

    public func updateUIView(_ uiView: PreviewView, context: Context) {}

    public class PreviewView: UIView {
        override public class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
```

- [ ] **Créer `CameraView.swift`**

```swift
// Packages/Features/Capture/Sources/Capture/CameraView.swift
import SwiftUI
import AVFoundation
import DesignSystem

public struct CameraView: View {
    let onCapture: (UUID) -> Void

    @Environment(CaptureStore.self) private var store
    @State private var flashOverlay = false
    @State private var focusPoint: CGPoint = .zero
    @State private var showFocus = false
    @State private var permissionDenied = false

    public init(onCapture: @escaping (UUID) -> Void) { self.onCapture = onCapture }

    public var body: some View {
        ZStack {
            // Viewfinder
            if permissionDenied {
                permissionDeniedView
            } else {
                CameraPreviewLayer(session: store.session)
                    .ignoresSafeArea()
            }

            // Flash overlay blanc
            Color.white.opacity(flashOverlay ? 0.85 : 0)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.25), value: flashOverlay)

            // Gradients haut + bas
            VStack {
                LinearGradient(colors: [.black.opacity(0.55), .clear],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 140)
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.65)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 220)
            }
            .ignoresSafeArea()

            // Focus square
            if showFocus {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.atfAccent, lineWidth: 1.5)
                    .frame(width: 70, height: 70)
                    .position(focusPoint)
                    .transition(.opacity.combined(with: .scale(scale: 1.2)))
            }

            // UI overlay
            VStack {
                topBar
                Spacer()
                centerGuides
                Spacer()
                modeStrip
                bottomBar
            }
        }
        .statusBarHidden()
        .onAppear { checkPermissionAndSetup() }
        .onDisappear { store.stopSession() }
        .onTapGesture { location in handleTap(at: location) }
    }

    private var topBar: some View {
        HStack {
            Button { /* dismiss → RootView handles via navigation */ } label: {
                ATFIconView(.x, size: 22, color: .white)
                    .padding(12)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }

            Spacer()

            // Counter pill
            Text("\(store.shotCount)/\(store.targetCount) photos")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.black.opacity(0.4))
                .clipShape(Capsule())

            Spacer()

            HStack(spacing: 12) {
                // Flash
                Button { store.flashEnabled.toggle() } label: {
                    ATFIconView(store.flashEnabled ? .flash : .flashOff, size: 22, color: .white)
                        .padding(10)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                // Flip
                Button { store.flipCamera() } label: {
                    ATFIconView(.flip, size: 22, color: .white)
                        .padding(10)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var centerGuides: some View {
        GeometryReader { geo in
            // Rule-of-thirds grid
            ZStack {
                let w = geo.size.width
                let h = geo.size.height
                // Vertical lines
                ForEach([w/3, 2*w/3], id: \.self) { x in
                    Rectangle().fill(Color.white.opacity(0.15)).frame(width: 1).offset(x: x - w/2)
                }
                // Horizontal lines
                ForEach([h/3, 2*h/3], id: \.self) { y in
                    Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1).offset(y: y - h/2)
                }
                // Corner brackets
                cornerBrackets(in: geo.size)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func cornerBrackets(in size: CGSize) -> some View {
        let len: CGFloat = 24
        let thick: CGFloat = 2
        let pad: CGFloat = 28
        return ZStack {
            ForEach([true, false], id: \.self) { top in
                ForEach([true, false], id: \.self) { left in
                    let x: CGFloat = left ? pad : size.width - pad
                    let y: CGFloat = top ? pad : size.height - pad
                    let hX: CGFloat = left ? x + len : x - len
                    let vY: CGFloat = top ? y + len : y - len
                    Path { p in
                        p.move(to: CGPoint(x: hX, y: y))
                        p.addLine(to: CGPoint(x: x, y: y))
                        p.addLine(to: CGPoint(x: x, y: vY))
                    }
                    .stroke(Color.white.opacity(0.6), lineWidth: thick)
                }
            }
        }
    }

    private var modeStrip: some View {
        HStack(spacing: 28) {
            ForEach(["1 plat", "Photo", "Shoot rapide"], id: \.self) { mode in
                let isActive = mode == (store.quickMode ? "Shoot rapide" : "Photo")
                VStack(spacing: 4) {
                    Text(mode)
                        .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                        .foregroundStyle(isActive ? .white : Color.white.opacity(0.5))
                    Circle()
                        .fill(isActive ? Color.atfAccent : Color.clear)
                        .frame(width: 5, height: 5)
                }
                .onTapGesture {
                    store.quickMode = mode == "Shoot rapide"
                }
            }
        }
        .padding(.bottom, 12)
    }

    private var bottomBar: some View {
        HStack {
            // Galerie thumb (placeholder)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.15))
                .frame(width: 50, height: 50)
                .overlay(ATFIconView(.download, size: 20, color: .white))

            Spacer()

            // Shutter
            Button {
                Task { await shutter() }
            } label: {
                ZStack {
                    Circle().strokeBorder(Color.white, lineWidth: 3).frame(width: 80, height: 80)
                    Circle().fill(Color.white.opacity(store.isCapturing ? 0.4 : 1))
                        .frame(width: 64, height: 64)
                }
                .scaleEffect(store.isCapturing ? 0.92 : 1)
                .animation(.easeInOut(duration: 0.12), value: store.isCapturing)
            }
            .disabled(store.isCapturing)

            Spacer()

            // Terminer (quick mode)
            if store.quickMode {
                Button("Terminer") {
                    // Retour RootView avec dernière photo si capturée
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.2))
                .clipShape(Capsule())
            } else {
                Spacer().frame(width: 50)
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 32)
    }

    private var permissionDeniedView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                ATFIconView(.cameraSlash, size: 42, color: .atfText3)
                Text("Accès caméra requis")
                    .font(.atfHeadline).foregroundStyle(.white)
                Text("Activer dans Réglages → At Food → Caméra")
                    .font(.atfSubhead).foregroundStyle(Color.atfText3)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
        }
    }

    private func shutter() async {
        // Flash animation (indépendant du flash physique)
        withAnimation { flashOverlay = true }
        try? await Task.sleep(for: .milliseconds(250))
        withAnimation { flashOverlay = false }

        if let photoID = await store.capturePhoto() {
            onCapture(photoID)
        }
    }

    private func handleTap(at location: CGPoint) {
        focusPoint = location
        withAnimation(.easeIn(duration: 0.15)) { showFocus = true }
        Task {
            try? await Task.sleep(for: .milliseconds(800))
            withAnimation(.easeOut(duration: 0.3)) { showFocus = false }
        }
    }

    private func checkPermissionAndSetup() {
        Task {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .authorized:
                store.setupSession()
            case .notDetermined:
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                if granted { store.setupSession() } else { permissionDenied = true }
            default:
                permissionDenied = true
            }
        }
    }
}

#Preview("CameraView: Simulateur") {
    // La caméra ne fonctionne pas sur simulateur: affiche l'UI sans viewfinder
    CameraView { _ in }
        .environment(CaptureStore())
}
```

- [ ] **Build check + commit**

```bash
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | tail -3

git add Packages/Features/Capture/Sources/Capture/CaptureStore.swift \
        Packages/Features/Capture/Sources/Capture/CameraPreviewLayer.swift \
        Packages/Features/Capture/Sources/Capture/CameraView.swift
git commit -m "feat(capture): CaptureStore + CameraPreviewLayer + CameraView (S05)"
```

---

## Task 11: Capture: PhotoPreviewView (S06) + AttachDishView (S07)

**Files:**
- Create: `Packages/Features/Capture/Sources/Capture/PhotoPreviewView.swift`
- Create: `Packages/Features/Capture/Sources/Capture/AttachDishView.swift`

- [ ] **Créer `PhotoPreviewView.swift`**

```swift
// Packages/Features/Capture/Sources/Capture/PhotoPreviewView.swift
import SwiftUI
import DesignSystem

public struct PhotoPreviewView: View {
    let photoID: UUID
    let onAttach: () -> Void
    let onNewDish: () -> Void
    let onRetake: () -> Void

    @Environment(CaptureStore.self) private var store

    public init(photoID: UUID, onAttach: @escaping () -> Void,
                onNewDish: @escaping () -> Void, onRetake: @escaping () -> Void) {
        self.photoID = photoID; self.onAttach = onAttach
        self.onNewDish = onNewDish; self.onRetake = onRetake
    }

    private var image: UIImage? { store.capturedPhotos[photoID] }

    public var body: some View {
        ZStack {
            Color(hex: "0a0805").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: onRetake) {
                        ATFIconView(.chevLeft, size: 22, color: .white).padding(8)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Circle().fill(Color.atfSuccess).frame(width: 7, height: 7)
                        Text("PHOTO PRÊTE · 4:5 · 1,8 Mo")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())

                    Spacer()

                    Button {} label: {
                        ATFIconView(.more, size: 22, color: .white).padding(8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer().frame(height: 24)

                // Photo
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: UIScreen.main.bounds.height * 0.5)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .padding(.horizontal, 16)
                } else {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.white.opacity(0.08))
                        .frame(maxWidth: .infinity)
                        .frame(height: UIScreen.main.bounds.height * 0.5)
                        .padding(.horizontal, 16)
                        .overlay(ATFIconView(.camera, size: 40, color: .white.opacity(0.3)))
                }

                Spacer()

                // Action panel
                VStack(spacing: 0) {
                    // Handle
                    Capsule().fill(Color.atfText3.opacity(0.4))
                        .frame(width: 36, height: 5).padding(.top, 12).padding(.bottom, 16)

                    Text("Que faire avec cette photo ?".uppercased())
                        .atfOverlineStyle()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24).padding(.bottom, 16)

                    VStack(spacing: 10) {
                        actionRow(icon: .tag, title: "Rattacher à un plat",
                                  subtitle: "3 plats sans photo", color: .atfAccent,
                                  action: onAttach)
                        actionRow(icon: .plus, title: "Créer nouveau plat",
                                  subtitle: nil, color: nil, action: onNewDish)
                        actionRow(icon: .sparkles, title: "Retoucher avec l'IA",
                                  subtitle: nil, color: nil,
                                  badge: ATFBadge("Pro", kind: .pro, icon: .star),
                                  action: {})
                    }
                    .padding(.horizontal, 24)

                    Button("Reprendre la photo", action: onRetake)
                        .font(.atfSubhead)
                        .foregroundStyle(Color.atfText3)
                        .padding(.vertical, 20)
                }
                .background(Color.atfBg.clipShape(
                    RoundedRectangle(cornerRadius: 28)).ignoresSafeArea(edges: .bottom))
            }
        }
        .statusBarHidden()
    }

    private func actionRow(icon: ATFIcon, title: String, subtitle: String?,
                           color: Color?, badge: ATFBadge? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color?.opacity(0.12) ?? Color.atfSurface2)
                        .frame(width: 42, height: 42)
                    ATFIconView(icon, size: 20, color: color ?? .atfText1)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.atfBody).foregroundStyle(Color.atfText1)
                    if let subtitle {
                        Text(subtitle).font(.atfCaption).foregroundStyle(Color.atfText3)
                    }
                }
                Spacer()
                if let badge { badge }
                ATFIconView(.chevRight, size: 18, color: .atfText3)
            }
            .padding(14)
            .background(Color.atfSurface)
            .clipShape(RoundedRectangle(cornerRadius: ATFRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: ATFRadius.card)
                    .strokeBorder(Color.atfBorder, lineWidth: 1)
            )
        }
        .buttonStyle(ATFScaleButtonStyle())
    }
}

#Preview("PhotoPreviewView") {
    PhotoPreviewView(photoID: UUID(), onAttach: {}, onNewDish: {}, onRetake: {})
        .environment(CaptureStore())
}
```

- [ ] **Créer `AttachDishView.swift`**

```swift
// Packages/Features/Capture/Sources/Capture/AttachDishView.swift
import SwiftUI
import DesignSystem
import Models
import Networking

public struct AttachDishView: View {
    let photoID: UUID
    let networking: any ATFNetworking
    let restaurant: Restaurant?
    let onAttached: (String) -> Void

    @State private var searchText = ""
    @State private var selectedFilter: String = "Tous"
    @State private var items: [MenuItem] = []
    @State private var isLoading = true

    @Environment(CaptureStore.self) private var store

    public init(photoID: UUID, networking: any ATFNetworking,
                restaurant: Restaurant?, onAttached: @escaping (String) -> Void) {
        self.photoID = photoID; self.networking = networking
        self.restaurant = restaurant; self.onAttached = onAttached
    }

    private var orphans: [MenuItem] { items.filter { $0.photoURL == nil } }
    private var filters: [String] { ["Sans photo · \(orphans.count)", "Tous · \(items.count)"] +
        MenuCategory.allCases.prefix(4).map(\.displayName) }

    private var filtered: [MenuItem] {
        let base: [MenuItem]
        if selectedFilter.hasPrefix("Sans photo") { base = orphans }
        else if selectedFilter.hasPrefix("Tous") { base = items }
        else { base = items.filter { $0.category.displayName == selectedFilter } }
        if searchText.isEmpty { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Nav
            HStack {
                Button {} label: {
                    HStack(spacing: 4) {
                        ATFIconView(.chevLeft, size: 18, color: .atfAccent)
                        Text("Aperçu").font(.atfSubhead).foregroundStyle(Color.atfAccent)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 24).padding(.top, 8).padding(.bottom, 4)

            Text("Choisir un plat.")
                .font(.atfDisplaySm).foregroundStyle(Color.atfText1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24).padding(.bottom, 16)

            // Search
            ATFTextField(text: $searchText, placeholder: "Rechercher un plat…",
                         rightIcon: .search)
                .padding(.horizontal, 24).padding(.bottom, 12)

            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filters, id: \.self) { f in
                        ATFChip(f, selected: selectedFilter == f, tap: true) { selectedFilter = f }
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 16)

            // List
            if isLoading {
                VStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { _ in
                        HStack(spacing: 12) {
                            ATFSkeleton(width: 54, height: 54, radius: 10)
                            VStack(alignment: .leading, spacing: 6) {
                                ATFSkeleton(width: 140, height: 14)
                                ATFSkeleton(width: 80, height: 12)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                    }
                }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if !orphans.isEmpty && selectedFilter.hasPrefix("Sans") {
                            Text("Plats sans photo · \(orphans.count)")
                                .atfOverlineStyle()
                                .padding(.horizontal, 24).padding(.vertical, 12)
                        }

                        ForEach(filtered) { item in
                            itemRow(item)
                                .padding(.horizontal, 24)
                            Divider().padding(.horizontal, 24)
                        }
                    }
                }
            }
        }
        .background(Color.atfBg.ignoresSafeArea())
        .task {
            if let rid = restaurant?.id {
                items = (try? await networking.fetchMenuItems(restaurantID: rid)) ?? MenuItem.mocks
            } else {
                items = MenuItem.mocks
            }
            isLoading = false
            selectedFilter = "Sans photo · \(items.filter { $0.photoURL == nil }.count)"
        }
    }

    private func itemRow(_ item: MenuItem) -> some View {
        Button {
            Task {
                if let img = store.capturedPhotos[photoID],
                   let data = img.jpegData(compressionQuality: 0.85),
                   let rid = restaurant?.id {
                    _ = try? await networking.attachPhoto(imageData: data, toDishID: item.id, restaurantID: rid)
                }
                onAttached(item.name)
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(item.photoURL == nil ? Color.atfWarningBg : Color.atfSurface2)
                        .frame(width: 54, height: 54)
                    if item.photoURL == nil {
                        ATFIconView(.cameraSlash, size: 22, color: .atfWarning)
                    } else {
                        ATFAsyncImage(url: item.photoURL, fallback: Color.atfSurface2,
                                      radius: 10, height: 54, width: 54, overlay: false)
                    }
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name).font(.atfBody).foregroundStyle(Color.atfText1)
                    HStack(spacing: 6) {
                        Text(item.priceFormatted)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.atfText3)
                        Text("·").foregroundStyle(Color.atfText3)
                        Text(item.category.displayName)
                            .font(.atfCaption).foregroundStyle(Color.atfText3)
                    }
                }
                Spacer()
                ATFIconView(.chevRight, size: 18, color: .atfText3)
            }
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

#Preview("AttachDishView") {
    AttachDishView(photoID: UUID(), networking: MockNetworking(),
                   restaurant: Restaurant.mocks[0]) { _ in }
        .environment(CaptureStore())
}
```

- [ ] **Build check + commit**

```bash
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | tail -3

git add Packages/Features/Capture/Sources/Capture/PhotoPreviewView.swift \
        Packages/Features/Capture/Sources/Capture/AttachDishView.swift
git commit -m "feat(capture): PhotoPreviewView (S06) + AttachDishView (S07)"
```

---

## Task 12: Form: FormStore + DishFormView (S08)

**Files:**
- Delete: `Packages/Features/Form/Sources/Form/Placeholder.swift`
- Create: `Packages/Features/Form/Sources/Form/FormStore.swift`
- Create: `Packages/Features/Form/Sources/Form/DishFormView.swift`

- [ ] **Créer `FormStore.swift`**

```swift
// Packages/Features/Form/Sources/Form/FormStore.swift
import Foundation
import Models
import Networking

@MainActor
@Observable
public final class FormStore {
    public var name = ""
    public var priceRaw = ""
    public var category: MenuCategory?
    public var isAvailable = true
    public var isFeatured = false
    public var description = ""
    public var isPublishing = false
    public var priceError: String?

    public var price: Int? { Int(priceRaw.filter(\.isNumber)) }

    public var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        price != nil && (price ?? 0) > 0 &&
        category != nil
    }

    public init() {}

    public func publish(photoData: Data?, networking: any ATFNetworking,
                        restaurantID: UUID?) async throws -> MenuItem {
        guard isValid, let price, let category else {
            throw ATFError.invalidCredentials
        }
        isPublishing = true
        defer { isPublishing = false }

        var item = MenuItem(name: name, price: price, category: category,
                           isAvailable: isAvailable, isFeatured: isFeatured,
                           description: description)
        item = try await networking.createMenuItem(item, restaurantID: restaurantID ?? UUID())

        if let data = photoData, let rid = restaurantID {
            let url = try await networking.attachPhoto(imageData: data, toDishID: item.id, restaurantID: rid)
            item.photoURL = url
        }
        return item
    }
}
```

- [ ] **Créer `DishFormView.swift`**

```swift
// Packages/Features/Form/Sources/Form/DishFormView.swift
import SwiftUI
import DesignSystem
import Models
import Networking

public struct DishFormView: View {
    let photoID: UUID?
    let networking: any ATFNetworking
    let restaurant: Restaurant?
    let onPublished: (String) -> Void

    @State private var store = FormStore()
    @State private var showNewCategory = false
    @Environment(CaptureStore.self) private var captureStore

    public init(photoID: UUID?, networking: any ATFNetworking,
                restaurant: Restaurant?, onPublished: @escaping (String) -> Void) {
        self.photoID = photoID; self.networking = networking
        self.restaurant = restaurant; self.onPublished = onPublished
    }

    private var photo: UIImage? {
        guard let id = photoID else { return nil }
        return captureStore.capturedPhotos[id]
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Nav bar
            ZStack {
                HStack {
                    ATFButton("Annuler", kind: .ghost) { /* dismiss */ }
                    Spacer()
                }
                Text("Nouveau plat")
                    .font(.atfBodyStr).foregroundStyle(Color.atfText1)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(Color.atfBg)
            .overlay(Divider(), alignment: .bottom)

            ScrollView {
                VStack(spacing: 0) {
                    // Photo header
                    photoHeader

                    VStack(alignment: .leading, spacing: 24) {
                        // Essentiel
                        sectionHeader("L'essentiel")

                        ATFTextField("Nom du plat *", text: $store.name,
                                     placeholder: "Ex: Mafé bœuf")

                        ATFTextField("Prix *", text: $store.priceRaw,
                                     placeholder: "3 800", suffix: "FCFA",
                                     error: store.priceError)
                            .keyboardType(.numberPad)
                            .onChange(of: store.priceRaw) { _, new in
                                let n = new.filter(\.isNumber)
                                if n != new { store.priceRaw = n }
                                store.priceError = (!n.isEmpty && Int(n) == nil) ? "Prix invalide" : nil
                            }

                        // Catégorie
                        VStack(alignment: .leading, spacing: 10) {
                            sectionHeader("Catégorie *")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(MenuCategory.allCases, id: \.self) { cat in
                                        ATFChip(cat.displayName,
                                                selected: store.category == cat) {
                                            store.category = cat
                                        }
                                    }
                                    ATFChip("Créer", icon: .plus, kind: .add) {
                                        showNewCategory = true
                                    }
                                }
                            }
                        }

                        Divider()

                        // Carte
                        ATFCard {
                            HStack {
                                Text("Carte principale")
                                    .font(.atfBody).foregroundStyle(Color.atfText1)
                                Spacer()
                                ATFIconView(.chevRight, size: 18, color: .atfText3)
                            }
                            .padding(16)
                        }

                        // Description
                        sectionHeader("Description")
                        ATFTextField(text: $store.description,
                                     placeholder: "Décris le plat, les ingrédients…",
                                     multiline: true,
                                     hint: "\(store.description.count)/500")

                        // Affichage toggles
                        ATFCard {
                            VStack(spacing: 0) {
                                toggleRow("Disponible aujourd'hui", isOn: $store.isAvailable, orange: false)
                                Divider().padding(.horizontal, 16)
                                toggleRow("Mis en avant sur l'accueil", isOn: $store.isFeatured, orange: true)
                            }
                        }

                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
            }

            // CTA sticky
            VStack(spacing: 0) {
                Divider()
                ATFButton("Publier le plat", kind: .primary, fullWidth: true,
                          loading: store.isPublishing,
                          disabled: !store.isValid) {
                    Task {
                        let photoData = photo?.jpegData(compressionQuality: 0.85)
                        if let item = try? await store.publish(
                            photoData: photoData, networking: networking,
                            restaurantID: restaurant?.id
                        ) {
                            onPublished(item.name)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color.atfBg.ignoresSafeArea())
            }
        }
        .background(Color.atfBg.ignoresSafeArea())
        .atfSheet(isPresented: $showNewCategory, detents: [.medium]) {
            NewCategorySheet(isPresented: $showNewCategory)
        }
    }

    private var photoHeader: some View {
        ZStack(alignment: .bottomTrailing) {
            if let image = photo {
                Image(uiImage: image)
                    .resizable().scaledToFill()
                    .frame(maxWidth: .infinity).frame(height: 200)
                    .clipped()
            } else {
                Color.atfSurface.frame(height: 200)
                    .overlay(ATFIconView(.camera, size: 36, color: .atfText3))
            }

            // Overlays
            HStack {
                Text("PHOTO · 4:5")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
                Spacer()
                ATFButton("Reprendre", kind: .secondary) { /* back to camera */ }
            }
            .padding(12)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.atfHeadline)
            .foregroundStyle(Color.atfText1)
    }

    private func toggleRow(_ label: String, isOn: Binding<Bool>, orange: Bool) -> some View {
        HStack {
            Text(label).font(.atfBody).foregroundStyle(Color.atfText1)
            Spacer()
            ATFToggle(isOn: isOn, orange: orange)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}

#Preview("DishFormView") {
    DishFormView(photoID: nil, networking: MockNetworking(),
                 restaurant: Restaurant.mocks[0]) { _ in }
        .environment(CaptureStore())
}
```

- [ ] **Build check + commit**

```bash
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | tail -3

git add Packages/Features/Form/Sources/Form/FormStore.swift \
        Packages/Features/Form/Sources/Form/DishFormView.swift
git commit -m "feat(form): FormStore + DishFormView publish flow (S08)"
```

---

## Task 13: Form: NewCategorySheet (S09)

**Files:**
- Create: `Packages/Features/Form/Sources/Form/NewCategorySheet.swift`

- [ ] **Créer `NewCategorySheet.swift`**

```swift
// Packages/Features/Form/Sources/Form/NewCategorySheet.swift
import SwiftUI
import DesignSystem

private let iconChoices: [ATFIcon] = [
    .fork, .tag, .star, .flash, .sparkles, .bell, .globe, .coins,
    .camera, .search, .trash, .info, .user, .settings, .tray, .history,
]

private enum PrepType: String, CaseIterable {
    case cuisine = "Cuisine"
    case bar     = "Bar"
    case both    = "Les deux"
}

public struct NewCategorySheet: View {
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var selectedIcon: ATFIcon? = .fork
    @State private var prepType: PrepType = .cuisine
    @State private var highlight = false

    public init(isPresented: Binding<Bool>) { self._isPresented = isPresented }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Nouvelle catégorie.")
                    .font(.atfDisplaySm).foregroundStyle(Color.atfText1)
                    .padding(.top, 4)

                ATFTextField("Nom *", text: $name, placeholder: "Ex: Grillades",
                             hint: "\(name.count)/32")

                // Icônes
                VStack(alignment: .leading, spacing: 12) {
                    Text("Icône").font(.atfCaption).foregroundStyle(Color.atfText2)
                    LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 10), count: 4),
                              spacing: 10) {
                        ForEach(iconChoices, id: \.self) { icon in
                            let selected = selectedIcon == icon
                            Button { selectedIcon = icon } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selected ? Color.atfAccent : Color.atfSurface2)
                                        .frame(height: 56)
                                    ATFIconView(icon, size: 22,
                                                color: selected ? .white : .atfText2)
                                }
                            }
                            .buttonStyle(ATFScaleButtonStyle())
                        }
                    }
                }

                // Préparation
                VStack(alignment: .leading, spacing: 10) {
                    Text("Préparation").font(.atfCaption).foregroundStyle(Color.atfText2)
                    HStack(spacing: 8) {
                        ForEach(PrepType.allCases, id: \.self) { type in
                            ATFChip(type.rawValue, selected: prepType == type) { prepType = type }
                        }
                    }
                }

                // Toggle mise en avant
                ATFCard {
                    HStack {
                        Text("Mettre en avant sur l'accueil")
                            .font(.atfBody).foregroundStyle(Color.atfText1)
                        Spacer()
                        ATFToggle(isOn: $highlight, orange: true)
                    }
                    .padding(16)
                }

                Spacer().frame(height: 8)

                ATFButton("Créer la catégorie", kind: .primary, fullWidth: true,
                          disabled: name.trimmingCharacters(in: .whitespaces).isEmpty) {
                    // Plan 3 : persister via networking
                    isPresented = false
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

#Preview("NewCategorySheet") {
    @Previewable @State var show = true
    return Color.gray.opacity(0.3)
        .atfSheet(isPresented: $show, detents: [.medium, .large]) {
            NewCategorySheet(isPresented: $show)
        }
}
```

- [ ] **Build check**

```bash
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Commit**

```bash
git add Packages/Features/Form/Sources/Form/NewCategorySheet.swift
git commit -m "feat(form): NewCategorySheet: création catégorie (S09)"
```

---

## Task 14: Validation finale: full flow build + smoke

- [ ] **Build release propre**

```bash
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -configuration Release \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | tail -10
```

Expected: `** BUILD SUCCEEDED **`: 0 error, 0 strict-concurrency warning.

- [ ] **Vérifier SwiftUI Previews** dans Xcode pour chaque écran :
  - `OnboardingView`: 3 slides, fond photo, Ken Burns visible
  - `LoginView`: champ email pré-rempli, bouton orange
  - `RestaurantPickerView`: 2 cards, sélection accent
  - `HomeView`: stats row, FoodCards horizontaux, CTA orange
  - `CameraView`: UI caméra (viewfinder gris sur simulateur)
  - `PhotoPreviewView`: fond sombre, panel bas 3 actions
  - `AttachDishView`: chips filtres, liste plats
  - `DishFormView`: photo top, champs, toggles, CTA sticky
  - `NewCategorySheet`: grille icônes, chips, toggle

- [ ] **Commit final**

```bash
git add .
git commit -m "feat: Plan 2 complet: S01, S09 Auth + Home + Capture + Form"
```

---

## Critères de sortie Plan 2

- [ ] `xcodebuild -configuration Release build` → `BUILD SUCCEEDED` 0 warning strict concurrency
- [ ] Flow complet sur simulateur : Onboarding → Login → RestaurantPicker → Home
- [ ] Navigation retour fonctionne partout (chevron haut gauche)
- [ ] `DishFormView` CTA "Publier le plat" disabled si nom/prix/catégorie vide
- [ ] Toast apparaît en haut après attachement ou publication, disparaît en 3s
- [ ] SwiftUI Previews : tous les écrans prévisualisables sans crash

**Prochaine étape → Plan 3 :** `2026-05-22-atfood-plan3-drafts-ai-profile.md`: Drafts (S10) + AIRetouch (S11, S13) + Profile (S14, S16) + wiring Supabase réel
