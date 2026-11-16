import SwiftUI

public extension View {
    /// Acts like a button for a tap only. A SwiftUI Button also fires when a swipe ends inside it, and a full-width card or
    /// row is wide enough to hold a whole horizontal swipe (a back swipe picked a restaurant on iPad). The tap gesture
    /// fails as soon as the finger moves. Keeps the button role for VoiceOver.
    func tapOnly(_ label: String? = nil, action: @escaping () -> Void) -> some View {
        contentShape(Rectangle())
            .onTapGesture(perform: action)
            .accessibilityElement(children: label == nil ? .combine : .ignore)
            .accessibilityAddTraits(.isButton)
            .modifier(OptionalLabel(label: label))
            .accessibilityAction(.default, action)
    }
}

private struct OptionalLabel: ViewModifier {
    let label: String?
    func body(content: Content) -> some View {
        if let label { content.accessibilityLabel(label) } else { content }
    }
}
