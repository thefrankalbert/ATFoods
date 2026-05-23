import SwiftUI
import DesignSystem

public struct OfflineView: View {
    let pendingCount: Int
    let onRetry: () -> Void
    let onBack: () -> Void

    public init(pendingCount: Int = 0, onRetry: @escaping () -> Void, onBack: @escaping () -> Void) {
        self.pendingCount = pendingCount; self.onRetry = onRetry; self.onBack = onBack
    }

    public var body: some View {
        VStack(spacing: 0) {
            topBar
            Spacer()
            content
            Spacer()
            Spacer()
        }
        .background(Color.atfBg.ignoresSafeArea())
    }

    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.atfText1)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 52)
        .padding(.bottom, 14)
    }

    private var content: some View {
        VStack(spacing: 28) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 64))
                .foregroundStyle(Color.atfText3)

            VStack(spacing: 8) {
                Text("Pas de connexion")
                    .font(.atfHeadline)
                    .foregroundStyle(Color.atfText1)
                Text("Vérifiez votre réseau et réessayez")
                    .font(.atfBody)
                    .foregroundStyle(Color.atfText2)
                    .multilineTextAlignment(.center)
            }

            if pendingCount > 0 {
                queueCard
            }

            ATFButton("Réessayer", kind: .outline, fullWidth: false, icon: .reload) {
                onRetry()
            }
        }
        .padding(.horizontal, 32)
    }

    private var queueCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "tray.full.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color.atfWarning)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(pendingCount) photo\(pendingCount > 1 ? "s" : "") en attente")
                    .font(.atfBodyStr)
                    .foregroundStyle(Color.atfText1)
                Text("Synchronisation dès la reconnexion")
                    .font(.atfCaption)
                    .foregroundStyle(Color.atfText2)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.atfWarningBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview("OfflineView - avec queue") {
    OfflineView(pendingCount: 3, onRetry: {}, onBack: {})
}

#Preview("OfflineView - vide") {
    OfflineView(pendingCount: 0, onRetry: {}, onBack: {})
}
