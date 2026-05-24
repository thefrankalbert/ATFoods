# At Food iOS — Plan 1: Foundation + DesignSystem

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Créer le projet Xcode (Tuist), la structure SPM multi-modules, et le package `DesignSystem` complet avec tous les tokens et composants, validés par SwiftUI Previews pixel-perfect vs le prototype.

**Architecture:** Tuist 4 génère le `.xcodeproj`. Chaque feature est un local Swift Package dans `Packages/`. Le package `DesignSystem` exporte tokens (couleurs, typo, radius), composants (`ATFButton`, `ATFTextField`, `ATFChip`, `ATFToggle`, `ATFBadge`, `ATFCard`, `ATFSheet`, `ATFToast`, `ATFAsyncImage`), `ATFIcon` enum SF Symbols, et `ATFWordmark`.

**Tech Stack:** Swift 6 · SwiftUI · iOS 17+ · Tuist 4 · Swift Testing · `SWIFT_STRICT_CONCURRENCY = complete`

---

## Fichiers créés dans ce plan

```
ATFood/
├── Tuist/
│   └── Project.swift
├── App/
│   ├── ATFoodApp.swift
│   └── ContentView.swift            ← placeholder rouge (remplacé Plan 2)
├── Packages/
│   └── Core/
│       └── DesignSystem/
│           ├── Package.swift
│           ├── Resources/
│           │   ├── InstrumentSerif-Regular.ttf
│           │   └── InstrumentSerif-Italic.ttf
│           └── Sources/DesignSystem/
│               ├── Tokens/
│               │   ├── ATFColors.swift
│               │   ├── ATFTypography.swift
│               │   └── ATFRadius.swift
│               ├── Icons/
│               │   └── ATFIcon.swift
│               ├── Wordmark/
│               │   └── ATFWordmark.swift
│               └── Components/
│                   ├── ATFButton.swift
│                   ├── ATFTextField.swift
│                   ├── ATFChip.swift
│                   ├── ATFToggle.swift
│                   ├── ATFBadge.swift
│                   ├── ATFCard.swift
│                   ├── ATFSheet.swift
│                   ├── ATFToast.swift
│                   └── ATFAsyncImage.swift
```

---

## Task 1: Installer Tuist + créer le projet

**Files:**
- Create: `Tuist/Project.swift`
- Create: `App/ATFoodApp.swift`
- Create: `App/ContentView.swift`

- [ ] **Vérifier que Tuist est installé**

```bash
tuist version
```
Si absent :
```bash
curl -Ls https://install.tuist.io | bash
# ou
mise install tuist
```
Expected output: `4.x.x`

- [ ] **Initialiser le projet depuis le répertoire ATFoods**

```bash
cd "/Users/a.g.i.c/Documents/SAAS Ressources 26/Project App-Saas/ATFoods"
tuist init --name ATFood --platform ios
```

Cela génère `Tuist/`, `Project.swift`, `ATFood/` — on va modifier la structure.

- [ ] **Remplacer `Project.swift` par la config correcte**

```swift
// Tuist/Project.swift
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
                .package(product: "DesignSystem"),
            ]
        )
    ]
)
```

- [ ] **Créer `App/ATFoodApp.swift`**

```swift
// App/ATFoodApp.swift
import SwiftUI

@main
struct ATFoodApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

- [ ] **Créer `App/ContentView.swift` (placeholder)**

```swift
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
```

- [ ] **Générer le projet Xcode**

```bash
cd "/Users/a.g.i.c/Documents/SAAS Ressources 26/Project App-Saas/ATFoods"
tuist generate
```

Expected: `ATFood.xcworkspace` généré sans erreur.

- [ ] **Vérifier que ça compile**

```bash
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Commit**

```bash
git init
git add Tuist/ App/
git commit -m "chore: tuist project skeleton + placeholder ContentView"
```

---

## Task 2: Créer le package DesignSystem

**Files:**
- Create: `Packages/Core/DesignSystem/Package.swift`

- [ ] **Créer la structure de répertoires**

```bash
mkdir -p Packages/Core/DesignSystem/Sources/DesignSystem/Tokens
mkdir -p Packages/Core/DesignSystem/Sources/DesignSystem/Icons
mkdir -p Packages/Core/DesignSystem/Sources/DesignSystem/Wordmark
mkdir -p Packages/Core/DesignSystem/Sources/DesignSystem/Components
mkdir -p Packages/Core/DesignSystem/Resources
mkdir -p Packages/Core/DesignSystem/Tests/DesignSystemTests
```

- [ ] **Créer `Package.swift`**

```swift
// Packages/Core/DesignSystem/Package.swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DesignSystem",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
    ],
    targets: [
        .target(
            name: "DesignSystem",
            path: "Sources/DesignSystem",
            resources: [
                .process("../../Resources"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem"],
            path: "Tests/DesignSystemTests"
        ),
    ]
)
```

- [ ] **Télécharger les fonts Instrument Serif**

Va sur https://fonts.google.com/specimen/Instrument+Serif → Download family.  
Copier `InstrumentSerif-Regular.ttf` et `InstrumentSerif-Italic.ttf` dans `Packages/Core/DesignSystem/Resources/`.

