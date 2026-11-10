import SwiftUI

/// Screen header shared by every pushed screen: back chevron, centered title, optional trailing control.
public struct ATFHeader<Trailing: View>: View {
    let title: String
    let backDisabled: Bool
    let onBack: () -> Void
    let trailing: Trailing

    public init(_ title: String, backDisabled: Bool = false, onBack: @escaping () -> Void,
                @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.backDisabled = backDisabled
        self.onBack = onBack
        self.trailing = trailing()
    }

    public var body: some View {
        ZStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.atfText1)
                .lineLimit(1)
                .padding(.horizontal, 56)
                .accessibilityAddTraits(.isHeader)
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.atfText1)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .disabled(backDisabled)
                .accessibilityLabel("Retour")
                Spacer()
                trailing
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 52)
        .background(Color.atfBg)
    }
}

public extension ATFHeader where Trailing == EmptyView {
    init(_ title: String, backDisabled: Bool = false, onBack: @escaping () -> Void) {
        self.init(title, backDisabled: backDisabled, onBack: onBack) { EmptyView() }
    }
}

/// Grouped section on Ivory, like iOS Settings: footnote title, white rounded card.
public struct ATFSection<Content: View>: View {
    let title: String?
    let footer: String?
    let content: Content

    public init(_ title: String? = nil, footer: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.footer = footer
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(Color.atfText2)
                    .padding(.horizontal, 16)
            }
            VStack(alignment: .leading, spacing: 0) { content }
                .background(Color.atfField, in: RoundedRectangle(cornerRadius: 12))
            if let footer {
                Text(footer)
                    .font(.footnote)
                    .foregroundStyle(Color.atfText2)
                    .padding(.horizontal, 16)
            }
        }
    }
}

/// Hairline between rows of an ATFSection, inset like iOS lists.
public struct ATFRowDivider: View {
    public init() {}
    public var body: some View {
        Rectangle().fill(Color.atfBorder).frame(height: 0.5).padding(.leading, 16)
    }
}
