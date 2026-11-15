// Packages/Core/DesignSystem/Sources/DesignSystem/Icons/ATFIcon.swift
import SwiftUI

public enum ATFIcon: String, CaseIterable, Sendable {
    case camera      = "camera"
    case cameraFill  = "camera.fill"
    case cameraSlash = "camera.slash"
    case plus        = "plus"
    case minus       = "minus"
    case check       = "checkmark"
    case checkCircle = "checkmark.circle"
    case x           = "xmark"
    case xCircle     = "xmark.circle"
    case chevRight   = "chevron.right"
    case chevLeft    = "chevron.left"
    case chevDown    = "chevron.down"
    case chevUp      = "chevron.up"
    case search      = "magnifyingglass"
    case user        = "person"
    case userCircle  = "person.circle"
    case settings    = "gearshape"
    case sparkles    = "sparkles"
    case fork        = "fork.knife"
    case tag         = "tag"
    case tray        = "tray"
    case upRight     = "arrow.up.forward.circle"
    case alert       = "exclamationmark.triangle"
    case reload      = "arrow.clockwise.circle"
    case wifiSlash   = "wifi.slash"
    case flash       = "bolt.fill"
    case flashOff    = "bolt.slash.fill"
    case flip        = "arrow.triangle.2.circlepath.camera"
    case arrowLeft   = "arrow.left"
    case bell        = "bell"
    case trash       = "trash"
    case drag        = "line.3.horizontal"
    case more        = "ellipsis"
    case faceId      = "faceid"
    case globe       = "globe"
    case bug         = "ant"
    case info        = "info.circle"
    case out         = "arrow.right.square"
    case star        = "star.fill"
    case coins       = "dollarsign.circle"
    case history     = "clock.arrow.circlepath"
    case filter      = "line.3.horizontal.decrease.circle"
    case scan        = "viewfinder"
    case download    = "arrow.down"
    case pencil      = "pencil"
    case shieldCheck = "checkmark.shield"

    public var systemName: String { rawValue }
}

// MARK: - ATFIconView

public struct ATFIconView: View {
    let icon: ATFIcon
    let size: CGFloat
    let color: Color?

    public init(_ icon: ATFIcon, size: CGFloat = 22, color: Color? = nil) {
        self.icon = icon
        self.size = size
        self.color = color
    }

    public var body: some View {
        Image(systemName: icon.systemName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(color ?? Color.primary)
            .accessibilityHidden(true)
    }
}

// Previews use DEBUG-only demo data (MockNetworking, .mocks): never compiled into Release.
#if DEBUG
// MARK: - Preview

#Preview("ATFIcon grid") {
    let icons: [ATFIcon] = [.camera, .cameraFill, .plus, .check, .x, .chevRight,
                             .search, .user, .settings, .sparkles, .fork, .tag,
                             .flash, .flashOff, .trash, .star, .bell, .more]
    return ScrollView {
        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 16) {
            ForEach(icons, id: \.self) { icon in
                VStack(spacing: 4) {
                    ATFIconView(icon, size: 24, color: .atfAccent)
                    Text(icon.rawValue)
                        .font(.system(size: 7))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}
#endif