- [ ] **Régénérer avec Tuist pour inclure le package**

```bash
tuist generate
```

- [ ] **Vérifier compilation avec package vide**

```bash
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Commit**

```bash
git add Packages/
git commit -m "chore: add DesignSystem SPM package skeleton + Instrument Serif fonts"
```

---

## Task 3: Tokens — Couleurs

**Files:**
- Create: `Packages/Core/DesignSystem/Sources/DesignSystem/Tokens/ATFColors.swift`

- [ ] **Créer le helper `Color(hex:)`**

```swift
// Packages/Core/DesignSystem/Sources/DesignSystem/Tokens/ATFColors.swift
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - ATF Design Tokens

public extension Color {
    // Accent
    static let atfAccent      = Color(hex: "F97316")
    static let atfAccentHover = Color(hex: "EA6E0A")
    static let atfAccentMuted = Color(hex: "F97316").opacity(0.12)
    static let atfAccentOn    = Color.white

    // Surfaces — light (default)
    static let atfBg          = Color(hex: "FFFFFF")
    static let atfSurface     = Color(hex: "F7F7F7")
    static let atfSurface2    = Color(hex: "EFEFEF")
    static let atfBorder      = Color.black.opacity(0.08)
    static let atfBorderStr   = Color.black.opacity(0.14)
    static let atfText1       = Color(hex: "0A0A0A")
    static let atfText2       = Color(hex: "535353")
    static let atfText3       = Color(hex: "9A9A9A")
    static let atfOverlay     = Color.black.opacity(0.32)

    // Semantic
    static let atfSuccess     = Color(hex: "16A34A")
    static let atfSuccessBg   = Color(hex: "16A34A").opacity(0.12)
    static let atfWarning     = Color(hex: "EAB308")
    static let atfWarningBg   = Color(hex: "EAB308").opacity(0.14)
    static let atfDanger      = Color(hex: "DC2626")
    static let atfDangerBg    = Color(hex: "DC2626").opacity(0.12)
}

// MARK: - Dark mode adaptive tokens

public extension ShapeStyle where Self == Color {
    // Used as: .foregroundStyle(.atfAdaptive(.atfText1, dark: .atfText1Dark))
}

// Adaptive color helper — usage: Color.atfAdaptive(light: .atfBg, dark: .atfBgDark)
public extension Color {
    static func atfAdaptive(light: Color, dark: Color) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }

    // Dark surface tokens
    static let atfBgDark       = Color(hex: "0E0E0E")
    static let atfSurfaceDark  = Color(hex: "1A1A1A")
    static let atfSurface2Dark = Color(hex: "252525")
    static let atfText1Dark    = Color(hex: "FAFAFA")
    static let atfText2Dark    = Color(hex: "A1A1A1")
    static let atfText3Dark    = Color(hex: "6B6B6B")
}
```

- [ ] **Créer le test de compilation des couleurs**

```swift
// Packages/Core/DesignSystem/Tests/DesignSystemTests/ATFColorsTests.swift
import Testing
import SwiftUI
@testable import DesignSystem

@Suite("ATFColors")
struct ATFColorsTests {
    @Test("hex initializer parses F97316 to orange")
    func hexParserOrange() {
        let c = Color(hex: "F97316")
        let ui = UIColor(c)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(abs(r - 0.976) < 0.01)
        #expect(abs(g - 0.451) < 0.01)
        #expect(abs(b - 0.086) < 0.01)
    }

    @Test("atfAccent is non-clear")
    func accentNonClear() {
        let ui = UIColor(Color.atfAccent)
        var a: CGFloat = 0
        ui.getWhite(nil, alpha: &a)
        #expect(a == 1.0)
    }
}
```

- [ ] **Lancer les tests**

```bash
xcodebuild test \
  -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  2>&1 | grep -E "Test|PASS|FAIL|error:"
```

Expected: `Test Suite 'ATFColorsTests' passed`

- [ ] **Commit**

```bash
git add Packages/Core/DesignSystem/Sources/DesignSystem/Tokens/ATFColors.swift \
        Packages/Core/DesignSystem/Tests/
git commit -m "feat(design-system): ATFColors tokens + hex initializer"
```

---

## Task 4: Tokens — Typographie + Radius

**Files:**
- Create: `Packages/Core/DesignSystem/Sources/DesignSystem/Tokens/ATFTypography.swift`
- Create: `Packages/Core/DesignSystem/Sources/DesignSystem/Tokens/ATFRadius.swift`

- [ ] **Créer `ATFTypography.swift`**

```swift
// Packages/Core/DesignSystem/Sources/DesignSystem/Tokens/ATFTypography.swift
import SwiftUI

public extension Font {
    // Display — Instrument Serif
    static let atfDisplay: Font = {
        if let _ = UIFont(name: "InstrumentSerif-Regular", size: 34) {
            return .custom("InstrumentSerif-Regular", size: 34)
        }
        return .system(size: 34, weight: .light, design: .serif)
    }()

    static let atfDisplaySm: Font = {
        if let _ = UIFont(name: "InstrumentSerif-Regular", size: 28) {
            return .custom("InstrumentSerif-Regular", size: 28)
        }
        return .system(size: 28, weight: .light, design: .serif)
    }()

