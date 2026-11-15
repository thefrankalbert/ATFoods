import XCTest

/// Checks only a real device can answer: the live camera (permission, preview, shutter, photo preview) and the
/// back swipe from the screen edge. Mock backend, real hardware. Skipped on the simulator. Run it on a plugged-in device:
///   xcodebuild test -workspace ATFood.xcworkspace -scheme ATFood -destination 'id=<device udid>' -only-testing:ATFoodUITests/DeviceTest
final class DeviceTest: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("Needs a real camera and touch screen")
        #else
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]   // mock backend, real camera
        app.launch()
        #endif
    }

    func testCameraAndBackSwipeOnDevice() throws {
        if app.buttons["Passer"].waitForExistence(timeout: 5) { app.buttons["Passer"].tap() }
        signIn()

        // Swipe right goes back from every pushed screen. Swipe on the window: on iPad it is not at the screen origin.
        let window = app.windows.firstMatch
        let dish = { self.app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Thieboudienne'")).firstMatch.tap() }
        let screens: [(String, () -> Void)] = [("Fiche plat", dish), ("Profil", { self.app.buttons["profileButton"].tap() }),
                                               ("Brouillons", { self.app.buttons["draftsButton"].tap() })]
        for (name, open) in screens {
            open()
            sleep(1)
            window.swipeRight(velocity: .fast)
            XCTAssertTrue(app.buttons["cameraButton"].waitForExistence(timeout: 10), "Swipe did not go back from \(name)")
        }
        // An unsaved edit is never swiped away.
        dish()
        XCTAssertTrue(app.navigationBars["Fiche plat"].waitForExistence(timeout: 4))
        app.switches["À la une"].tap()
        window.swipeRight(velocity: .fast)
        sleep(1)
        XCTAssertTrue(app.navigationBars["Fiche plat"].exists, "Swipe dropped an unsaved edit")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["Abandonner"].waitForExistence(timeout: 3))
        app.buttons["Abandonner"].tap()
        XCTAssertTrue(app.buttons["cameraButton"].waitForExistence(timeout: 4))

        // Live camera: permission, preview, shutter, photo preview.
        app.buttons["cameraButton"].tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Autoriser", "OK", "Allow"] where springboard.buttons[label].waitForExistence(timeout: 3) {
            springboard.buttons[label].tap()
            break
        }
        let shutter = app.buttons["shutterButton"]
        XCTAssertTrue(shutter.waitForExistence(timeout: 6), "Camera screen not shown")
        XCTAssertTrue(shutter.isHittable, "Shutter not tappable")
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'accès'")).firstMatch.exists,
                       "Camera access refused or unavailable")
        sleep(2)   // let the live preview and the guidance settle
        shot("device_01_camera_live")
        let hint = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Inclinez' OR label CONTAINS 'Rapprochez' OR label CONTAINS 'Parfait' OR label CONTAINS 'plat'")).firstMatch
        if hint.exists {
            XCTAssertGreaterThanOrEqual(hint.frame.minY, app.navigationBars.firstMatch.frame.maxY,
                                        "Camera hint overlaps the navigation bar")
        }
        shutter.tap()
        XCTAssertTrue(app.buttons["Utiliser"].waitForExistence(timeout: 10), "No photo preview after the shutter")
        shot("device_02_photo_preview")
    }

    // MARK: - Helpers

    private func signIn() {
        let email = app.textFields.firstMatch
        XCTAssertTrue(email.waitForExistence(timeout: 5))
        email.tap(); email.typeText("chef@resto.cm")
        let password = app.secureTextFields.firstMatch
        password.tap(); password.typeText("test")
        app.buttons["Se connecter"].tap()
        let chezFlora = app.buttons["restaurant_Chez Flora"]
        XCTAssertTrue(chezFlora.waitForExistence(timeout: 8))
        let cta = app.buttons["Continuer"]
        // iOS may show "Save password?" and swallow taps: dismiss it and retry.
        for _ in 0..<6 where !app.buttons["cameraButton"].exists {
            if app.buttons["Plus tard"].exists { app.buttons["Plus tard"].tap(); sleep(1) }
            if !cta.isEnabled { chezFlora.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap(); sleep(1) }
            if cta.exists && cta.isEnabled { cta.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap() }
            _ = app.buttons["cameraButton"].waitForExistence(timeout: 3)
        }
        XCTAssertTrue(app.buttons["cameraButton"].exists, "Home not reached")
        if app.buttons["Plus tard"].waitForExistence(timeout: 3) { app.buttons["Plus tard"].tap() }
        sleep(1)
    }

    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
