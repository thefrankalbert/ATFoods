# At Food iOS — Spec d'implémentation v1

**Date :** 2026-05-21  
**Prototype source :** `At Food — Prototype v1 (Print).pdf` · 16 écrans · iPhone 15 Pro  
**Stack validée :** Swift 6 · SwiftUI · iOS 17+ · @Observable · SPM + Tuist · Supabase

---

## 1. Règle UX/UI — Non-négociable

> **Fidélité pixel-perfect au prototype.** Chaque composant est validé en SwiftUI Preview sur iPhone 15 Pro (393pt) avant d'être utilisé dans un écran. Aucun écran ne passe en "done" sans comparaison côte-à-côte avec la capture du prototype.

- Typographie : `Instrument Serif` (display) via bundle + `Inter` (text) via system font stack
- Accent orange : `#F97316` strict — jamais approximé
- Dark mode : `@Environment(\.colorScheme)` sur chaque token — jamais de couleur hardcodée
- Animations : durées issues du prototype (sheetUp 0.28s, fadeUp 0.45s, spin 0.8s, flash 0.25s)
- Safe area : respectée via `.safeAreaInset` et `.ignoresSafeArea` ciblés, jamais globaux

---

## 2. Design Tokens

Extraits de `tokens.css` — mappés vers Swift enums/structs dans `DesignSystem`.

### Couleurs

```swift
// ATFColors.swift
extension Color {
    // Accent
    static let atfAccent      = Color(hex: "#F97316")
    static let atfAccentHover = Color(hex: "#EA6E0A")
    static let atfAccentMuted = Color(hex: "#F97316").opacity(0.12)
    static let atfAccentOn    = Color.white

    // Light surfaces
    static let atfBg         = Color(hex: "#FFFFFF")
    static let atfSurface    = Color(hex: "#F7F7F7")
    static let atfSurface2   = Color(hex: "#EFEFEF")
    static let atfText1      = Color(hex: "#0A0A0A")
    static let atfText2      = Color(hex: "#535353")
    static let atfText3      = Color(hex: "#9A9A9A")

    // Dark surfaces (via colorScheme)
    static let atfBgDark      = Color(hex: "#0E0E0E")
    static let atfSurfaceDark = Color(hex: "#1A1A1A")
    // etc.

    // Semantic
    static let atfSuccess     = Color(hex: "#16A34A")
    static let atfWarning     = Color(hex: "#EAB308")
    static let atfDanger      = Color(hex: "#DC2626")
}
```

### Typographie

```swift
// ATFTypography.swift
extension Font {
    static let atfDisplay   = Font.custom("InstrumentSerif-Regular", size: 34)
    static let atfDisplaySm = Font.custom("InstrumentSerif-Regular", size: 28)
    static let atfTitle     = Font.custom("InstrumentSerif-Regular", size: 24)
    static let atfHeadline  = Font.system(size: 20, weight: .semibold)
    static let atfBody      = Font.system(size: 17, weight: .regular)
    static let atfBodyStr   = Font.system(size: 17, weight: .semibold)
    static let atfSubhead   = Font.system(size: 15, weight: .regular)
    static let atfCaption   = Font.system(size: 13, weight: .medium)
    static let atfOverline  = Font.system(size: 11, weight: .semibold)
    static let atfMono      = Font.system(size: 15, weight: .medium).monospaced()
}
```

### Radius

```swift
// ATFRadius.swift
enum ATFRadius {
    static let input:  CGFloat = 8
    static let card:   CGFloat = 14
    static let pill:   CGFloat = 9999
    static let modal:  CGFloat = 20
    static let chip:   CGFloat = 9999
}
```

---

## 3. Composants DesignSystem

Mappage JSX → SwiftUI. Chaque composant a sa Preview standalone.