    static let atfTitle: Font = {
        if let _ = UIFont(name: "InstrumentSerif-Regular", size: 24) {
            return .custom("InstrumentSerif-Regular", size: 24)
        }
        return .system(size: 24, weight: .light, design: .serif)
    }()

    static let atfDisplayItalic: Font = {
        if let _ = UIFont(name: "InstrumentSerif-Italic", size: 34) {
            return .custom("InstrumentSerif-Italic", size: 34)
        }
        return .system(size: 34, weight: .light, design: .serif).italic()
    }()

    static let atfDisplaySmItalic: Font = {
        if let _ = UIFont(name: "InstrumentSerif-Italic", size: 28) {
            return .custom("InstrumentSerif-Italic", size: 28)
        }
        return .system(size: 28, weight: .light, design: .serif).italic()
    }()

    // System — Inter via -apple-system
    static let atfHeadline  = Font.system(size: 20, weight: .semibold)
    static let atfBody      = Font.system(size: 17, weight: .regular)
    static let atfBodyStr   = Font.system(size: 17, weight: .semibold)
    static let atfSubhead   = Font.system(size: 15, weight: .regular)
    static let atfCaption   = Font.system(size: 13, weight: .medium)
    static let atfOverline  = Font.system(size: 11, weight: .semibold)
    static let atfMono      = Font.system(size: 15, weight: .medium, design: .monospaced)
}

// Convenience modifier for overline style (uppercase + tracking)
public struct ATFOverlineModifier: ViewModifier {
    public init() {}
    public func body(content: Content) -> some View {
        content
            .font(.atfOverline)
            .textCase(.uppercase)
            .tracking(1.0)
            .foregroundStyle(Color.atfText3)
    }
}

public extension View {
    func atfOverlineStyle() -> some View {
        modifier(ATFOverlineModifier())
    }
}
```

- [ ] **Créer `ATFRadius.swift`**

```swift
// Packages/Core/DesignSystem/Sources/DesignSystem/Tokens/ATFRadius.swift
import CoreFoundation

public enum ATFRadius {
    public static let input:  CGFloat = 8
    public static let card:   CGFloat = 14
    public static let pill:   CGFloat = 9999
    public static let modal:  CGFloat = 20
    public static let chip:   CGFloat = 9999
}
```

- [ ] **Build check**

```bash
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | tail -3
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Commit**

```bash
git add Packages/Core/DesignSystem/Sources/DesignSystem/Tokens/
git commit -m "feat(design-system): typography + radius tokens"
```

---

## Task 5: ATFIcon

**Files:**
- Create: `Packages/Core/DesignSystem/Sources/DesignSystem/Icons/ATFIcon.swift`

- [ ] **Créer `ATFIcon.swift`**

```swift
// Packages/Core/DesignSystem/Sources/DesignSystem/Icons/ATFIcon.swift
import SwiftUI

public enum ATFIcon: String, CaseIterable, Sendable {
    case camera      = "camera"
    case cameraFill  = "camera.fill"
    case cameraSlash = "camera.slash"
    case plus        = "plus"
    case minus       = "minus"
    case check       = "checkmark"
    case checkCircle = "checkmark.circle"
    case x           = "xmark"
    case xCircle     = "xmark.circle"
    case chevRight   = "chevron.right"
    case chevLeft    = "chevron.left"
    case chevDown    = "chevron.down"
    case chevUp      = "chevron.up"
    case search      = "magnifyingglass"
    case user        = "person"
    case userCircle  = "person.circle"
    case settings    = "gearshape"
    case sparkles    = "sparkles"
    case fork        = "fork.knife"
    case tag         = "tag"
    case tray        = "tray"
    case upRight     = "arrow.up.forward.circle"
    case alert       = "exclamationmark.triangle"
    case reload      = "arrow.clockwise.circle"
    case wifiSlash   = "wifi.slash"
    case flash       = "bolt.fill"
    case flashOff    = "bolt.slash.fill"
    case flip        = "arrow.triangle.2.circlepath.camera"
    case arrowLeft   = "arrow.left"
    case bell        = "bell"
    case trash       = "trash"
    case drag        = "line.3.horizontal"
    case more        = "ellipsis"
    case faceId      = "faceid"
    case globe       = "globe"
    case bug         = "ant"
    case info        = "info.circle"
    case out         = "arrow.right.square"
    case star        = "star.fill"
    case coins       = "dollarsign.circle"
    case history     = "clock.arrow.circlepath"
    case filter      = "line.3.horizontal.decrease.circle"
    case scan        = "viewfinder"
    case download    = "arrow.down"
    case pencil      = "pencil"
    case shieldCheck = "checkmark.shield"

    public var systemName: String { rawValue }
}

// MARK: - ATFIconView

public struct ATFIconView: View {
    let icon: ATFIcon
    let size: CGFloat
    let color: Color?

    public init(_ icon: ATFIcon, size: CGFloat = 22, color: Color? = nil) {
        self.icon = icon
        self.size = size
        self.color = color
    }

    public var body: some View {
        Image(systemName: icon.systemName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(color ?? Color.primary)
    }
}

// MARK: - Preview

#Preview("ATFIcon grid") {
    let icons: [ATFIcon] = [.camera, .cameraFill, .plus, .check, .x, .chevRight,
                             .search, .user, .settings, .sparkles, .fork, .tag,
                             .flash, .flashOff, .trash, .star, .bell, .more]
    return ScrollView {
        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 16) {
            ForEach(icons, id: \.self) { icon in
                VStack(spacing: 4) {
                    ATFIconView(icon, size: 24, color: .atfAccent)
                    Text(icon.rawValue)
                        .font(.system(size: 7))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}
```

