import SwiftUI
import Models
import DesignSystem

public struct NewCategorySheet: View {
    @State private var name: String = ""
    let onCreated: (String) -> Void
    let onDismiss: () -> Void

    public init(
        onCreated: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.onCreated = onCreated
        self.onDismiss = onDismiss
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    public var body: some View {
        ZStack {
            Color.atfSurface.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Nouvelle catégorie")
                    .font(.atfHeadline)
                    .foregroundStyle(Color.atfText1)
                    .padding(.top, 24)

                ATFTextField("Nom de la catégorie", text: $name, placeholder: "Ex: Grillades")
                    .padding(.horizontal, 20)

                ATFButton("Créer", kind: .primary, fullWidth: true, disabled: !isValid) {
                    let trimmed = name.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    onCreated(trimmed)
                }
                .padding(.horizontal, 20)

                ATFButton("Annuler", kind: .ghost) { onDismiss() }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview("NewCategorySheet") {
    NewCategorySheet(onCreated: { _ in }, onDismiss: {})
}
