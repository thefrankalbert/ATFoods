import SwiftUI
import Vision
import Mantis
import Models
import DesignSystem

// MARK: - PhotoPreviewView (Screen S06)

public struct PhotoPreviewView: View {
    @Bindable var store: CaptureStore
    let onRetake: () -> Void
    let onUse: () -> Void

    @State private var showCropper = false
    @State private var qualityWarning: String?
    @State private var originalImage: UIImage?   // set while the white background is applied
    @State private var isRemovingBackground = false
    @State private var backgroundError: String?
    @State private var backgroundTask: Task<Void, Never>?

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

            // Full photo (fit, so the user sees exactly what will be uploaded)
            if let image = store.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }

            // Overlay
            VStack(spacing: 12) {
                // Top bar
                HStack {
                    Button(action: { onRetake() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Retour")
                    Spacer()
                    Text("Aperçu")
                        .font(.atfHeadline)
                        .foregroundStyle(.white)
                    Spacer()
                    Button(action: { showCropper = true }) {
                        Image(systemName: "crop.rotate")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Recadrer")
                    .disabled(isRemovingBackground)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                if let qualityWarning {
                    Label(qualityWarning, systemImage: "exclamationmark.triangle.fill")
                        .font(.atfCaption)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.atfWarning, in: Capsule())
                        .padding(.horizontal, 20)
                }

                Spacer()

                if let backgroundError {
                    Text(backgroundError)
                        .font(.atfCaption)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                backgroundToggle

                // Bottom bar
                HStack(spacing: 12) {
                    // Locked while the cutout runs, so it can't swap the photo after the user moved on.
                    ATFButton("Reprendre", kind: .ghost, disabled: isRemovingBackground, action: { onRetake() })
                    ATFButton("Utiliser cette photo", kind: .primary, disabled: isRemovingBackground, action: { onUse() })
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .statusBarHidden()
        .onDisappear {
            backgroundTask?.cancel()
            isRemovingBackground = false
        }
        .task(id: store.capturedImage) { await checkQuality() }
        .fullScreenCover(isPresented: $showCropper) {
            if let image = store.capturedImage {
                ImageCropper(image: image)
                    .onCrop { result in
                        store.capturedImage = result.croppedImage
                        originalImage = nil   // crop becomes the new baseline
                        showCropper = false
                    }
                    .onCancel { showCropper = false }
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - White background (on-device, free)

    private var backgroundToggle: some View {
        Button(action: toggleBackground) {
            HStack(spacing: 8) {
                if isRemovingBackground {
                    ProgressView().tint(.black)
                } else {
                    Image(systemName: originalImage == nil ? "wand.and.stars" : "arrow.uturn.backward")
                }
                Text(originalImage == nil ? "Fond blanc" : "Fond d'origine")
                    .font(.atfCaption)
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.white, in: Capsule())
        }
        .disabled(isRemovingBackground || store.capturedImage == nil)
        .accessibilityIdentifier("whiteBackgroundButton")
    }

    private func toggleBackground() {
        backgroundError = nil
        if let originalImage {
            store.capturedImage = originalImage
            self.originalImage = nil
            return
        }
        guard let image = store.capturedImage else { return }
        isRemovingBackground = true
        backgroundTask = Task {
            do {
                let result = try await BackgroundRemover.replaceBackground(of: image)
                guard !Task.isCancelled else { return }
                originalImage = image
                store.capturedImage = result
            } catch {
                if !Task.isCancelled { backgroundError = error.localizedDescription }
            }
            isRemovingBackground = false
        }
    }

    /// Apple's on-device aesthetics score (iOS 18+): flags blurry / badly exposed shots.
    /// Advisory only; silently skipped on iOS 17 and the simulator.
    private func checkQuality() async {
        qualityWarning = nil
        guard #available(iOS 18.0, *), let cgImage = store.capturedImage?.cgImage else { return }
        let request = CalculateImageAestheticsScoresRequest()
        guard let result = try? await request.perform(on: cgImage) else { return }
        // ponytail: threshold picked from Apple's -1...1 scale; tune with real restaurant photos.
        if result.overallScore < -0.2 {
            qualityWarning = "Photo un peu floue ou sombre. Reprendre ?"
        }
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
