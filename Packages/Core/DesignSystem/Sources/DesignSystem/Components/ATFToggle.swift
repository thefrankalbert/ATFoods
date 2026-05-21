// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFToggle.swift
import SwiftUI

/// iOS-style custom toggle. orange=true → accent orange au lieu de success vert.
public struct ATFToggle: View {
    @Binding var isOn: Bool
    let isOrange: Bool

    public init(isOn: Binding<Bool>, orange: Bool = false) {
        self._isOn = isOn
        self.isOrange = orange
    }

    public var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            RoundedRectangle(cornerRadius: ATFRadius.pill)
                .fill(isOn ? (isOrange ? Color.atfAccent : Color.atfSuccess) : Color.atfSurface2)
                .frame(width: 51, height: 31)
                .overlay(
                    RoundedRectangle(cornerRadius: ATFRadius.pill)
                        .strokeBorder(Color.atfBorder, lineWidth: 1)
                )

            Circle()
                .fill(Color.white)
                .frame(width: 25, height: 25)
                .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
                .padding(2)
        }
        .frame(width: 51, height: 31)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isOn)
        .onTapGesture { isOn.toggle() }
    }
}

#Preview("ATFToggle") {
    @Previewable @State var a = true
    @Previewable @State var b = false
    @Previewable @State var c = true

    VStack(spacing: 24) {
        HStack { Text("Disponible (vert)"); Spacer(); ATFToggle(isOn: $a) }
        HStack { Text("Mis en avant (orange)"); Spacer(); ATFToggle(isOn: $b, orange: true) }
        HStack { Text("Off"); Spacer(); ATFToggle(isOn: $c) }
    }
    .padding()
}
