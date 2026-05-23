import SwiftUI
import DesignSystem
import Models
import Networking

public struct CreditsView: View {
    @Bindable var store: ProfileStore
    let onUpgrade: () -> Void
    let onBack: () -> Void

    public init(store: ProfileStore, onUpgrade: @escaping () -> Void, onBack: @escaping () -> Void) {
        self.store = store; self.onUpgrade = onUpgrade; self.onBack = onBack
    }

    public var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(spacing: 16) {
                    balanceCard
                    historySection
                }
                .padding(16)
                .padding(.bottom, 32)
            }
            ctaBar
        }
        .background(Color.atfBg.ignoresSafeArea())
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.atfText1)
            }
            Spacer()
            Text("Crédits IA")
                .font(.atfHeadline)
                .foregroundStyle(Color.atfText1)
            Spacer()
            Color.clear.frame(width: 24)
        }
        .padding(.horizontal, 16)
        .padding(.top, 52)
        .padding(.bottom, 14)
    }

    // MARK: - Balance Card

    private var balanceCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(store.creditsBalance)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.atfText1)
                Text("crédits")
                    .font(.atfSubhead)
                    .foregroundStyle(Color.atfText2)
            }

            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.atfSurface2)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color.atfAccent, Color.atfAccentHover],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("\(store.creditsTotal - store.creditsBalance) utilisés")
                        .font(.atfCaption)
                        .foregroundStyle(Color.atfText2)
                    Spacer()
                    Text("\(store.creditsTotal) au total")
                        .font(.atfCaption)
                        .foregroundStyle(Color.atfText3)
                }
            }
        }
        .padding(20)
        .background(Color.atfSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.atfBorder, lineWidth: 1)
        )
    }

    private var progress: CGFloat {
        guard store.creditsTotal > 0 else { return 0 }
        return max(0, min(1, CGFloat(store.creditsBalance) / CGFloat(store.creditsTotal)))
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Historique")
                .font(.atfSubhead)
                .foregroundStyle(Color.atfText2)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(store.creditHistory) { entry in
                    historyRow(entry)
                    if entry.id != store.creditHistory.last?.id {
                        Divider().padding(.horizontal, 16)
                    }
                }
            }
            .background(Color.atfSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.atfBorder, lineWidth: 1)
            )
        }
    }

    private func historyRow(_ entry: CreditEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: entry.amount > 0 ? "plus.circle.fill" : "minus.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(entry.amount > 0 ? Color.atfSuccess : Color.atfText3)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.description)
                    .font(.atfSubhead)
                    .foregroundStyle(Color.atfText1)
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.atfCaption)
                    .foregroundStyle(Color.atfText3)
            }

            Spacer()

            Text(entry.amount > 0 ? "+\(entry.amount)" : "\(entry.amount)")
                .font(.atfBodyStr)
                .foregroundStyle(entry.amount > 0 ? Color.atfSuccess : Color.atfText1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - CTA

    private var ctaBar: some View {
        VStack(spacing: 0) {
            Divider()
            ATFButton("Obtenir plus de crédits", kind: .primary, fullWidth: true, icon: .sparkles) {
                onUpgrade()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .background(Color.atfSurface)
    }
}

// MARK: - Preview

#Preview("CreditsView") {
    let store = ProfileStore(user: AppUser.mock, restaurant: Restaurant.mocks[0])
    return CreditsView(store: store, onUpgrade: {}, onBack: {})
}