- [ ] **Build check**

```bash
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | tail -3
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Commit**

```bash
git add Packages/Core/DesignSystem/Sources/DesignSystem/Icons/
git commit -m "feat(design-system): ATFIcon SF Symbols enum + ATFIconView"
```

---

## Task 6: ATFWordmark

**Files:**
- Create: `Packages/Core/DesignSystem/Sources/DesignSystem/Wordmark/ATFWordmark.swift`

- [ ] **Créer `ATFWordmark.swift`**

```swift
// Packages/Core/DesignSystem/Sources/DesignSystem/Wordmark/ATFWordmark.swift
import SwiftUI

/// Logo "Atfood" avec point orange.
/// Usage: ATFWordmark(size: 22)  |  ATFWordmark(size: 18, color: .white)
public struct ATFWordmark: View {
    let size: CGFloat
    let color: Color
    let showDot: Bool

    public init(size: CGFloat = 22, color: Color = .primary, showDot: Bool = true) {
        self.size = size
        self.color = color
        self.showDot = showDot
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("At")
                .font(.custom("InstrumentSerif-Regular", size: size))
                .foregroundStyle(color)
            Text("food")
                .font(.custom("InstrumentSerif-Italic", size: size * 0.95))
                .foregroundStyle(color)
            if showDot {
                Circle()
                    .fill(Color.atfAccent)
                    .frame(width: size * 0.16, height: size * 0.16)
                    .offset(y: -size * 0.12)
                    .padding(.leading, 2)
            }
        }
    }
}

#Preview("ATFWordmark") {
    VStack(spacing: 24) {
        ATFWordmark(size: 32)
        ATFWordmark(size: 22)
        ATFWordmark(size: 18, color: .white)
            .padding()
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .padding()
}
```

- [ ] **Commit**

```bash
git add Packages/Core/DesignSystem/Sources/DesignSystem/Wordmark/
git commit -m "feat(design-system): ATFWordmark logo component"
```

---

## Task 7: ATFButton

**Files:**
- Create: `Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFButton.swift`

- [ ] **Créer `ATFButton.swift`**

```swift
// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFButton.swift
import SwiftUI

public enum ATFButtonKind {
    case primary, outline, ghost, secondary, danger
}

public struct ATFButton: View {
    let label: String
    let kind: ATFButtonKind
    let isFullWidth: Bool
    let isLoading: Bool
    let isDisabled: Bool
    let icon: ATFIcon?
    let iconRight: ATFIcon?
    let action: () -> Void

    public init(
        _ label: String,
        kind: ATFButtonKind = .primary,
        fullWidth: Bool = false,
        loading: Bool = false,
        disabled: Bool = false,
        icon: ATFIcon? = nil,
        iconRight: ATFIcon? = nil,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.kind = kind
        self.isFullWidth = fullWidth
        self.isLoading = loading
        self.isDisabled = disabled
        self.icon = icon
        self.iconRight = iconRight
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                        .scaleEffect(0.8)
                } else if let icon {
                    ATFIconView(icon, size: 18, color: foregroundColor)
                }
                Text(label)
                    .font(kind == .secondary ? .atfSubhead.weight(.medium) : .atfBodyStr)
                if let iconRight {
                    ATFIconView(iconRight, size: 18, color: foregroundColor)
                }
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: kind == .secondary ? 48 : 56)
            .padding(.horizontal, kind == .secondary ? 20 : 24)
            .background(background)
            .foregroundStyle(foregroundColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(borderColor, lineWidth: kind == .outline ? 1.5 : 0)
            )
        }
        .opacity(isDisabled || isLoading ? 0.5 : 1)
        .disabled(isDisabled || isLoading)
        .buttonStyle(ATFScaleButtonStyle())
    }

    private var background: AnyShapeStyle {
        switch kind {
        case .primary:  return AnyShapeStyle(Color.atfAccent)
        case .danger:   return AnyShapeStyle(Color.atfDanger)
        case .secondary: return AnyShapeStyle(Color.atfSurface)
        case .outline, .ghost: return AnyShapeStyle(Color.clear)
        }
    }

    private var foregroundColor: Color {
        switch kind {
        case .primary, .danger: return .white
        case .outline, .ghost:  return .atfAccent
        case .secondary:        return .atfText1
        }
    }

    private var borderColor: Color {
        kind == .outline ? .atfAccent : .clear
    }
}

// Scale press animation — matches prototype `.atf-btn:active { transform: scale(.96) }`
struct ATFScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeInOut(duration: 0.18), value: configuration.isPressed)
    }
}

