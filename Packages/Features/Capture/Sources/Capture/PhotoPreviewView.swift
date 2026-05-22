import SwiftUI
import Models
import DesignSystem

// MARK: - PhotoPreviewView (Screen S06)

public struct PhotoPreviewView: View {
    @Bindable var store: CaptureStore
    let onRetake: () -> Void
    let onUse: () -> Void

    public init(
        store: CaptureStore,
        onRetake: @escaping () -> Void,
        onUse: @escaping () -> Void
    ) {
        self.store = store
        self.onRetake = onRetake
        self.onUse = onUse
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Full-screen photo
            if let image = store.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }

            // Overlay
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: { onRetake() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                    Text("Aperçu")
                        .font(.atfHeadline)
                        .foregroundStyle(.white)
                    Spacer()
                    // Balance spacer
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer()

                // Bottom bar
                HStack(spacing: 12) {
                    ATFButton("Reprendre", kind: .ghost, action: { onRetake() })
                    ATFButton("Utiliser cette photo", kind: .primary, action: { onUse() })
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .statusBarHidden()
    }
}

// MARK: - Preview

#Preview("PhotoPreviewView") {
    PhotoPreviewView(
        store: CaptureStore(restaurant: Restaurant.mocks[0]),
        onRetake: {},
        onUse: {}
    )
}
