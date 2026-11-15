import SwiftUI
import PhotosUI
import Models
import Networking
import DesignSystem

/// New dish (from a photo) or dish card (edit name, price, availability, category, photo).
/// Grouped sections on Ivory, like iOS Settings; one primary action at the bottom.
public struct DishFormView: View {
    @Bindable var store: FormStore
    let networking: any ATFNetworking
    let onSaved: () -> Void
    /// Edit mode only: open the guided camera to replace this dish's photo.
    let onChangePhoto: (@MainActor () -> Void)?

    @State private var showCategorySheet = false
    @State private var confirmDiscard = false
    @State private var pickedGalleryItem: PhotosPickerItem?
    @State private var showTranslation = false
    @FocusState private var fieldFocused: Bool
    @Environment(\.dismiss) private var dismiss

    public init(
        store: FormStore,
        networking: any ATFNetworking,
        onSaved: @escaping () -> Void,
        onChangePhoto: (@MainActor () -> Void)? = nil
    ) {
        self.store = store
        self.networking = networking
        self.onSaved = onSaved
        self.onChangePhoto = onChangePhoto
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    photoSection
                    mainSection
                    categorySection
                    visibilitySection
                    if store.isEditing { gallerySection }
                    detailsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            // Hidden while typing: above the keyboard it covered the price field and the "Terminé" bar.
            if !fieldFocused { saveBar }
        }
        .background(Color.atfBg.ignoresSafeArea())
        .atfScreen(store.isEditing ? "Fiche plat" : "Nouveau plat")
        // Unsaved input: the system back button and swipe give way to a button that asks first.
        // Mid-save: no way out, the save pops the screen itself.
        .navigationBarBackButtonHidden(store.hasUnsavedChanges || store.isLoading)
        .backGestureLocked(store.hasUnsavedChanges || store.isLoading)
        .toolbar {
            if store.hasUnsavedChanges && !store.isLoading {
                ToolbarItem(placement: .topBarLeading) {
                    Button { confirmDiscard = true } label: { Image(systemName: "chevron.left") }
                        .tint(Color.atfText1)
                        .accessibilityLabel("Retour")
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Terminé") { fieldFocused = false }
            }
        }
        .task { await store.loadCategories(networking: networking) }
        // Values are right-aligned: a tap left of the text would put the cursor before it ("6900" typed on "6500"
        // gave "69006500"). Start editing at the end, like the Settings app.
        .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { note in
            guard let field = note.object as? UITextField else { return }
            DispatchQueue.main.async {
                field.selectedTextRange = field.textRange(from: field.endOfDocument, to: field.endOfDocument)
            }
        }
        .confirmationDialog("Abandonner les modifications ?", isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button("Abandonner", role: .destructive) { dismiss() }
            Button("Continuer la modification", role: .cancel) {}
        }
        .sheet(isPresented: $showCategorySheet) {
            NewCategorySheet(store: store, networking: networking) { showCategorySheet = false }
        }
    }

    // MARK: - Photo