#Preview("ATFButton variants") {
    VStack(spacing: 12) {
        ATFButton("Se connecter", kind: .primary, fullWidth: true) {}
        ATFButton("Découvrir", kind: .outline, fullWidth: true) {}
        ATFButton("Annuler", kind: .ghost) {}
        ATFButton("Shoot rapide", kind: .secondary, icon: .scan) {}
        ATFButton("Supprimer", kind: .danger, fullWidth: true) {}
        ATFButton("Chargement…", kind: .primary, fullWidth: true, loading: true) {}
        ATFButton("Désactivé", kind: .primary, fullWidth: true, disabled: true) {}
    }
    .padding()
}
```

- [ ] **Build check**

```bash
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | tail -3
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Commit**

```bash
git add Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFButton.swift
git commit -m "feat(design-system): ATFButton (primary/outline/ghost/secondary/danger + loading)"
```

---

## Task 8: ATFTextField

**Files:**
- Create: `Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFTextField.swift`

- [ ] **Créer `ATFTextField.swift`**

```swift
// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFTextField.swift
import SwiftUI

public struct ATFTextField: View {
    let label: String?
    @Binding var text: String
    let placeholder: String
    let isMultiline: Bool
    let suffix: String?
    let error: String?
    let hint: String?
    let isSecure: Bool
    let rightIcon: ATFIcon?

    @FocusState private var isFocused: Bool

    public init(
        _ label: String? = nil,
        text: Binding<String>,
        placeholder: String = "",
        multiline: Bool = false,
        suffix: String? = nil,
        error: String? = nil,
        hint: String? = nil,
        secure: Bool = false,
        rightIcon: ATFIcon? = nil
    ) {
        self.label = label
        self._text = text
        self.placeholder = placeholder
        self.isMultiline = multiline
        self.suffix = suffix
        self.error = error
        self.hint = hint
        self.isSecure = secure
        self.rightIcon = rightIcon
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let label {
                Text(label)
                    .font(.atfCaption)
                    .foregroundStyle(Color.atfText2)
                    .padding(.leading, 4)
            }

            ZStack(alignment: .trailing) {
                Group {
                    if isMultiline {
                        TextEditor(text: $text)
                            .frame(minHeight: 96)
                            .padding(14)
                            .scrollContentBackground(.hidden)
                    } else if isSecure {
                        SecureField(placeholder, text: $text)
                            .padding(.horizontal, 14)
                            .padding(.trailing, suffix != nil ? 56 : 14)
                    } else {
                        TextField(placeholder, text: $text)
                            .padding(.horizontal, 14)
                            .padding(.trailing, suffix != nil ? 56 : (rightIcon != nil ? 44 : 14))
                    }
                }
                .frame(height: isMultiline ? nil : 52)
                .font(.atfBody)
                .foregroundStyle(Color.atfText1)
                .background(Color.atfSurface)
                .clipShape(RoundedRectangle(cornerRadius: ATFRadius.input))
                .overlay(
                    RoundedRectangle(cornerRadius: ATFRadius.input)
                        .strokeBorder(
                            error != nil ? Color.atfDanger :
                            isFocused ? Color.atfAccent :
                            Color.atfBorder,
                            lineWidth: 1
                        )
                )
                .focused($isFocused)

                if let suffix {
                    Text(suffix)
                        .font(.atfMono.size(14))
                        .foregroundStyle(Color.atfText3)
                        .padding(.trailing, 14)
                }
                if let rightIcon {
                    ATFIconView(rightIcon, size: 18, color: .atfText3)
                        .padding(.trailing, 10)
                }
            }

            if let error {
                HStack(spacing: 4) {
                    ATFIconView(.alert, size: 12, color: .atfDanger)
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.atfDanger)
                }
                .padding(.leading, 4)
            } else if let hint {
                Text(hint)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.atfText3)
                    .padding(.leading, 4)
            }
        }
    }
}

private extension Font {
    func size(_ s: CGFloat) -> Font { .system(size: s, weight: .medium, design: .monospaced) }
}

#Preview("ATFTextField") {
    @Previewable @State var email = "mariam@chezflora.cm"
    @Previewable @State var pass = ""
    @Previewable @State var price = "3800"
    @Previewable @State var desc = ""

    return VStack(spacing: 16) {
        ATFTextField("Adresse e-mail", text: $email, placeholder: "mariam@chezflora.cm")
        ATFTextField("Mot de passe", text: $pass, placeholder: "••••••••", secure: true,
                     error: "Identifiants invalides")
        ATFTextField("Prix *", text: $price, placeholder: "3 800", suffix: "FCFA")
        ATFTextField("Description", text: $desc,
                     placeholder: "Décris le plat…", multiline: true,
                     hint: "\(desc.count)/500")
    }
    .padding()
}
```

- [ ] **Build + commit**

```bash
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | tail -3

git add Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFTextField.swift
git commit -m "feat(design-system): ATFTextField (input, secure, multiline, suffix, error)"
```

---

## Task 9: ATFToggle

**Files:**
- Create: `Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFToggle.swift`

- [ ] **Créer `ATFToggle.swift`**

