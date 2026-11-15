# AT Food: Design Brief Complet
## Pour refonte UI/UX totale (Claude Design / Figma)

---

## 1. Contexte Produit

**AT Food** est l'application iOS B2B destinée aux restaurateurs partenaires de **Attabl** (attabl.com), un SaaS de gestion de carte digitale pour restaurants africains (marché principal : Cameroun, Côte d'Ivoire, Sénégal).

### Proposition de valeur core
> En 2 gestes: photo d'un plat → plat en ligne sur la carte digitale du restaurant.

Ce n'est **pas** une app client (type Uber Eats). C'est un outil professionnel pour le restaurateur ou son équipe :
- photographier rapidement un plat
- l'ajouter ou le rattacher à la carte
- gérer la disponibilité en temps réel
- améliorer les photos avec l'IA

### Relation avec Attabl SaaS
AT Food est un module satellite d'Attabl. L'authentification, les tenants, le menu et le stockage sont tous dans la même base Supabase. Ce que le restaurateur fait dans AT Food apparaît immédiatement dans son dashboard web Attabl et sur sa carte QR client.

---

## 2. Utilisateurs Cibles

| Rôle | Description | Usage typique |
|------|-------------|---------------|
| **Propriétaire** (owner) | Gérant du restaurant | Configure la carte, gère l'abonnement |
| **Admin** | Responsable de salle | Ajoute des plats, gère disponibilités |
| **Manager** | Chef / responsable cuisine | Photographie les plats du jour |

**Profil type :** 28-45 ans, Afrique francophone, smartphone Android ou iPhone, utilise WhatsApp au quotidien, pas forcément tech-savvy. Veut quelque chose d'**ultra-rapide et intuitif**.

---

## 3. Brand Identity & Tone

### Nom
- App : **AT Food** (prononcer "à table food")
- SaaS parent : **Attabl** (contraction de "À Table")

