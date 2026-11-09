import SwiftUI
import PhotosUI
import Models
import Networking
import DesignSystem

/// New dish (from a photo) or dish card (edit name, price, availability, category, photo).
public struct DishFormView: View {
    @Bindable var store: FormStore
    let networking: any ATFNetworking
    let onSaved: () -> Void
    let onBack: () -> Void
    /// Edit mode only: open the guided camera to replace this dish's photo.
    let onChangePhoto: (@MainActor () -> Void)?

    @State private var showCategorySheet = false
    @State private var confirmDiscard = false
    @State private var pickedGalleryItem: PhotosPickerItem?
    @State private var showTranslation = false
    @FocusState private var fieldFocused: Bool

    public init(
        store: FormStore,
        networking: any ATFNetworking,
        onSaved: @escaping () -> Void,
        onBack: @escaping () -> Void,
        onChangePhoto: (@MainActor () -> Void)? = nil
    ) {
        self.store = store
        self.networking = networking
        self.onSaved = onSaved
        self.onBack = onBack
        self.onChangePhoto = onChangePhoto
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 20) {
                    photoSection
                    if store.isEditing { gallerySection }
                    fieldsSection
                    categorySection
                    availabilityRow
                    detailsSection
                    if let errorMsg = store.error {
                        Label(errorMsg, systemImage: "exclamationmark.triangle.fill")
                            .font(.atfCaption)
                            .foregroundStyle(Color.atfDanger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            // Hidden while typing: above the keyboard it covered the price field and the "Terminé" bar.
            if !fieldFocused {
                saveButton
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.atfSurface)
            }
        }
        .background(Color.atfSurface.ignoresSafeArea())
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Terminé") { fieldFocused = false }
            }
        }
        .task { await store.loadCategories(networking: networking) }
        .confirmationDialog("Abandonner les modifications ?", isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button("Abandonner", role: .destructive, action: onBack)
            Button("Continuer la modification", role: .cancel) {}
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                if store.hasUnsavedChanges { confirmDiscard = true } else { onBack() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.atfAccent)
                    .frame(width: 44, height: 44)
            }
            // Leaving mid-save would pop the screen and then jump elsewhere when the save ends.
            .disabled(store.isLoading)
            .accessibilityLabel("Retour")

            Spacer()

            Text(store.isEditing ? "Fiche plat" : "Nouveau plat")
                .font(.atfHeadline)
                .foregroundStyle(Color.atfText1)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    // MARK: - Photo

    private var photoSection: some View {
        VStack(spacing: 10) {
            Group {
                if let editing = store.editing {
                    remoteImage(editing.photoURL)
                } else {
                    switch store.photo {
                    case .captured(let image):
                        Image(uiImage: image).resizable().scaledToFill()
                    case .draft(let draft):
                        remoteImage(draft.photoURL)
                    case nil:
                        placeholder
                    }
                }
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityHidden(true)

            if let onChangePhoto {
                ATFButton(store.editing?.photoURL == nil ? "Ajouter une photo" : "Changer la photo",
                          kind: .secondary, disabled: store.isLoading, action: onChangePhoto)
                    .accessibilityIdentifier("changePhotoButton")
            }
        }
    }

    private func remoteImage(_ url: URL?) -> some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else if url == nil {
                placeholder
            } else {
                Color.atfSurface2
            }
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.atfSurface2
            Image(systemName: "photo")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(Color.atfText3)
        }
    }

    // MARK: - Fields

    private var fieldsSection: some View {
        VStack(spacing: 16) {
            ATFTextField("Nom du plat", text: $store.name, placeholder: "Ex. : Thieboudienne")
                .textInputAutocapitalization(.sentences)
                .focused($fieldFocused)
            ATFTextField("Prix", text: $store.priceText,
                         placeholder: store.allowsDecimals ? "12,50" : "3 800",
                         suffix: store.currencySymbol,
                         error: store.priceError)
                .keyboardType(store.allowsDecimals ? .decimalPad : .numberPad)
                .focused($fieldFocused)
        }
        .padding(.horizontal, 20)
        .disabled(store.isDishCreated)
    }

    // MARK: - Category

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Catégorie")
                .font(.atfCaption)
                .foregroundStyle(Color.atfText2)
                .padding(.leading, 20)

            if !store.menusLoaded && !store.isLoadingCategories {
                HStack {
                    Text("Catégories non chargées.")
                        .font(.atfCaption)
                        .foregroundStyle(Color.atfDanger)
                    ATFButton("Réessayer", kind: .secondary) {
                        Task { await store.loadCategories(networking: networking) }
                    }
                }
                .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if store.isLoadingCategories {
                            ProgressView().tint(Color.atfAccent)
                        }
                        Button {
                            showCategorySheet = true
                        } label: {
                            Label(store.categories.isEmpty ? "Créer une catégorie" : "Nouvelle", systemImage: "plus")
                                .font(.atfCaption)
                                .foregroundStyle(Color.atfAccent)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(Color.atfAccentMuted)
                                .clipShape(Capsule())
                        }
                        .accessibilityIdentifier("newCategoryButton")
                        ForEach(store.categories) { cat in
                            categoryChip(cat)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .disabled(store.isDishCreated)
        .sheet(isPresented: $showCategorySheet) {
            NewCategorySheet(store: store, networking: networking) {
                showCategorySheet = false
            }
        }
    }

    private func categoryChip(_ cat: MenuCategory) -> some View {
        let isSelected = store.selectedCategoryID == cat.id
        return Button {
            store.selectedCategoryID = cat.id
        } label: {
            Text(store.label(for: cat))
                .font(.atfCaption)
                .foregroundStyle(isSelected ? Color.white : Color.atfText2)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.atfAccent : Color.atfSurface2)
                .clipShape(Capsule())
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Availability

    private var availabilityRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Disponible")
                    .font(.atfBody)
                    .foregroundStyle(Color.atfText1)
                Text(store.isAvailable ? "Visible et commandable sur votre menu" : "Affiché « épuisé » sur votre menu")
                    .font(.atfCaption)
                    .foregroundStyle(Color.atfText3)
            }
            Spacer()
            ATFToggle(isOn: $store.isAvailable)
                .accessibilityLabel("Disponible")
        }
        .padding(.horizontal, 20)
        .disabled(store.isDishCreated)
    }

    // MARK: - Details (rest of the web dish sheet)

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            textArea("Description", text: $store.descriptionText,
                     placeholder: "Ingrédients, accompagnement, cuisson…")

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("À la une")
                        .font(.atfBody)
                        .foregroundStyle(Color.atfText1)
                    Text("Mis en avant en tête de votre menu")
                        .font(.atfCaption)
                        .foregroundStyle(Color.atfText3)
                }
                Spacer()
                ATFToggle(isOn: $store.isFeatured, orange: true)
                    .accessibilityLabel("À la une")
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Allergènes")
                    .font(.atfCaption)
                    .foregroundStyle(Color.atfText2)
                FlowLayout(spacing: 8) {
                    ForEach(Allergen.all, id: \.id) { allergen in
                        ATFChip(allergen.label, selected: store.allergens.contains(allergen.id), tap: true) {
                            if store.allergens.contains(allergen.id) { store.allergens.remove(allergen.id) }
                            else { store.allergens.insert(allergen.id) }
                        }
                        .accessibilityAddTraits(store.allergens.contains(allergen.id) ? .isSelected : [])
                    }
                }
            }

            ATFTextField("Calories", text: $store.caloriesText, placeholder: "Ex. : 450",
                         suffix: "kcal", error: store.caloriesError)
                .keyboardType(.numberPad)
                .focused($fieldFocused)

            DisclosureGroup(isExpanded: $showTranslation) {
                VStack(spacing: 16) {
                    ATFTextField("Nom (traduction)", text: $store.nameEn, placeholder: "Ex. : Grilled fish")
                        .focused($fieldFocused)
                    textArea("Description (traduction)", text: $store.descriptionEn,
                             placeholder: "Shown to customers who read the menu in English")
                }
                .padding(.top, 12)
            } label: {
                Text("Traduction anglaise")
                    .font(.atfBody)
                    .foregroundStyle(Color.atfText1)
            }
            .tint(Color.atfAccent)
        }
        .padding(.horizontal, 20)
        .disabled(store.isDishCreated)
    }

    private func textArea(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.atfCaption)
                .foregroundStyle(Color.atfText2)
            TextField(placeholder, text: text, axis: .vertical)
                .lineLimit(3...6)
                .font(.atfBody)
                .foregroundStyle(Color.atfText1)
                .padding(12)
                .background(Color.atfSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.atfBorder, lineWidth: 1))
                .focused($fieldFocused)
                .accessibilityLabel(label)
        }
    }

    // MARK: - Gallery (extra photos)

    private var gallerySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Photos supplémentaires")
                .font(.atfCaption)
                .foregroundStyle(Color.atfText2)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(store.gallery, id: \.self) { url in
                        AsyncImage(url: url) { phase in
                            if let image = phase.image { image.resizable().scaledToFill() } else { Color.atfSurface2 }
                        }
                        .frame(width: 76, height: 76)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(alignment: .topTrailing) {
                            Button {
                                Task { await store.removeGalleryPhoto(url, networking: networking) }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .black.opacity(0.6))
                                    .frame(width: 32, height: 32)
                            }
                            .accessibilityLabel("Retirer cette photo")
                        }
                    }
                    PhotosPicker(selection: $pickedGalleryItem, matching: .images) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).fill(Color.atfAccentMuted)
                            if store.isUpdatingGallery {
                                ProgressView().tint(Color.atfAccent)
                            } else {
                                Image(systemName: "plus").font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(Color.atfAccent)
                            }
                        }
                        .frame(width: 76, height: 76)
                    }
                    .disabled(store.isUpdatingGallery)
                    .accessibilityLabel("Ajouter une photo supplémentaire")
                    .accessibilityIdentifier("addGalleryPhotoButton")
                }
            }
            Text("Affichées dans la fiche du plat sur votre menu, après la photo principale.")
                .font(.atfCaption)
                .foregroundStyle(Color.atfText3)
        }
        .padding(.horizontal, 20)
        .disabled(store.isUpdatingGallery)
        .onChange(of: pickedGalleryItem) { _, item in
            guard let item else { return }
            pickedGalleryItem = nil
            Task {
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let jpeg = await UIImage(data: data)?.uploadJPEG() else {
                    store.error = "Impossible d'ouvrir cette photo. Choisissez-en une autre."
                    return
                }
                await store.addGalleryPhoto(jpeg, networking: networking)
            }
        }
    }

    // MARK: - Save

    private var saveButton: some View {
        ATFButton(
            store.isDishCreated ? "Réessayer l'envoi de la photo" : (store.isEditing ? "Enregistrer les modifications" : "Enregistrer"),
            kind: .primary,
            fullWidth: true,
            loading: store.isLoading,
            disabled: !store.isValid
        ) {
            fieldFocused = false
            Task {
                await store.submit(networking: networking)
                if store.error == nil {
                    onSaved()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("DishFormView") {
    DishFormView(
        store: FormStore(restaurant: Restaurant.mocks[0]),
        networking: MockNetworking(),
        onSaved: {},
        onBack: {}
    )
}