    private var photoSection: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let editing = store.editing {
                    remoteImage(editing.photoURL)
                } else {
                    switch store.photo {
                    case .captured(let image): Image(uiImage: image).resizable().scaledToFill()
                    case .draft(let draft): remoteImage(draft.photoURL)
                    case nil: placeholder
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .accessibilityHidden(true)

            if let onChangePhoto {
                Button(action: onChangePhoto) {
                    Label(store.editing?.photoURL == nil ? "Ajouter une photo" : "Changer la photo", systemImage: "camera")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.atfText1)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .background(Color.atfBg, in: Capsule())
                }
                .buttonStyle(ATFScaleButtonStyle())
                .disabled(store.isLoading)
                .padding(12)
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
                Color.atfSurface2.overlay(ProgressView().tint(Color.atfText2))
            }
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.atfSurface2
            Image(systemName: "photo").font(.title).foregroundStyle(Color.atfText3)
        }
    }

    // MARK: - Name & price

    private var mainSection: some View {
        ATFSection(footer: store.priceError) {
            fieldRow("Nom du plat") {
                TextField("Nom du plat", text: $store.name, prompt: Text("Ex. : Thiéboudienne"))
                    .textInputAutocapitalization(.sentences)
            }
            ATFRowDivider()
            fieldRow("Prix") {
                HStack(spacing: 6) {
                    TextField("Prix", text: $store.priceText, prompt: Text(store.allowsDecimals ? "12,50" : "3 800"))
                        .keyboardType(store.allowsDecimals ? .decimalPad : .numberPad)
                        .monospacedDigit()
                    Text(store.currencySymbol).foregroundStyle(Color.atfText2)
                }
            }
        }
        .disabled(store.isDishCreated)
        .tint(Color.atfText1)
    }

    private func fieldRow<Field: View>(_ label: String, @ViewBuilder field: () -> Field) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .foregroundStyle(Color.atfText1)
                .frame(width: 110, alignment: .leading)
                .accessibilityHidden(true)
            field()
                .multilineTextAlignment(.trailing)
                .focused($fieldFocused)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 50)
    }

    // MARK: - Category

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Catégorie")
                .font(.footnote)
                .foregroundStyle(Color.atfText2)
                .padding(.horizontal, 16)

            if !store.menusLoaded && !store.isLoadingCategories {
                HStack {
                    Text("Catégories non chargées.")
                        .font(.footnote)
                        .foregroundStyle(Color.atfDanger)
                    Spacer()
                    Button("Réessayer") { Task { await store.loadCategories(networking: networking) } }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.atfText1)
                }
                .padding(.horizontal, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if store.isLoadingCategories { ProgressView().tint(Color.atfText2) }
                        ATFChip(store.categories.isEmpty ? "Créer une catégorie" : "Nouvelle", icon: .plus, kind: .add) {
                            showCategorySheet = true
                        }
                        .accessibilityIdentifier("newCategoryButton")
                        ForEach(store.categories) { cat in
                            let isSelected = store.selectedCategoryID == cat.id
                            ATFChip(store.label(for: cat), selected: isSelected) { store.selectedCategoryID = cat.id }
                                .accessibilityAddTraits(isSelected ? .isSelected : [])
                        }
                    }
                }
                .contentMargins(.horizontal, 0)
            }
        }
        .disabled(store.isDishCreated)
        .sensoryFeedback(.selection, trigger: store.selectedCategoryID)
    }

    // MARK: - Visibility

    private var visibilitySection: some View {
        ATFSection {
            toggleRow("Disponible",
                      subtitle: store.isAvailable ? "Visible et commandable sur votre menu" : "Affiché « épuisé » sur votre menu",
                      isOn: $store.isAvailable)
            ATFRowDivider()
            toggleRow("À la une", subtitle: "Mis en avant en tête de votre menu", isOn: $store.isFeatured)
        }
        .disabled(store.isDishCreated)
    }

    private func toggleRow(_ title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).foregroundStyle(Color.atfText1)
                Text(subtitle).font(.footnote).foregroundStyle(Color.atfText2)
            }
        }
        .tint(Color.atfAccent)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)   // keep the switch's own on/off value
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Details (rest of the web dish sheet)

    private var detailsSection: some View {
        VStack(spacing: 24) {
            ATFSection("Description") {
                TextField("Description", text: $store.descriptionText,
                          prompt: Text("Ingrédients, accompagnement, cuisson…"), axis: .vertical)
                    .lineLimit(3...6)
                    .focused($fieldFocused)
                    .padding(16)
            }

            ATFSection("Allergènes") {
                FlowLayout(spacing: 8) {
                    ForEach(Allergen.all, id: \.id) { allergen in
                        let isOn = store.allergens.contains(allergen.id)
                        ATFChip(allergen.label, selected: isOn, tap: true) {
                            if isOn { store.allergens.remove(allergen.id) } else { store.allergens.insert(allergen.id) }
                        }
                        .accessibilityAddTraits(isOn ? .isSelected : [])
                    }
                }
                .padding(12)
            }

            ATFSection(footer: store.caloriesError) {
                fieldRow("Calories") {
                    HStack(spacing: 6) {
                        TextField("Calories", text: $store.caloriesText, prompt: Text("Ex. : 450"))
                            .keyboardType(.numberPad)
                            .monospacedDigit()
                        Text("kcal").foregroundStyle(Color.atfText2)
                    }
                }
            }

            ATFSection {
                DisclosureGroup(isExpanded: $showTranslation) {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Nom (traduction)", text: $store.nameEn, prompt: Text("Ex. : Grilled fish"))
                            .focused($fieldFocused)
                        Divider()
                        TextField("Description (traduction)", text: $store.descriptionEn,
                                  prompt: Text("Affichée aux clients qui lisent le menu en anglais"), axis: .vertical)
                            .lineLimit(2...5)
                            .focused($fieldFocused)
                    }
                    .padding(.top, 12)
                } label: {
                    Text("Traduction anglaise").foregroundStyle(Color.atfText1)
                }
                .tint(Color.atfText2)
                .padding(16)
            }
        }
        .disabled(store.isDishCreated)
        .tint(Color.atfText1)
    }

    // MARK: - Gallery (extra photos)

    private var gallerySection: some View {
        ATFSection("Photos supplémentaires", footer: "Affichées dans la fiche du plat sur votre menu, après la photo principale.") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(store.gallery, id: \.self) { url in
                        ATFRemoteImage(Thumbnail.url(url, points: 76), fallback: url) { Color.atfSurface2 }
                        .frame(width: 76, height: 76)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(alignment: .topTrailing) {
                            Button {
                                Task { await store.removeGalleryPhoto(url, networking: networking) }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(Color.atfAccentOn, Color.atfAccent.opacity(0.7))
                                    .frame(width: 44, height: 44)
                            }
                            .offset(x: 10, y: -10)
                            .accessibilityLabel("Retirer cette photo")
                        }
                    }
                    PhotosPicker(selection: $pickedGalleryItem, matching: .images) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8).fill(Color.atfSurface2)
                            if store.isUpdatingGallery {
                                ProgressView().tint(Color.atfText2)
                            } else {
                                Image(systemName: "plus").font(.title3.weight(.semibold)).foregroundStyle(Color.atfText1)
                            }
                        }
                        .frame(width: 76, height: 76)
                    }
                    .disabled(store.isUpdatingGallery)
                    .accessibilityLabel("Ajouter une photo supplémentaire")
                    .accessibilityIdentifier("addGalleryPhotoButton")
                }
                .padding(12)
            }
        }
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

    private var saveBar: some View {
        VStack(spacing: 8) {
            if let errorMsg = store.error {
                Label(errorMsg, systemImage: "exclamationmark.circle")
                    .font(.footnote)
                    .foregroundStyle(Color.atfDanger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let missing = store.missingFieldsHint, !store.isLoading {
                Text(missing)
                    .font(.footnote)
                    .foregroundStyle(Color.atfText2)
                    .multilineTextAlignment(.center)
            }
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
                    if store.error == nil { onSaved() }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color.atfBg)
        .sensoryFeedback(.success, trigger: store.isLoading) { was, now in was && !now && store.error == nil }
        .sensoryFeedback(.error, trigger: store.error) { _, new in new != nil }
    }
}

// Previews use DEBUG-only demo data (MockNetworking, .mocks): never compiled into Release.
#if DEBUG
// MARK: - Preview

#Preview("DishFormView") {
    DishFormView(
        store: FormStore(restaurant: Restaurant.mocks[0]),
        networking: MockNetworking(),
        onSaved: {}
    )
}
#endif
