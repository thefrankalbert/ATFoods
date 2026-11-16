import SwiftUI
import UIKit

public extension View {
    /// Stops the back gestures (edge swipe, and swipe from anywhere on iOS 26+) while `locked`: unsaved edit, upload in
    /// progress. Hiding the back button alone does not reliably stop them on a device. Pair it with
    /// navigationBarBackButtonHidden(locked).
    func backGestureLocked(_ locked: Bool) -> some View {
        background(BackGestureLock(locked: locked))
    }
}

private struct BackGestureLock: UIViewControllerRepresentable {
    let locked: Bool

    func makeUIViewController(context: Context) -> Controller { Controller() }

    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.locked = locked
    }

    final class Controller: UIViewController {
        var locked = false { didSet { if isOnScreen { apply(locked) } } }
        private var isOnScreen = false

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            isOnScreen = true
            apply(locked)
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            isOnScreen = false
            apply(false)   // the screen pushed on top, or the one we go back to, swipes normally
        }

        private func apply(_ locked: Bool) {
            guard let navigation = navigationController else { return }
            navigation.interactivePopGestureRecognizer?.isEnabled = !locked
            if #available(iOS 26, *) { navigation.interactiveContentPopGestureRecognizer?.isEnabled = !locked }
        }
    }
}
