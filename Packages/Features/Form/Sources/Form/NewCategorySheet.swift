import SwiftUI
import Models
import Networking
import DesignSystem

/// Creates the category in Supabase right away, attached to a menu so the web storefront shows it.
public struct NewCategorySheet: View {
    @Bindable var store: FormStore
    let networking: any ATFNetworking
    let onDone: () -> Void

    @State private var name: String = ""
    @State private var menuID: UUID?
    @State private var isSaving = false
    @State private var error: String?

    public init(store: FormStore, networking: any ATFNetworking, onDone: @escaping () -> Void) {
        self.store = store
        self.networking = networking
        self.onDone = onDone
    }

    private var trimmed: String { name.trimmingCharacters(in: .whitespaces) }
    // With several menus the storefront hides categories without a menu: force a choice.
    private var needsMenu: Bool { store.menus.count > 1 }
    private var isValid: Bool { store.menusLoaded && !trimmed.isEmpty && (!needsMenu || menuID != nil) }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Nouvelle catégorie")
                    .font(.atfHeadline)
                    .foregroundStyle(Color.atfText1)
                    .padding(.top, 24)

                ATFTextField("Nom de la catégorie", text: $name, placeholder: "Ex. : Grillades", error: error)
                    .padding(.horizontal, 20)

                if !store.menusLoaded {
                    VStack(spacing: 8) {
                        Text("Menus non chargés : impossible de savoir où placer la catégorie.")
                            .font(.atfCaption)
                            .foregroundStyle(Color.atfDanger)
                            .multilineTextAlignment(.center)
                        ATFButton("Réessayer", kind: .secondary, loading: store.isLoadingCategories) {
                            Task { await store.loadCategories(networking: networking) }
                        }
                    }
                    .padding(.horizontal, 20)
                } else if needsMenu {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dans quel menu ?")
                            .font(.atfCaption)
                            .foregroundStyle(Color.atfText2)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(store.menus) { menu in
                                    ATFChip(menu.name, selected: menuID == menu.id, tap: true) { menuID = menu.id }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                ATFButton("Créer", kind: .primary, fullWidth: true, loading: isSaving, disabled: !isValid) {
                    save()
                }
                .padding(.horizontal, 20)

                ATFButton("Annuler", kind: .ghost) { onDone() }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
        }
        // Scrolls when the keyboard or a short window leaves less room than the content needs.
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .background(Color.atfBg.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .onAppear {
            if store.menus.count == 1 { menuID = store.menus.first?.id }
        }
    }

    private func save() {
        guard isValid else { return }
        if store.categories.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame && $0.menuID == menuID }) {
            error = "Cette catégorie existe déjà."
            return
        }
        isSaving = true
        error = nil
        Task {
            do {
                try await store.createCategory(name: trimmed, menuID: menuID, networking: networking)
                onDone()
            } catch {
                self.error = UserMessage.from(error)
            }
            isSaving = false
        }
    }
}

// Previews use DEBUG-only demo data (MockNetworking, .mocks): never compiled into Release.
#if DEBUG
#Preview("NewCategorySheet") {
    NewCategorySheet(store: FormStore(restaurant: Restaurant.mocks[0]), networking: MockNetworking(), onDone: {})
}
#endif
