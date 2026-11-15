import SwiftUI

/// Button for the black camera screens, where Slate buttons would disappear: Ivory fill, or translucent white.
public struct ATFDarkButton: View {
    let label: String
    let prominent: Bool
    let isDisabled: Bool
    let action: @MainActor () -> Void

    public init(_ label: String, prominent: Bool = true, disabled: Bool = false, action: @escaping @MainActor () -> Void) {
        self.label = label
        self.prominent = prominent
        self.isDisabled = disabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(label)
                .font(.atfBodyStr)
                .foregroundStyle(prominent ? Color.atfText1 : Color.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .padding(.horizontal, 16)
                .background(prominent ? AnyShapeStyle(Color.atfBg) : AnyShapeStyle(Color.white.opacity(0.18)), in: Capsule())
        }
        .buttonStyle(ATFScaleButtonStyle())
        .opacity(isDisabled ? 0.4 : 1)
        .disabled(isDisabled)
    }
}
