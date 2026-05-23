import SwiftUI
import Models
import Networking
import DesignSystem

public struct DishFormView: View {
    @Bindable var store: FormStore
    let networking: any ATFNetworking
    let onSaved: () -> Void
    let onBack: () -> Void

    @State private var showCategorySheet = false

    public init(
        store: FormStore,
        networking: any ATFNetworking,
        onSaved: @escaping () -> Void,
        onBack: @escaping () -> Void
    ) {
        self.store = store
        self.networking = networking
        self.onSaved = onSaved
        self.onBack = onBack
    }

    public var body: some View {
        ZStack {
            Color.atfSurface.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 20) {
                        photoSection
                        fieldsSection
                        categorySection
                        availabilityRow
                        if let errorMsg = store.error {
                            Text(errorMsg)
                                .font(.atfCaption)
                                .foregroundStyle(Color.atfDanger)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }
            }

            VStack {
                Spacer()
                saveButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    .background(
                        Color.atfSurface
                            .ignoresSafeArea(edges: .bottom)
                    )
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.atfAccent)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("Nouveau plat")
                .font(.atfHeadline)
                .foregroundStyle(Color.atfText1)

            Spacer()

            // Balance the back button
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        Group {
            if let image = store.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if let url = store.photoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    case .failure:
                        photoPlaceholder
                    default:
                        Color.atfSurface2
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            } else {
                photoPlaceholder
            }
        }
    }

    private var photoPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.atfSurface2)
            .frame(width: 120, height: 120)
            .overlay(
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Color.atfText3)
            )
    }

    // MARK: - Fields

    private var fieldsSection: some View {
        VStack(spacing: 16) {
            ATFTextField("Nom du plat", text: $store.name, placeholder: "Ex: Thieboudienne")
            ATFTextField("Prix", text: $store.priceText, placeholder: "3 800", suffix: "FCFA")
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Category Picker

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Catégorie")
                .font(.atfCaption)
                .foregroundStyle(Color.atfText2)
                .padding(.leading, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MenuCategory.allCases, id: \.self) { cat in
                        categoryChip(cat)
                    }
                    Button {
                        showCategorySheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.atfCaption)
                            .foregroundStyle(Color.atfAccent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Color.atfSurface2)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showCategorySheet) {
            NewCategorySheet(
                onSelect: { cat in
                    store.category = cat
                    showCategorySheet = false
                },
                onDismiss: { showCategorySheet = false }
            )
        }
    }

    private func categoryChip(_ cat: MenuCategory) -> some View {
        let isSelected = store.category == cat
        return Button {
            store.category = cat
        } label: {
            Text(cat.displayName)
                .font(.atfCaption)
                .foregroundStyle(isSelected ? Color.white : Color.atfText2)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.atfAccent : Color.atfSurface2)
                .clipShape(Capsule())
        }
    }

    // MARK: - Availability

    private var availabilityRow: some View {
        HStack {
            Text("Disponible")
                .font(.atfBody)
                .foregroundStyle(Color.atfText1)
            Spacer()
            ATFToggle(isOn: $store.isAvailable)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        ATFButton(
            "Enregistrer",
            kind: .primary,
            fullWidth: true,
            loading: store.isLoading,
            disabled: !store.isValid
        ) {
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