| Composant JSX | SwiftUI View | Notes |
|---|---|---|
| `Btn` (primary/outline/ghost/secondary/danger) | `ATFButton` | `kind: ATFButtonKind` enum, `loading: Bool`, `full: Bool` |
| `Field` | `ATFTextField` | `multiline: Bool`, `suffix: String?`, `error: String?` |
| `Chip` | `ATFChip` | `selected: Bool`, `kind: .default/.add`, `tap: Bool` |
| `Toggle` | `ATFToggle` | `orange: Bool` — iOS switch style custom |
| `Badge` | `ATFBadge` | `.pro/.pending/.attached/.danger/.soft` |
| `Card` / `Card elev` | `ATFCard` | `elevated: Bool` |
| `Sheet` | `ATFSheet` | `detent: .small/.medium/.large` via `.sheet` SwiftUI |
| `Toast` | `ATFToast` | Overlay global via `ZStack` dans `RootView` |
| `Icon` | `ATFIcon` | SF Symbols mapping — pas d'asset custom |
| `Wordmark` | `ATFWordmark` | `Instrument Serif` + dot orange |
| `Img` | `ATFAsyncImage` | `AsyncImage` + fallback color + overlay vignette |
| `FoodVignette` | `ATFFoodCard` | Wrapper `ATFAsyncImage` avec tone-to-URL |
| `Skeleton` | `ATFSkeleton` | `shimmer` animation via `.overlay` |

### ATFIcon — SF Symbols mapping

```swift
enum ATFIcon: String {
    case camera      = "camera"
    case cameraFill  = "camera.fill"
    case cameraSlash = "camera.slash"
    case plus        = "plus"
    case check       = "checkmark"
    case x           = "xmark"
    case chevR       = "chevron.right"
    case chevL       = "chevron.left"
    case search      = "magnifyingglass"
    case user        = "person"
    case settings    = "gearshape"
    case sparkles    = "sparkles"
    case flash       = "bolt.fill"
    case flashOff    = "bolt.slash"
    case flip        = "arrow.triangle.2.circlepath.camera"
    case scan        = "viewfinder"
    case tag         = "tag"
    case trash       = "trash"
    case pencil      = "pencil"
    case star        = "star"
    case bell        = "bell"
    case globe       = "globe"
    case more        = "ellipsis"
    case reload      = "arrow.clockwise"
    case wifiSlash   = "wifi.slash"
    case out         = "arrow.right.square"
    case download    = "arrow.down"
    case coins       = "dollarsign.circle"
    case history     = "clock.arrow.circlepath"
    case info        = "info.circle"
    case alert       = "exclamationmark.triangle"
    case shieldCheck = "checkmark.shield"
    case fork        = "fork.knife"
    case tray        = "tray"
    case drag        = "line.3.horizontal"
    case faceId      = "faceid"
    case filter      = "line.3.horizontal.decrease.circle"
    case bug         = "ant"
}
```

---

## 4. Architecture Projet

### Structure Tuist + SPM

```
ATFood/
├── App/
│   ├── ATFoodApp.swift          # @main, SwiftData container setup
│   ├── RootView.swift           # NavigationStack + toast overlay
│   └── Info.plist
├── Packages/
│   ├── Core/
│   │   ├── DesignSystem/        # Tokens + composants (ÉTAPE 1)
│   │   ├── Models/              # Types partagés
│   │   └── Networking/          # SupabaseClient wrapper
│   └── Features/
│       ├── Auth/                # S01 + S02 + S03
│       ├── Home/                # S04
│       ├── Capture/             # S05 + S06 + S07
│       ├── Form/                # S08 + S09
│       ├── Drafts/              # S10
│       ├── AIRetouch/           # S11 + S12 + S13
│       └── Profile/             # S14 + S15 + S16
└── Tuist/
    └── Project.swift
```

### Navigation

```swift
// RootView.swift
enum ATFRoute: Hashable {
    case onboarding
    case login
    case restaurantPicker
    case home
    case camera(mode: CameraMode)
    case preview(photoID: UUID)
    case attachDish(photoID: UUID)
    case dishForm(photoID: UUID?)
    case newCategory
    case drafts
    case aiRetouch(dishID: UUID)
    case backgrounds(dishID: UUID)
    case credits
    case profile
    case upgrade(source: UpgradeSource)
    case offline
}

enum CameraMode { case single, quick }
enum UpgradeSource { case retouch, profile }
```

Navigation stack racine + `.sheet` pour modaux (S09 Nouvelle catégorie, S15 Upgrade).

### State management — @Observable par feature