### Ton
- Professionnel mais chaleureux
- Confiant, efficace, sans friction
- Français (toute l'UI est en français)
- Pas trop corporate: c'est pour des gens de terrain

### Couleur accent actuelle
- Orange : `#F97316` (Tailwind orange-500)
- C'est la couleur signature d'Attabl. **À conserver** comme couleur primaire.

### Inspiration de niveau (apps de référence)
- **Uber Eats** (qualité photo, UX fluide, cards food)
- **Toast POS** (outil pro restaurant, efficace)
- **Lightroom Mobile** (interface capture/edit pro)
- **Notion** (typo propre, espacement généreux)

### Ce qui manque actuellement
L'app actuelle est **fonctionnelle mais visuellement basique** :
- Typographie trop petite / trop peu de hiérarchie
- Cards de plats trop serrées, pas assez appétissantes
- Onboarding trop simple (3 slides backgrounds Unsplash)
- Formulaires plats sans personnalité
- Écrans de capture sans guidage visuel fort
- Pas de dark mode cohérent
- Aucune micro-animation ou feedback haptique

---

## 4. Design System Actuel (tokens à revisiter)

### Couleurs
```
Accent:        #F97316  (orange: à conserver)
AccentHover:   #EA6E0A
AccentMuted:   #F97316 @ 12% opacity

Background:    #FFFFFF
Surface:       #F7F7F7
Surface2:      #EFEFEF
Border:        black @ 8% opacity
BorderStrong:  black @ 14% opacity

Text1:         #0A0A0A  (primary)
Text2:         #535353  (secondary)
Text3:         #9A9A9A  (placeholder/muted)

Success:       #16A34A
Warning:       #EAB308
Danger:        #DC2626

Dark mode surfaces:
BgDark:        #0E0E0E
SurfaceDark:   #1A1A1A
Surface2Dark:  #252525
```

### Typographie actuelle (à remplacer)
- Headings onboarding : `InstrumentSerif` (Regular + Italic)
- Corps : SF Pro (system): **trop générique**
- **Recommandation brief** : garder une serif élégante pour les grandes accroches + une sans-serif premium pour le reste (ex: Plus Jakarta Sans, DM Sans, ou Geist)

### Radius
- Cards : 12-14pt
- Chips/capsules : full radius (Capsule)
- Boutons : Capsule

### Composants existants à redesigner
- `ATFButton` (primary, secondary, danger): OK structurellement, esthétique à revoir
- `ATFTextField`: fonctionnel, style à améliorer
- `ATFBadge` (soft, pro, success, warning): trop petit/fade
- `ATFFoodCard`: carte plat dans la grille home: priorité haute
- `ATFChip`: chip catégorie: à rendre plus premium
- `ATFSkeleton`: loading placeholder: à améliorer
- `ATFToast`: notification: à refaire (bottom sheet style)
- `ATFToggle`: switch disponibilité
- `ATFSheet`: sheet modale

---

## 5. Navigation Complète

```
App Launch
    └── Onboarding (3 slides) ──────────────────────────────── [S01]
            └── Login ──────────────────────────────────────── [S02]
                    └── Restaurant Picker ───────────────────── [S03]
                                └── Home ────────────────────── [S04]
                                        ├── Camera ──────────── [S05]
                                        │       └── Photo Preview ── [S06]
                                        │               └── Attach Dish ── [S07]
                                        │                       ├── Dish Form (nouveau plat) ── [S08]
                                        │                       │       └── New Category Sheet ── [S09]
                                        │                       └── (attach to existing → Home)
                                        │
                                        ├── Drafts ───────────── [S10]
                                        │       └── AI Retouch ── [S11]
                                        │               └── Backgrounds ── [S12]
                                        │
                                        └── Profile ──────────── [S13]
                                                ├── Credits ───── [S14]
                                                ├── Upgrade Sheet ─ [S15]
                                                └── Offline ────── [S16]
```

---

## 6. Inventaire Écrans: Description Détaillée

---

### S01: Onboarding (3 slides)

**But :** Première impression. Expliquer la valeur en 3 étapes avant le login.

**Contenu actuel des slides :**
1. *"Publiez vos plats en 2 gestes."*: photo plat, tag "Pour les restaurateurs"
2. *"Photographiez comme un pro."*: cadrage automatique, shoot rapide
3. *"Votre menu, toujours à jour."*: activer/désactiver en un tap

**Architecture actuelle :**
- Fullscreen photo background (Unsplash)
- Effet Ken Burns (zoom lent)
- Double gradient overlay (top + bottom)
- Progress bar top + dots navigation
- Bouton "Passer" top right
- Titre en InstrumentSerif (42pt) + accent italic orange
- Body 16pt blanc
- CTA capsule orange

**Problèmes actuels :**
- Photos Unsplash génériques (pas des vrais plats africains)
- Layout trop classique / vu partout
- Pas de personnalité de marque forte

**Objectif redesign :**
- Visual storytelling premium (photos food africaine haute qualité ou illustrations)
- Animations de transition entre slides (pas juste fade)
- Logo Attabl + AT Food bien mis en avant
- Sentiment de "outil professionnel sérieux" + "plaisir d'utiliser"

---

### S02: Login

**But :** Authentification email/password.

**Contenu :**
- Logo AT Food (icône fourchette dans carré orange arrondi 72×72)
- Wordmark "ATFood" 32pt
- Tagline "Vos plats, en deux gestes."
- Champ email + champ password (secure)
- Lien "Mot de passe oublié ?"
- Bouton "Se connecter" (primary, fullWidth)
- Lien "Pas encore À Table ? Découvrir"

**Logique :**
- Pas d'inscription dans l'app: le compte est créé sur attabl.com
- Erreurs affichées inline sous le champ password
- Erreurs mappées : credentials invalides / réseau / autre

**Objectif redesign :**
- Login page qui donne envie (food mood, pas page corporate)
- Meilleure hiérarchie visuelle
- Transition animée depuis onboarding

---

### S03: Restaurant Picker

**But :** Si l'utilisateur gère plusieurs restaurants, il choisit lequel utiliser.

**Contenu :**
- Titre "Bonjour, [Prénom] 👋" + "Quel établissement ?"
- Liste de cards restaurants :
  - Photo logo restaurant (48×48 arrondi)
  - Nom + ville + nombre de plats
  - Badge rôle (Propriétaire / Admin / Manager)
  - Checkmark sélection
- Bouton "Continuer" fixé en bas

**Données restaurant :** `id, name, city, role, dishCount, photoURL`

**Règle métier :** Ne montre que les restaurants actifs avec abonnement valide (trial / active / past_due) et rôle autorisé (owner / admin / manager).

**Objectif redesign :**
- Cards plus riches visuellement (fond photo restaurant)
- Si 1 seul restaurant → skip automatique (pas d'écran)
- Micro-animation de sélection

---

### S04: Home (Menu Board)

**But :** Vue principale. Affiche tous les plats du restaurant avec filtres catégorie.

**Layout actuel :**
- Fond sombre (#0F0909 brun-noir)
- Top bar : avatar/profil | Wordmark + nom restaurant | Drafts | Camera
- Chips catégories (scroll horizontal) : "Tous" + catégories dynamiques depuis Supabase
- Grille 2 colonnes de FoodCards (148×170pt)
- State vide avec icône fork.knife

**FoodCard actuelle :**
- Image plat (rectangle avec overlay gradient)
- Nom du plat
- Prix formaté (ex: "3 800 FCFA")
- Indicateur disponibilité (point vert/gris)

**Données menu :**
- `id, name, price (FCFA), category, photoURL, isAvailable, isFeatured, description, createdAt`

**Prix :** toujours en FCFA (Franc CFA d'Afrique Centrale). Format: "3 800 FCFA", "15 000 FCFA"

**Catégories :** dynamiques depuis table `categories` Supabase (ex: Plat, Entrée, Grillades, Boisson, Dessert, Spécialité)

**States à designer :**
- Loading (skeleton grid 2 colonnes)
- Vide (aucun plat: CTA d'ajout)
- Liste normale
- Liste filtrée par catégorie

**Objectif redesign :**
- Cards food beaucoup plus appétissantes (style Uber Eats ou Deliveroo)
- Meilleure mise en valeur des plats featured / vedettes
- Navigation plus intuitive (FAB caméra ?)
- Dark mode natif cohérent (le fond sombre est voulu)

---

### S05: Camera

**But :** Capturer une photo d'un plat avec la caméra arrière.

**Layout actuel :**
- Plein écran live camera preview
- Bouton capture circulaire en bas (80pt, blanc avec ring)
- Bouton fermer (×) en haut gauche
- Accès galerie (non implémenté)

**Logique :**
- `AVFoundation` : `AVCaptureSession`, `AVCapturePhotoOutput`
- Photo capturée → stockée dans `CaptureStore.capturedImage: UIImage`
- Auto-orientation portrait

**Objectif redesign :**
- Guide de cadrage visuel (overlay aide à bien centrer le plat)
- Indicateur de qualité lumière (optionnel futur)
- Animation de capture (flash + scale)
- Bouton galerie intégré élégamment

---

### S06: Photo Preview

**But :** Voir la photo capturée avant de l'utiliser.

**Layout actuel :**
- Photo plein écran
- Bouton "Reprendre" (secondary): retour caméra
- Bouton "Utiliser" (primary): avancer vers Attach Dish

**Objectif redesign :**
- Preview plus immersif
- Option zoom/crop basique
- Feedback qualité photo (blur, luminosité)
- Transition fluide depuis caméra

---

### S07: Attach Dish

**But :** Après la photo, choisir : rattacher à un plat existant OU créer un nouveau plat.

**Layout actuel :**
- Header "Attacher à un plat" + back
- Bouton "+ Nouveau plat" (secondary, fullWidth)
- Séparateur "ou choisir un plat existant"
- Liste scrollable de plats existants (DishRow : nom + badge catégorie + checkmark)
- Bouton "Attacher" fixé en bas (disabled si rien sélectionné, loading pendant upload)

**Logique :**
- Charge `fetchMenuItems(restaurantID)` au chargement
- Upload via `attachPhoto(imageData, dishID, restaurantID)`
- Upload vers storage Supabase `menu-items/{tenantID}/{dishID}.jpg`
- Met à jour `image_url` dans `menu_items`

**États :**
- Loading (fetch liste)
- Vide (aucun plat: forcer création nouveau)
- Liste normale
- Uploading (bouton Attacher en loading)
- Erreur inline

**Objectif redesign :**
- Thumbnails des plats existants dans la liste (pas juste texte)
- Recherche dans la liste (si beaucoup de plats)
- Preview de la photo capturée visible quelque part

---

### S08: Dish Form (Nouveau Plat)

**But :** Créer un nouveau plat avec photo, nom, prix, catégorie, disponibilité.

**Champs :**
- Photo (preview si capturedImage présent sinon placeholder "+")
- Nom du plat (TextField)
- Prix en FCFA (TextField numérique, suffix "FCFA")
- Catégorie (chips scrollables dynamiques depuis Supabase + bouton "+" pour nouvelle catégorie)
- Disponible (toggle on/off)
- Description (non visible dans le form actuel: à ajouter ?)

**Validation :**
- Nom non vide + prix valide → bouton "Enregistrer" actif
- Prix accepte saisie libre, extrait les chiffres uniquement

**Logique save :**
1. `findOrCreateCategory(name, tenantID)` → récupère ou crée la catégorie dans Supabase
2. `createMenuItem(item, restaurantID)` → INSERT dans `menu_items`
3. Si photo capturée → `attachPhoto(imageData, dishID, restaurantID)` → upload storage + UPDATE `image_url`

**Objectif redesign :**
- Form visuellement premium (pas juste des TextFields gris)
- Champ description optionnel visible
- Prix avec clavier numérique formaté
- Animation smooth sur le toggle disponibilité
- Indication visuelle claire que la photo sera uploadée

---

### S09: New Category Sheet

**But :** Ajouter une nouvelle catégorie directement depuis le formulaire plat.

**Layout actuel :**
- Bottom sheet (`.presentationDetents([.medium])`)
- TextField "Nom de la catégorie"
- Bouton "Créer" (primary)
- Bouton "Annuler"

**Logique :**
- La catégorie est créée dans Supabase lors du save du plat via `findOrCreateCategory`
- Dans le sheet elle est juste ajoutée à la liste locale de `store.categories`

**Objectif redesign :**
- Sheet compacte, ergonomique (keyboard avoid natif)
- Suggestions de catégories courantes (Plat, Entrée, Boisson…)

---

### S10: Drafts

**But :** Liste des photos en attente d'attachement ou déjà attachées.

**Layout actuel :**
- Header "Mes photos" + back
- Liste de DraftRows (photo thumbnail + status badge)
- Status : "En attente" (orange) ou "Attachée" (vert)
- Bouton "Retouche IA" sur les drafts attachés

**Données draft :**
- `id: UUID, photoURL: URL, status: pending | attached`
- Table Supabase `dish_photo_drafts` (créée en V1 migration)

**Objectif redesign :**
- Grid de photos (pas liste), style galerie
- Status visuellement clair
- Preview en grand au tap

---

### S11: AI Retouch

**But :** Appliquer un effet IA à la photo d'un plat (améliorer rendu visuel).

**Layout actuel :**
- Photo originale en grand
- Grille d'effets IA disponibles (thumbnails avec labels)
- Bouton "Appliquer" (crédits requis)
- Indicateur crédits restants
- Si 0 crédits → prompt upgrade

**Effets disponibles (enum `AIRetouchEffect`) :**
- `.enhance`: amélioration générale
- `.background`: suppression fond
- `.lighting`: optimisation lumière
- `.colorBoost`: saturation couleurs

**Crédits :** compteur depuis `ai_photo_credits` table Supabase (non encore fonctionnel)

**Objectif redesign :**
- Before/After slider de preview d'effet
- Effets avec preview thumbnail en temps réel (ou mockup)
- Compteur crédits très visible
- Paywall élégant si crédits épuisés

---

### S12: Backgrounds

**But :** Choisir un fond de remplacement pour la photo du plat.

**Layout actuel :**
- Grid de fonds disponibles
- Aperçu avec le plat actuel

**Objectif redesign :**
- Preview split ou overlay élégant
- Catégories de fonds (bois, ardoise, textile, couleur unie…)

---

### S13: Profile

**But :** Profil utilisateur, gestion du compte et settings.

**Sections :**

**Avatar :** Initiale dans cercle gradient orange. Nom + email + badge plan.

**Plan Card :** Si non-Pro → card CTA "Passer au Pro" avec border orange.

**Credits Card :** "X / Y crédits IA disponibles" → navigate vers Credits.

**Restaurant Card :** Nom restaurant actif + badge rôle.

**Settings List :**
- Ouvrir le dashboard web (attabl.com)
- Activer Face ID
- Notifications (ouvre app settings iOS)
- Langue (non implémenté)
- Mode hors-ligne → S16
- Signaler un bug (mailto:support@attabl.com)
- Aide & Support (attabl.com/support)
- Conditions d'utilisation
- Version app

**Sign Out :** Bouton rouge "Se déconnecter"

**Objectif redesign :**
- Avatar section plus impactante (fond photo restaurant derrière ?)
- Settings list plus aérée, icônes colorées (style iOS Settings)
- Plan badge Pro beaucoup plus premium et désirable
- Transition vers la liste depuis le Home (slide in depuis droite ou modale)

---

### S14: Credits

**But :** Voir l'historique et le solde de crédits IA.

**Layout actuel :**
- Solde restant (grand chiffre)
- Historique d'utilisation
- Bouton achat crédits → upgrade

**Objectif redesign :**
- Balance display premium (style Apple Pay balance)
- Historique sous forme de timeline

---

### S15: Upgrade Sheet

**But :** Paywall pour passer au plan Pro.

**Layout actuel :**
- Bottom sheet
- Features Pro listées
- CTA "Passer au Pro"

**Objectif redesign :**
- Paywall premium style (gradient sombre, sparkles, features avec checkmarks)
- Prix clairement affiché
- Social proof si possible

---

### S16: Offline Mode

**But :** Gérer les actions en mode hors connexion.

**Layout actuel :**
- Message "Vous êtes hors ligne"
- Compteur actions en attente
- Bouton "Réessayer"

**Objectif redesign :**
- Illustration offline expressive
- Liste claire des actions en queue

---

## 7. Modèles de Données

### MenuItem
```swift
id: UUID
name: String          // "Thieboudienne"
price: Int            // 4500 (FCFA)
category: String      // "Plat" (nom de catégorie depuis Supabase)
photoURL: URL?        // https://...supabase.co/storage/v1/object/public/menu-items/...
isAvailable: Bool     // true/false: toggle temps réel
isFeatured: Bool      // plat vedette (pas encore affiché dans UI)
description: String   // texte libre
createdAt: Date
```

Format prix FCFA : `4 500 FCFA`, `15 000 FCFA`, `800 FCFA`

### Restaurant (= Tenant)
```swift
id: UUID
name: String          // "L'Epicurien"
city: String          // "Douala"
role: RestaurantRole  // owner / admin / manager
dishCount: Int        // nombre de plats dans la carte
photoURL: URL?        // logo restaurant
```

### AppUser
```swift
id: UUID
name: String          // premier segment de l'email
email: String
plan: AppPlan         // starter / pro / business / enterprise
```

### Draft
```swift
id: UUID
photoURL: URL
status: DraftStatus   // pending / attached
```

---

## 8. Flux Utilisateur Principaux

### Flux A: Ajouter un nouveau plat (flow principal)
```
Home (tap caméra)
  → Camera (cadre + capture)
  → Photo Preview (valider photo)
  → Attach Dish (tap "+ Nouveau plat")
  → Dish Form (remplir nom + prix + catégorie)
  → [Save] → toast "Plat enregistré !" → retour Home
```

### Flux B: Rattacher une photo à un plat existant
```
Home (tap caméra)
  → Camera → Photo Preview
  → Attach Dish (sélectionner plat dans liste)
  → [tap Attacher] → toast "Photo attachée !" → retour Home
```

### Flux C: Retouche IA d'une photo
```
Home (tap Drafts)
  → Drafts (liste des photos)
  → tap "Retouche IA"
  → AI Retouch (choisir effet)
  → [si fond] → Backgrounds (choisir fond)
  → [Appliquer] → photo mise à jour
```

### Flux D: Gestion du profil
```
Home (tap avatar)
  → Profile
  → [Crédits] → Credits
  → [Upgrade] → Upgrade Sheet
  → [Hors-ligne] → Offline Mode
```

---

## 9. Contraintes Techniques pour le Designer

### Plateforme
- iOS 17+ uniquement
- SwiftUI natif (pas React Native)
- iPhone only (pas iPad, pas Mac)
- Portrait uniquement pour la majorité des écrans

### Safe Areas
- Tous les écrans respectent les safe areas iOS
- Home et Camera utilisent `ignoresSafeArea()` pour le fond
- Boutons fixés en bas : padding bottom 32pt minimum + safe area

### Navigation
- `NavigationStack` avec `navigationBarHidden(true)` sur tous les écrans
- Navigation par push (slide horizontal)
- Sheets modales pour : New Category, Upgrade, (potentiellement Attach Dish)
- Toast notifications (slide in from top)

### Tailles de référence
- Screen design sur iPhone 15 Pro (393×852pt logical)
- Corner radius system : 12pt (cards small), 14pt (cards large), 20pt (sheets)
- Touch targets minimum : 44×44pt

### Composants à designer (pour chaque)
1. Default state
2. Loading / skeleton state
3. Error state
4. Empty state
5. Dark mode variant

---

## 10. Écrans Manquants / À Créer

Ces fonctionnalités sont définies dans le code mais n'ont pas d'écran abouti :

| Écran manquant | Priorité | Description |
|----------------|----------|-------------|
| **Dish Detail** | Haute | Voir/éditer un plat existant depuis la Home. Actuellement les cards de Home ne sont pas tappables. |
| **Edit Dish Form** | Haute | Formulaire d'édition d'un plat existant (nom, prix, catégorie, disponibilité, photo). |
| **Search** | Moyenne | Recherche dans le menu par nom ou catégorie. |
| **QR Code** | Moyenne | Voir et partager le QR code de la carte digitale du restaurant. |
| **Notifications Center** | Basse | Centre de notifications in-app (commandes, alertes). |
| **User Management** | Basse | Gérer les membres de l'équipe (owner seulement). |
| **Categories Manager** | Moyenne | Gérer l'ordre et la visibilité des catégories. |
| **Onboarding Post-Login** | Haute | Premier setup guidé après login (ajouter premier plat, configurer le restaurant). |
| **Photo Gallery per Dish** | Basse | Historique des photos d'un plat. |

---

## 11. Direction Créative Souhaitée

### Style général
- **Dark-first** : le contexte restaurant (cuisine, service du soir) favorise les interfaces sombres
- **Food photography dominant** : les photos des plats sont le contenu héros: l'UI doit les mettre en valeur sans les écraser
- **Premium africain** : ancré dans le contexte (cuisine africaine, FCFA, noms en français) mais avec une qualité visuelle internationale
- **Ultra-fluide** : chaque action a une réponse immédiate (haptique + animation)

### Palette de couleurs suggérée
- Background primaire : proche de `#0A0A08` (noir chaud, pas froid)
- Surfaces : `#141412`, `#1E1C1A`
- Accent : garder `#F97316` (orange Attabl)
- Texte primaire : `#F5F3F0` (blanc cassé chaud)
- Success : vert émeraude `#10B981`
- Cards : glassmorphism léger ou dark elevated

### Typographie suggérée
- Titres/accroches : **Plus Jakarta Sans ExtraBold** ou **DM Serif Display** (contraste serif/sans)
- Corps : **Plus Jakarta Sans Regular/Medium**
- Prix : chiffres en **tabular nums**, gras, orange
- Labels UI : Medium 13-14pt

### Références visuelles (à ne pas copier mais s'inspirer)
- Uber Eats food cards: photos plein-bleed, gradient bottom, nom clair
- Toast POS: efficacité, lisibilité en cuisine
- Pitch app: cartes slides premium
- Blackbird (app restaurant manager US): dark UI pro
- Opal app: animations fluides et onboarding soigné

---

## 12. Priorités Redesign

| Priorité | Écran | Raison |
|----------|-------|--------|
| 🔴 P0 | Home (S04) | Écran le plus utilisé: FoodCards à refaire |
| 🔴 P0 | Onboarding (S01) | Première impression: actuellement trop générique |
| 🔴 P0 | Camera + Photo Preview (S05-S06) | Flow principal de valeur |
| 🟠 P1 | Attach Dish (S07) | Friction actuelle: pas de thumbnails |
| 🟠 P1 | Dish Form (S08) | Créer un plat: expérience trop basique |
| 🟠 P1 | Login (S02) | Impression de marque |
| 🟡 P2 | Profile (S13) | Fonctionnel mais générique |
| 🟡 P2 | AI Retouch (S11) | Feature premium: doit paraître premium |
| 🟡 P2 | Upgrade Sheet (S15) | Conversion: actuellement trop basique |
| 🟢 P3 | Drafts, Credits, Offline | Utilitaires: redesign après les prioritaires |

---

## 13. Assets & Ressources

### Logos / Wordmarks
- Wordmark "ATFood" : composant SwiftUI `ATFWordmark`: à refaire en vrai SVG/asset
- Icône app : fourchette stylisée dans carré orange arrondi (72×72)
- À créer : version dark mode du wordmark

### Iconographie
- Actuellement : SF Symbols Apple uniquement
- Objectif : set d'icônes custom ou mixte (SF Symbols + Lucide Icons ou Phosphor)

### Photos de référence (types de plats représentés)
- Thieboudienne (riz au poisson sénégalais)
- Mafé bœuf (sauce d'arachide)
- Ndolé (feuilles amères + crevettes camerounais)
- Brochettes / grillades
- Jus de bissap (hibiscus rouge)
- Alloco (bananes plantain frites)

---

## 14. Checklist pour le Designer

Pour chaque écran livré :

- [ ] Frame iPhone 15 Pro (393×852)
- [ ] State default + loading + error + empty
- [ ] Dark mode uniquement (ou dark + light si pertinent)
- [ ] Annotations des tailles/espacements
- [ ] Composants découpés et nommés
- [ ] Prototype de navigation minimum (Home → Camera → Form → Home)
- [ ] Export des couleurs et typographies comme variables Figma

---

*Brief rédigé à partir du code source ATFood: Mai 2025*
*Version app : basée sur commit `d1a5168` (branche main)*
*Architecture : iOS 17+ / SwiftUI / Supabase / Swift 6 strict concurrency*
