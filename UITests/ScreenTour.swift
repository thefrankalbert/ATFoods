import XCTest

/// Visual review aid: walks every screen against the real backend and attaches a screenshot of each.
/// Same credentials as LiveTest (skipped without them). Read-only except it opens the save-less screens.
final class ScreenTour: XCTestCase {

    var app: XCUIApplication!

    func testTour() throws {
        let env = ProcessInfo.processInfo.environment
        guard let email = env["ATF_LIVE_EMAIL"], let password = env["ATF_LIVE_PASSWORD"] else {
            throw XCTSkip("ATF_LIVE_EMAIL / ATF_LIVE_PASSWORD not set")
        }
        continueAfterFailure = true
        app = XCUIApplication()
        app.launch()

        // Onboarding
        if app.buttons["Passer"].waitForExistence(timeout: 10) {
            shot("01_onboarding_1")
            app.buttons["Continuer"].tap(); sleep(1); shot("02_onboarding_2")
            app.buttons["Continuer"].tap(); sleep(1); shot("03_onboarding_3")
            app.buttons["Commencer"].tap()
        }
        // Login
        XCTAssertTrue(app.buttons["Se connecter"].waitForExistence(timeout: 10))
        shot("04_login_empty")
        let emailField = app.textFields.firstMatch
        emailField.tap(); emailField.typeText(email)
        let secure = app.secureTextFields.firstMatch
        secure.tap(); secure.typeText("mauvais-mot-de-passe")
        app.buttons["Se connecter"].tap(); sleep(4)
        shot("05_login_error")
        secure.tap()
        secure.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 30))
        secure.typeText(password)
        app.buttons["Se connecter"].tap()
        XCTAssertTrue(app.buttons["cameraButton"].waitForExistence(timeout: 20))
        sleep(2)
        if app.buttons["Plus tard"].waitForExistence(timeout: 2) { app.buttons["Plus tard"].tap() }
        sleep(2); shot("06_home")
        app.buttons["Plats"].tap(); sleep(1); shot("07_home_filter_plats")
        app.buttons["Tous"].tap()

        // Dish card
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Ndolé'")).firstMatch.tap()
        sleep(2); shot("08_dish_card")
        app.textFields.element(boundBy: 1).tap(); sleep(1); shot("09_dish_card_keyboard")
        app.buttons["Terminé"].tap()
        app.navigationBars.buttons.firstMatch.tap(); sleep(1)

        // Camera + gallery
        app.buttons["cameraButton"].tap(); sleep(2); shot("10_camera")
        app.buttons["galleryButton"].tap(); sleep(3); shot("11_gallery_picker")
        // The system photo picker runs out of process: tap the first thumbnail by position.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.16, dy: 0.72)).tap()
        sleep(5); shot("12_photo_preview")
        app.buttons["Utiliser cette photo"].tap()
        sleep(3); shot("13_attach_dish")
        app.buttons["Créer un nouveau plat"].tap(); sleep(2); shot("14_new_dish_form")

        // Back to home whatever the depth
        for _ in 0..<4 where !app.buttons["cameraButton"].isHittable {
            let back = app.buttons.matching(NSPredicate(format: "label == 'Retour' OR label == 'Fermer' OR label == 'Reprendre'")).firstMatch
            if back.exists { back.tap(); sleep(1) } else { break }
        }

        // Drafts (empty state)
        app.buttons["draftsButton"].tap(); sleep(2); shot("15_drafts")
        app.navigationBars.buttons.firstMatch.tap(); sleep(1)

        // Profile
        app.buttons["profileButton"].tap(); sleep(2); shot("16_profile")
        app.swipeUp(); sleep(1); shot("17_profile_bottom")
        app.staticTexts["Supprimer mon compte"].tap(); sleep(1); shot("18_delete_confirm")
        // iOS 26 shows the confirmation as a popover (no Cancel button): tap outside to dismiss.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08)).tap()
    }

    private func shot(_ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = name; a.lifetime = .keepAlways
        add(a)
    }
}