```swift
// Auth
@Observable final class AuthStore {
    var email = "mariam@chezflora.cm"
    var password = ""
    var isLoading = false
    var error: String?
    var currentUser: User?
    var selectedRestaurant: Restaurant?
}

// Home
@Observable final class HomeStore {
    var restaurant: Restaurant?
    var recentItems: [MenuItem] = []
    var totalCount = 47
    var orphanCount = 3
    var weekCount = 6
}

// Capture
@Observable final class CaptureStore {
    var flashEnabled = true
    var isFlashing = false
    var quickMode = true
    var shotCount = 0
    var targetCount = 3
    var capturedPhotoID: UUID?
}

// Form
@Observable final class FormStore {
    var name = ""
    var price = ""
    var category: MenuCategory?
    var isAvailable = true
    var isFeatured = false
    var description = ""
    var isPublishing = false
    var priceError: String?
}
```

---

## 5. Modèles de données

```swift
// Models/MenuItem.swift
struct MenuItem: Identifiable, Hashable {
    let id: UUID
    var name: String
    var price: Int           // FCFA
    var category: MenuCategory
    var photoURL: URL?
    var isAvailable: Bool
    var isFeatured: Bool
    var description: String
    var createdAt: Date
}

// Models/Restaurant.swift
struct Restaurant: Identifiable, Hashable {
    let id: UUID
    var name: String
    var city: String
    var role: RestaurantRole
    var dishCount: Int
    var photoURL: URL?
}

// Models/Draft.swift
struct Draft: Identifiable {
    let id: UUID
    var photoURL: URL
    var status: DraftStatus
    var createdAt: Date
}

enum DraftStatus { case pending, attached }
enum RestaurantRole { case owner, manager }
enum MenuCategory: String, CaseIterable {
    case entree, plat, grillades, specialite, boisson, dessert
}
```

---

## 6. Inventaire des 16 écrans

### Section 01 — Premier lancement

**S01 · Onboarding** (`OnboardingView`)
- Fond plein écran food photo (3 slides) + Ken Burns scale 1.0→1.08 sur 8s
- Gradient overlay haut + bas
- Barre de progression 3 segments (blanc sur fond translucide)
- Bouton "Passer" haut droite
- Wordmark blanc + tag slide (pill translucide)
- Bas : overline accent, titre display 56pt italic accent, body 16pt, dots + bouton "Continuer/Commencer" orange pill avec arrow circle

**S02 · Splash + Login** (`LoginView`)
- Fond `atfBg`, padding safe area
- Icône orange 72×72 radius 20 + ombre orange
- Wordmark 32pt + tagline "Vos plats, en deux gestes."
- Form : email + password fields (focus orange border)
- "Mot de passe oublié ?" ghost link
- "Se connecter" primary full button
- Footer "Pas encore À Table ? Découvrir"

**S03 · Sélecteur resto** (`RestaurantPickerView`)
- Header : overline "Bonjour {name}", display-sm "Choisis ton restaurant."
- Liste de cards `atf-card-elev` : photo 68×68, nom, ville, role badge, dish count mono
- Sélection : border accent 1.5pt + shadow orange + checkmark pill orange
- Bouton dashed "+ Ajouter un autre établissement"
- CTA sticky bas : "Continuer avec {restoName}" + chevron

### Section 02 — Cœur du produit

**S04 · Home / Dashboard** (`HomeView`)
- Header : photo resto 38×38 + nom + ville + avatar user button
- "Bonjour {name}" overline + "Ta carte du jour." display-sm
- CTA large : card orange "Nouvelle photo" (camera icon + texte + chevron) OU split grid
- Secondary : "Shoot rapide" row surface
- Stats row : 3 cards (47 sur carte / 3 sans photo warning / +6 cette semaine success)
- "Derniers publiés" + horizontal scroll de FoodCards (148pt wide, 170pt tall)
- Badge warning "3 plats sans photo" (conditionnel)