```swift
// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFToggle.swift
import SwiftUI

/// iOS-style custom toggle. orange=true → accent orange au lieu de success vert.
public struct ATFToggle: View {
    @Binding var isOn: Bool
    let isOrange: Bool

    public init(isOn: Binding<Bool>, orange: Bool = false) {
        self._isOn = isOn
        self.isOrange = orange
    }

    public var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            RoundedRectangle(cornerRadius: ATFRadius.pill)
                .fill(isOn ? (isOrange ? Color.atfAccent : Color.atfSuccess) : Color.atfSurface2)
                .frame(width: 51, height: 31)
                .overlay(
                    RoundedRectangle(cornerRadius: ATFRadius.pill)
                        .strokeBorder(Color.atfBorder, lineWidth: 1)
                )

            Circle()
                .fill(Color.white)
                .frame(width: 25, height: 25)
                .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
                .padding(2)
        }
        .frame(width: 51, height: 31)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isOn)
        .onTapGesture { isOn.toggle() }
    }
}

#Preview("ATFToggle") {
    @Previewable @State var a = true
    @Previewable @State var b = false
    @Previewable @State var c = true

    return VStack(spacing: 24) {
        HStack { Text("Disponible (vert)"); Spacer(); ATFToggle(isOn: $a) }
        HStack { Text("Mis en avant (orange)"); Spacer(); ATFToggle(isOn: $b, orange: true) }
        HStack { Text("Off"); Spacer(); ATFToggle(isOn: $c) }
    }
    .padding()
}
```

- [ ] **Build + commit**

```bash
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | tail -3

git add Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFToggle.swift
git commit -m "feat(design-system): ATFToggle iOS-style (vert/orange)"
```

---

## Task 10: ATFChip + ATFBadge

**Files:**
- Create: `Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFChip.swift`
- Create: `Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFBadge.swift`

- [ ] **Créer `ATFChip.swift`**

```swift
// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFChip.swift
import SwiftUI

public enum ATFChipKind { case `default`, add }

public struct ATFChip: View {
    let label: String
    let icon: ATFIcon?
    let isSelected: Bool
    let kind: ATFChipKind
    let isTap: Bool
    let action: () -> Void

    public init(
        _ label: String,
        icon: ATFIcon? = nil,
        selected: Bool = false,
        kind: ATFChipKind = .default,
        tap: Bool = false,
        action: @escaping () -> Void = {}
    ) {
        self.label = label
        self.icon = icon
        self.isSelected = selected
        self.kind = kind
        self.isTap = tap
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    ATFIconView(icon, size: 14,
                                color: isSelected ? .white :
                                       kind == .add ? .atfAccent : .atfText1)
                }
                Text(label)
                    .font(isTap ? .system(size: 12, weight: .medium) : .system(size: 14, weight: .medium))
            }
            .padding(.horizontal, isTap ? 10 : 14)
            .frame(height: isTap ? 28 : 36)
            .background(chipBackground)
            .foregroundStyle(chipForeground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(chipBorder, lineWidth: 1)
            )
        }
        .buttonStyle(ATFScaleButtonStyle())
        .fixedSize()
    }

    private var chipBackground: Color {
        if isSelected { return .atfAccent }
        if kind == .add { return .clear }
        return .atfSurface
    }

    private var chipForeground: Color {
        if isSelected { return .white }
        if kind == .add { return .atfAccent }
        return .atfText1
    }

    private var chipBorder: Color {
        if isSelected { return .atfAccent }
        if kind == .add { return Color.atfAccent.opacity(0.6) }
        return .atfBorder
    }
}

#Preview("ATFChip") {
    @Previewable @State var sel = "plat"
    let cats = ["Entrée", "Plat", "Grillades", "Spécialité"]

    return ScrollView(.horizontal) {
        HStack(spacing: 8) {
            ATFChip("Sans photo · 3", icon: .cameraSlash, selected: true) {}
            ForEach(cats, id: \.self) { c in
                ATFChip(c, selected: sel == c.lowercased()) { sel = c.lowercased() }
            }
            ATFChip("Créer", icon: .plus, kind: .add) {}
        }
        .padding()
    }
}
```

- [ ] **Créer `ATFBadge.swift`**

```swift
// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFBadge.swift
import SwiftUI

public enum ATFBadgeKind { case pro, pending, attached, danger, soft }

public struct ATFBadge: View {
    let label: String
    let kind: ATFBadgeKind
    let icon: ATFIcon?

    public init(_ label: String, kind: ATFBadgeKind = .soft, icon: ATFIcon? = nil) {
        self.label = label
        self.kind = kind
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let icon {
                ATFIconView(icon, size: 10, color: foreground)
            }
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.3)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(background)
        .foregroundStyle(foreground)
        .clipShape(Capsule())
    }

    private var background: AnyShapeStyle {
        switch kind {
        case .pro:      return AnyShapeStyle(LinearGradient(colors: [Color(hex: "F5D76E"), Color(hex: "D4AF37")], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .pending:  return AnyShapeStyle(Color.atfWarningBg)
        case .attached: return AnyShapeStyle(Color.atfSuccessBg)
        case .danger:   return AnyShapeStyle(Color.atfDangerBg)
        case .soft:     return AnyShapeStyle(Color.atfSurface2)
        }
    }

    private var foreground: Color {
        switch kind {
        case .pro:      return Color(hex: "4A3500")
        case .pending:  return Color(hex: "92660A")
        case .attached: return .atfSuccess
        case .danger:   return .atfDanger
        case .soft:     return .atfText2
        }
    }
}

#Preview("ATFBadge") {
    HStack(spacing: 8) {
        ATFBadge("Pro", kind: .pro, icon: .star)
        ATFBadge("En attente", kind: .pending)
        ATFBadge("Rattaché", kind: .attached)
        ATFBadge("Erreur", kind: .danger)
        ATFBadge("Manager", kind: .soft)
    }
    .padding()
}
```

