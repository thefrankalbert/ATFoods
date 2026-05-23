import SwiftUI
import DesignSystem

public struct UpgradeSheet: View {
    let onDismiss: () -> Void

    public init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.atfBorder)
                .frame(width: 40, height: 4)
                .padding(.top, 12)

            VStack(spacing: 8) {
                ATFBadge("PRO", kind: .pro, icon: .star)
                    .padding(.top, 28)

                Text("Passez au Pro")
                    .font(.atfTitle)
                    .foregroundStyle(Color.atfText1)

                Text("Accédez à toutes les fonctionnalités IA")
                    .font(.atfSubhead)
                    .foregroundStyle(Color.atfText2)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 14) {
                featureRow("IA illimitée", systemIcon: "sparkles")
                featureRow("Suppression de fond", systemIcon: "wand.and.rays")
                featureRow("Changement de fond", systemIcon: "photo.fill.on.rectangle.fill")
                featureRow("Galerie HD illimitée", systemIcon: "photo.stack")
                featureRow("Support prioritaire", systemIcon: "headphones")
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)

            Spacer()

            VStack(spacing: 4) {
                Text("9 900 FCFA")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.atfText1)
                Text("par mois · sans engagement")
                    .font(.atfCaption)
                    .foregroundStyle(Color.atfText2)
            }
            .padding(.top, 28)

            ATFButton("Passer au Pro", kind: .primary, fullWidth: true, icon: .sparkles) {
                onDismiss()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Button(action: onDismiss) {
                Text("Continuer avec le plan Gratuit")
                    .font(.atfCaption)
                    .foregroundStyle(Color.atfText3)
            }
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(Color.atfBg)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    private func featureRow(_ title: String, systemIcon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemIcon)
                .font(.system(size: 16))
                .foregroundStyle(Color.atfAccent)
                .frame(width: 24)
            Text(title)
                .font(.atfSubhead)
                .foregroundStyle(Color.atfText1)
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.atfSuccess)
        }
    }
}

// MARK: - Preview

#Preview("UpgradeSheet") {
    UpgradeSheet(onDismiss: {})
}
