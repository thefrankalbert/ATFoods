import SwiftUI
import DesignSystem
import Models
import Networking

private extension Color {
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

public struct BackgroundsView: View {
    @Bindable var store: AIRetouchStore
    let networking: any ATFNetworking
    let onApplied: () -> Void
    let onBack: () -> Void

    @State private var selected: String?

    public init(
        store: AIRetouchStore,
        networking: any ATFNetworking,
        onApplied: @escaping () -> Void,
        onBack: @escaping () -> Void
    ) {
        self.store = store; self.networking = networking
        self.onApplied = onApplied; self.onBack = onBack
    }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    public var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(BackgroundOption.options) { option in
                        backgroundCard(option)
                    }
                }
                .padding(16)
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
            Text("Arrière-plans")
                .font(.atfHeadline)
                .foregroundStyle(Color.atfText1)
            Spacer()
            Color.clear.frame(width: 24)
        }
        .padding(.horizontal, 16)
        .padding(.top, 52)
        .padding(.bottom, 14)
    }

    // MARK: - Background Card

    private func backgroundCard(_ option: BackgroundOption) -> some View {
        let isSelected = selected == option.id
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) { selected = option.id }
        } label: {
            ZStack(alignment: .bottom) {
                Group {
                    if let url = option.previewURL {
                        ATFAsyncImage(
                            url: url,
                            fallback: Color(hexString: option.colorHex),
                            radius: 12, height: 120, overlay: false, contentMode: .fill
                        )
                        .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)
                        .clipped()
                    } else {
                        Color(hexString: option.colorHex)
                            .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(option.name)
                    .font(.atfCaption)
                    .foregroundStyle(
                        option.colorHex == "FFFFFF" ? Color.atfText1 : Color.white
                    )
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? Color.atfAccent : Color.atfBorder,
                        lineWidth: isSelected ? 2.5 : 1
                    )
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.atfAccent)
                        .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - CTA Bar

    private var ctaBar: some View {
        VStack(spacing: 0) {
            Divider()
            ATFButton(
                selected != nil ? "Appliquer · 2 crédits" : "Choisir un fond",
                kind: .primary,
                fullWidth: true,
                loading: store.isProcessing,
                disabled: selected == nil
            ) {
                guard let bg = selected else { return }
                Task {
                    await store.changeBackground(bg, networking: networking)
                    onApplied()
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .background(Color.atfSurface)
    }
}

// MARK: - Preview

#Preview("BackgroundsView") {
    let store = AIRetouchStore(dishID: UUID(), creditsBalance: 5)
    return BackgroundsView(store: store, networking: MockNetworking(), onApplied: {}, onBack: {})
}
