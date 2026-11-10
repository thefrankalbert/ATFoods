// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFToggle.swift
import SwiftUI

/// Brand toggle. orange=true → accent orange au lieu de success vert.
public struct ATFToggle: View {
    @Binding var isOn: Bool
    let isOrange: Bool

    public init(isOn: Binding<Bool>, orange: Bool = false) {
        self._isOn = isOn
        self.isOrange = orange
    }

    // ponytail: native Toggle (VoiceOver, hit area, haptics) with the brand tint.
    public var body: some View {
        Toggle("", isOn: $isOn)
            .labelsHidden()
            .tint(Color.atfAccent)   // Slate in both cases: no coloured toggles
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
