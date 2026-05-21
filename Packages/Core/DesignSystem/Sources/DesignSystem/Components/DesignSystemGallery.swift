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