**S05 · Caméra** (`CameraView`)
- Full-bleed viewfinder (`AVCaptureSession` + `UIViewRepresentable` wrapper)
- Gradient overlay top + bottom
- Flash overlay blanc animé (0.25s) au tap shutter
- Top : X button + counter pill "2/3 photos" + flash toggle + flip button
- Centre : crop guides (rule-of-thirds + corner brackets + focus square)
- Mode strip bas : "1 plat / Photo / Shoot rapide" (dot accent sous actif)
- Shutter : 80pt circle blanc border + inner 64pt circle
- Bas gauche : galerie thumb 50×50 · Bas droite : "Terminer" pill (quick mode)

**S06 · Aperçu photo** (`PhotoPreviewView`)
- Fond noir `#0a0805`
- Header : back chevron + pill "PHOTO PRÊTE · 4:5 · 1,8 Mo" (dot vert) + more button
- Photo grande (top 56+32 → bottom 290) avec border radius 22
- Panel bas arrondi (radius 28) : overline + 3 action rows
  - "Rattacher" orange (icon tag, 3 plats sans photo)
  - "Créer nouveau plat" surface (icon plus)
  - "Retoucher" surface (icon sparkles + Pro badge si starter)
- Ghost link "Reprendre la photo"

**S07 · Rattacher à un plat** (`AttachDishView`)
- Back link "Aperçu" + display-sm "Choisir un plat."
- Search field + filtre chips (Sans photo·3, Tous·47, Plat, Grillades)
- Section overline "Plats sans photo · 3"
- List rows : photo placeholder warning (54×54) + nom + price mono + cat · tap → toast

**S08 · Fiche plat** (`DishFormView`)
- Nav bar sticky : "Annuler" ghost + titre "Nouveau plat" (centré)
- Scroll : photo 200pt (avec "Reprendre" pill + "PHOTO·4:5" label)
- L'essentiel : nom* + prix* (FCFA suffix)
- Catégorie* : chips horizontaux scroll (Entrée/Plat/Grillades/Spécialité/Boisson/Dessert + "Créer" dashed)
- Carte : card row "Carte principale"
- Description : textarea optionnel
- Affichage : card 2 toggles (Disponible + Mis en avant orange)
- CTA sticky bas : "Publier le plat" (disabled si form invalide)

### Section 03 — Création annexe

**S09 · Nouvelle catégorie** (`NewCategorySheet`)
- `.sheet` medium sur `DishFormView` (fond faded 35% opacity derrière)
- Grab handle + display-sm "Nouvelle catégorie."
- Nom field + hint compteur
- Grille icônes 4×4 (tap → accent fill)
- Préparation chips (Cuisine / Bar / Les deux)
- Toggle "Mettre en avant sur l'accueil" orange
- CTA "Créer la catégorie" (disabled si nom vide)

**S10 · Galerie brouillons** (`DraftsView`)
- Back "Accueil" + "Sélectionner/OK" toggle
- display-sm "Brouillons." + sous-titre
- Filter chips (Tous·9 / À publier·5 dot warning / Publiés·4 dot success)
- Grid 3 colonnes, 104×104, radius 12 + badge statut top-right
- Multi-select : dim non-sélectionnés + circle checkbox top-left + outline accent
- Action bar sticky bas (si sélection > 0) : "{n} sélectionné(s) · Rattacher · Supprimer"

### Section 04 — Module IA (V2)

**S11 · Retouche IA** (`AIRetouchView`)
- Header : "Fermer" + "Retouche" + credits pill
- Comparatif avant/après : `ZStack` avec `clipShape(Rectangle())` + drag → `clipPath`
- Slider range input invisible par-dessus
- Handle vertical blanc 2.5pt + circle 42pt avec arrows icon
- Labels "Original" pill noir / "Retouché" pill orange
- Tools : 2 rows surface (Supprimer fond 1 crédit · Changer fond 2 crédits)
- Footer : "Réinitialiser" secondary + "Appliquer" primary

**S12 · Backgrounds** (`BackgroundsView`)
- Header + display-sm "Choisir une scène."
- Grid 2 colonnes, 140pt height, AsyncImage + label pill bas-gauche
- Sélection : outline accent 2.5pt + checkmark circle orange top-right
- CTA sticky bas : "Appliquer · 2 crédits" + sparkles icon

**S13 · Crédits IA** (`CreditsView`)
- Header + display-sm "Crédits IA."
- Balance card gradient léger (44pt mono solde)
- Allocation card : compteur "43/50" + progress bar accent 86%
- Bouton outline "+ Acheter des crédits"
- Historique : list rows avec icon circle (plus success / sparkles accent) + montant mono

