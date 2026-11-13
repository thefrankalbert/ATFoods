import SwiftUI

/// Remote photo, cropped to fill. If `url` (usually a server-resized thumbnail) fails, tries `fallback`
/// (the original photo) before showing the placeholder: thumbnails keep working if resizing is ever unavailable.
public struct ATFRemoteImage<Placeholder: View>: View {
    let url: URL?
    let fallback: URL?
    let placeholder: Placeholder

    public init(_ url: URL?, fallback: URL? = nil, @ViewBuilder placeholder: () -> Placeholder) {
        self.url = url
        self.fallback = fallback
        self.placeholder = placeholder()
    }

    public var body: some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else if phase.error != nil, let fallback, fallback != url {
                AsyncImage(url: fallback) { second in
                    if let image = second.image { image.resizable().scaledToFill() } else { placeholder }
                }
            } else {
                placeholder
            }
        }
        .accessibilityHidden(true)
    }
}