- [ ] **Build + commit**

```bash
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | tail -3

git add Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFChip.swift \
        Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFBadge.swift
git commit -m "feat(design-system): ATFChip + ATFBadge"
```

---

## Task 11: ATFCard + ATFSheet

**Files:**
- Create: `Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFCard.swift`
- Create: `Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFSheet.swift`

- [ ] **Créer `ATFCard.swift`**

```swift
// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFCard.swift
import SwiftUI

public struct ATFCard<Content: View>: View {
    let isElevated: Bool
    let content: () -> Content

    public init(elevated: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.isElevated = elevated
        self.content = content
    }

    public var body: some View {
        content()
            .background(isElevated ? Color.atfBg : Color.atfSurface)
            .clipShape(RoundedRectangle(cornerRadius: ATFRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: ATFRadius.card)
                    .strokeBorder(Color.atfBorder, lineWidth: 1)
            )
            .shadow(
                color: isElevated ? Color.black.opacity(0.04) : .clear,
                radius: 7, x: 0, y: 2
            )
    }
}

#Preview("ATFCard") {
    VStack(spacing: 12) {
        ATFCard {
            Text("Surface card").padding()
        }
        ATFCard(elevated: true) {
            Text("Elevated card").padding()
        }
    }
    .padding()
}
```

- [ ] **Créer `ATFSheet.swift`**

```swift
// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFSheet.swift
import SwiftUI

/// Wrapper pour présenter du contenu en bottom sheet avec grab handle.
/// Utilise .presentationDetents natif iOS 16+.
public struct ATFSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let detents: Set<PresentationDetent>
    let sheetContent: () -> SheetContent

    public func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                VStack(spacing: 0) {
                    // Grab handle
                    Capsule()
                        .fill(Color.atfText3.opacity(0.4))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)
                        .padding(.bottom, 14)

                    sheetContent()
                }
                .presentationDetents(detents)
                .presentationDragIndicator(.hidden)
                .background(Color.atfBg)
            }
    }
}

public extension View {
    func atfSheet<Content: View>(
        isPresented: Binding<Bool>,
        detents: Set<PresentationDetent> = [.medium],
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(ATFSheetModifier(isPresented: isPresented, detents: detents, sheetContent: content))
    }
}
```

- [ ] **Build + commit**

```bash
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | tail -3

git add Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFCard.swift \
        Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFSheet.swift
git commit -m "feat(design-system): ATFCard + ATFSheet modifier"
```

---

## Task 12: ATFToast + ATFAsyncImage

**Files:**
- Create: `Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFToast.swift`
- Create: `Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFAsyncImage.swift`

- [ ] **Créer `ATFToast.swift`**

```swift
// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFToast.swift
import SwiftUI

public struct ATFToastData: Equatable, Sendable {
    public let message: String
    public let kind: Kind

    public enum Kind: Sendable { case success, warning, info }

    public init(_ message: String, kind: Kind = .success) {
        self.message = message
        self.kind = kind
    }
}

/// Overlay global — placer dans le ZStack racine.
/// Usage: .atfToast(toast: $toastData)
public struct ATFToastOverlay: View {
    let toast: ATFToastData?

    public init(toast: ATFToastData?) {
        self.toast = toast
    }

    public var body: some View {
        if let toast {
            HStack(spacing: 10) {
                Circle()
                    .fill(toast.kind == .success ? Color.atfSuccess : Color.atfWarning)
                    .frame(width: 6, height: 6)
                Text(toast.message)
                    .font(.atfSubhead.weight(.medium))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.atfText1)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.2), radius: 16, y: 6)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

#Preview("ATFToast") {
    ZStack(alignment: .top) {
        Color.gray.opacity(0.1).ignoresSafeArea()
        ATFToastOverlay(toast: ATFToastData("Plat publié sur la carte ✓"))
            .padding(.top, 64)
    }
}
```

- [ ] **Créer `ATFAsyncImage.swift`**

