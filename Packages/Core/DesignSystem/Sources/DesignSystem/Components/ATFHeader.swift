import SwiftUI

public extension View {
    /// Native navigation bar for a pushed screen: system back button and back swipe, inline title, Ivory bar.
    func atfScreen(_ title: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.atfBg, for: .navigationBar)
            .toolbarRole(.editor)   // back chevron without the previous screen's title
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
