import SwiftUI
import Models
import DesignSystem

public struct NewCategorySheet: View {
    let onSelect: (MenuCategory) -> Void
    let onDismiss: () -> Void

    public init(
        onSelect: @escaping (MenuCategory) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.onSelect = onSelect
        self.onDismiss = onDismiss
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    public var body: some View {
        ZStack {
            Color.atfSurface.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Choisir une catégorie")
                    .font(.atfHeadline)
                    .foregroundStyle(Color.atfText1)
                    .padding(.top, 24)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(MenuCategory.allCases, id: \.self) { category in
                        categoryCard(category)
                    }
                }
                .padding(.horizontal, 20)

                ATFButton("Annuler", kind: .ghost) { onDismiss() }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
        }
    }

    private func categoryCard(_ category: MenuCategory) -> some View {
        Button {
            onSelect(category)
        } label: {
            VStack(spacing: 10) {
                Image(systemName: icon(for: category))
                    .font(.system(size: 28))
                    .foregroundStyle(Color.atfAccent)
                Text(category.rawValue)
                    .font(.atfBody)
                    .foregroundStyle(Color.atfText1)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.atfSurface2)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func icon(for category: MenuCategory) -> String {
        switch category {
        case .entree:     return "fork.knife"
        case .plat:       return "takeoutbag.and.cup.and.straw"
        case .grillades:  return "flame"
        case .specialite: return "star"
        case .boisson:    return "cup.and.saucer"
        case .dessert:    return "birthday.cake"
        }
    }
}

#Preview("NewCategorySheet") {
    NewCategorySheet(onSelect: { _ in }, onDismiss: {})
}
