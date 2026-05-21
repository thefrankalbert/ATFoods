// Packages/Core/DesignSystem/Sources/DesignSystem/Components/ATFSheet.swift
import SwiftUI

/// Wrapper pour présenter du contenu en bottom sheet avec grab handle.
/// Utilise .presentationDetents natif iOS 16+.
public struct ATFSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let detents: Set<PresentationDetent>
    let sheetContent: @MainActor () -> SheetContent

    public init(
        isPresented: Binding<Bool>,
        detents: Set<PresentationDetent>,
        sheetContent: @escaping @MainActor () -> SheetContent
    ) {
        self._isPresented = isPresented
        self.detents = detents
        self.sheetContent = sheetContent
    }

    public func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                VStack(spacing: 0) {
                    // Grab handle
                    Capsule()
                        .fill(Color.atfText3.opacity(0.4))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)
                        .padding(.bottom, 14)

                    sheetContent()
                }
                .presentationDetents(detents)
                .presentationDragIndicator(.hidden)
                .background(Color.atfBg)
            }
    }
}

public extension View {
    func atfSheet<Content: View>(
        isPresented: Binding<Bool>,
        detents: Set<PresentationDetent> = [.medium],
        @ViewBuilder content: @escaping @MainActor () -> Content
    ) -> some View {
        modifier(ATFSheetModifier(isPresented: isPresented, detents: detents, sheetContent: content))
    }
}