```swift
// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFAsyncImage.swift
import SwiftUI

/// Image asynchrone avec fallback couleur + vignette overlay optionnelle.
/// Reproduit le comportement du composant `Img` du prototype.
public struct ATFAsyncImage: View {
    let url: URL?
    let fallbackColor: Color
    let radius: CGFloat
    let height: CGFloat
    let width: CGFloat?
    let showOverlay: Bool
    let contentMode: ContentMode

    public init(
        url: URL?,
        fallback: Color = Color(hex: "1A1410"),
        radius: CGFloat = 14,
        height: CGFloat = 120,
        width: CGFloat? = nil,
        overlay: Bool = true,
        contentMode: ContentMode = .fill
    ) {
        self.url = url
        self.fallbackColor = fallback
        self.radius = radius
        self.height = height
        self.width = width
        self.showOverlay = overlay
        self.contentMode = contentMode
    }

    public var body: some View {
        ZStack {
            fallbackColor

            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                    case .failure:
                        EmptyView()
                    case .empty:
                        EmptyView()
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            if showOverlay {
                // Vignette : highlight top-left + darken bottom
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0.08), location: 0),
                        .init(color: .clear, location: 0.35),
                        .init(color: .clear, location: 0.55),
                        .init(color: .black.opacity(0.28), location: 1),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: radius))
    }
}

#Preview("ATFAsyncImage") {
    VStack(spacing: 12) {
        // Fallback (no URL)
        ATFAsyncImage(url: nil, fallback: Color(hex: "C9551E"), radius: 14, height: 160)
        // With Unsplash URL
        ATFAsyncImage(
            url: URL(string: "https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?auto=format&fit=crop&q=80&w=640&h=800"),
            fallback: Color(hex: "C9551E"),
            radius: 14,
            height: 200
        )
    }
    .padding()
}
```

- [ ] **Build + commit**

```bash
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | tail -3

git add Packages/Core/DesignSystem/Sources/DesignSystem/Components/
git commit -m "feat(design-system): ATFToast + ATFAsyncImage"
```

---

## Task 13: Export public + validation finale

**Files:**
- Modify: Vérifier tous les `public` access modifiers

- [ ] **Créer un fichier d'export central**

```swift
// Packages/Core/DesignSystem/Sources/DesignSystem/DesignSystem.swift
// Public API du package — importer DesignSystem donne accès à tout.
@_exported import SwiftUI

// Tokens
public typealias ATFColors = Color  // extensions on Color — already public
// ATFTypography: Font extensions — already public
// ATFRadius: enum — already public

// Pas d'autres re-exports nécessaires — tout est public directement.
```

- [ ] **Test de smoke — créer une Preview qui utilise tous les composants**

```swift
// Packages/Core/DesignSystem/Sources/DesignSystem/Components/DesignSystemGallery.swift
import SwiftUI

#Preview("DesignSystem Gallery") {
    @Previewable @State var text = "Mafé bœuf"
    @Previewable @State var tog = true
    @Previewable @State var sheet = false

    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            // Wordmark
            ATFWordmark(size: 28)

            // Buttons
            Group {
                ATFButton("Publier le plat", kind: .primary, fullWidth: true) {}
                ATFButton("Annuler", kind: .outline, fullWidth: true) {}
                ATFButton("Shoot rapide", kind: .secondary, icon: .scan) {}
            }

            // TextField
            ATFTextField("Nom du plat *", text: $text, placeholder: "Ex: Mafé bœuf")

            // Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ATFChip("Sans photo · 3", icon: .cameraSlash, selected: true) {}
                    ATFChip("Tous · 47") {}
                    ATFChip("Créer", icon: .plus, kind: .add) {}
                }
            }

            // Toggle
            HStack {
                Text("Disponible aujourd'hui").font(.atfBody)
                Spacer()
                ATFToggle(isOn: $tog)
            }

            // Badges
            HStack(spacing: 8) {
                ATFBadge("Pro", kind: .pro, icon: .star)
                ATFBadge("Manager", kind: .soft)
                ATFBadge("Rattaché", kind: .attached)
            }

            // Card
            ATFCard(elevated: true) {
                HStack {
                    Text("Chez Flora").font(.atfBodyStr)
                    Spacer()
                    ATFIconView(.chevRight, size: 18, color: .atfText3)
                }
                .padding()
            }

            // AsyncImage
            ATFAsyncImage(
                url: URL(string: "https://images.unsplash.com/photo-1547928576-b822bc410bdf?auto=format&fit=crop&q=80&w=640&h=800"),
                fallback: Color(hex: "A3601E"),
                radius: 16,
                height: 220
            )

            // Toast preview
            ATFToastOverlay(toast: ATFToastData("Plat publié ✓"))
                .frame(maxWidth: .infinity)

            // Sheet trigger
            ATFButton("Ouvrir sheet", kind: .secondary, fullWidth: true) { sheet = true }
                .atfSheet(isPresented: $sheet) {
                    Text("Contenu du sheet").padding()
                }
        }
        .padding()
    }
}
```

- [ ] **Build final**

```bash
xcodebuild -workspace ATFood.xcworkspace \
  -scheme ATFood \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Commit final Plan 1**

```bash
git add .
git commit -m "feat(design-system): DesignSystem package complet — tous composants + gallery preview"
```

---

## Critère de sortie Plan 1

- [ ] `xcodebuild build` → `BUILD SUCCEEDED` zéro warning strict concurrency
- [ ] SwiftUI Preview "DesignSystem Gallery" affiche tous les composants sans crash
- [ ] Comparaison visuelle : chaque composant match le prototype (couleur, radius, typo, taille)
- [ ] Fonts Instrument Serif chargées (vérifier dans Preview : "At*food*" en serif italique)

**Prochaine étape → Plan 2 :** `2026-05-21-atfood-plan2-core-flow.md` (Auth + Home + Capture + Form)