### Section 05 — Compte & monétisation

**S14 · Profil** (`ProfileView`)
- Header display-sm "Profil." + settings button
- Avatar initiale 64×64 circle gradient orange + nom + email
- Plan card : dark gradient (Pro) OU surface (Starter + "Passer Pro" button)
- Restaurant actif card
- Settings list cards : Compte + Préférences + À propos (rows avec icon 30×30 radius 8)
- "Se déconnecter" danger outline button

**S15 · Upgrade Pro** (`UpgradeSheet`)
- `.sheet` large sur contexte faded
- Icône dorée 56×56 + display-sm centré
- Feature list : 4 rows avec icon accent + check success
- Price card fond sombre : "79 000 FCFA / mois" mono 22pt + Pro badge
- "Découvrir Pro" primary + "Plus tard" ghost

### Section 06 — États transverses

**S16 · Hors-ligne** (`OfflineView`)
- Centré vertical : icon wifi-slash 42pt dans box 88×88 radius 26
- display-sm "Pas de connexion." + body texte
- Card "3 photos en file" (icon tray warning)
- "Réessayer" primary + "Voir mes brouillons" outline

---

## 7. Intégration Supabase

```swift
// Networking/SupabaseClient.swift
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: Env.supabaseURL)!,
    supabaseKey: Env.supabaseAnonKey
)

// Auth
extension SupabaseClient {
    func signIn(email: String, password: String) async throws -> User { ... }
    func signOut() async throws { ... }
}

// Menu items
extension SupabaseClient {
    func fetchMenuItems(restaurantID: UUID) async throws -> [MenuItem] { ... }
    func createMenuItem(_ item: MenuItem) async throws -> MenuItem { ... }
    func uploadPhoto(_ data: Data, dishID: UUID) async throws -> URL { ... }
}
```

Tables Supabase requises : `restaurants`, `menu_items`, `drafts`, `ai_credits`

---

## 8. Séquence d'implémentation (Option A)

| Étape | Contenu | Critère "done" |
|---|---|---|
| 1 | Tuist project setup + SPM skeleton | `xcodebuild build` passe |
| 2 | `DesignSystem` : tokens + tous composants | Chaque composant a Preview qui match prototype |
| 3 | Feature `Auth` : S03 → S01 → S02 | Flow complet sur simulateur |
| 4 | Feature `Home` : S04 | Tous les états (badge on/off, CTA large/split) |
| 5 | Feature `Capture` : S05 → S06 → S07 | Photo capturée → rattachée → toast |
| 6 | Feature `Form` : S08 → S09 | Publier plat → toast → S09 sheet |
| 7 | Feature `Drafts` : S10 | Multi-select + action bar |
| 8 | Feature `AIRetouch` : S11 → S12 → S13 | Slider avant/après + navigation |
| 9 | Feature `Profile` : S14 → S15 → S16 | Tous états plan + offline |

---

## 9. Dépendances SPM

```swift
// Package.swift dependencies
.package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
.package(url: "https://github.com/kean/Nuke", from: "12.0.0"),          // images
.package(url: "https://github.com/realm/SwiftLint", from: "0.57.0"),
```

Fonts : `InstrumentSerif-Regular.ttf` + `InstrumentSerif-Italic.ttf` → bundle `DesignSystem`

---

## 10. CLAUDE.md règles projet

```markdown
# ATFood iOS — CLAUDE.md

## Stack
Swift 6 (strict concurrency), SwiftUI, iOS 17+, @Observable, SPM + Tuist, Supabase

## Règles
- SWIFT_STRICT_CONCURRENCY = complete
- MV pattern : @Observable store, pas de ObservableObject/MVVM
- Après chaque modification : xcodebuild -scheme ATFood build — corriger toutes erreurs
- UI/UX : pixel-perfect au prototype PDF — vérifier avec Preview SwiftUI avant commit
- Couleurs : jamais hardcodées hors de ATFColors.swift
- SF Symbols : utiliser ATFIcon enum uniquement
- Commentaires : uniquement si comportement non-évident
```
