import XCTest

/// Walks every redesigned screen on the mock backend, checks what each must show, and keeps a screenshot of each.
final class ScreensTest: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    func testRedesignedScreens() throws {
        signInToChezFlora()
        shot("01_home")

        // Home: availability switch works from the list, filters count it.
        let toggle = app.switches["Mafé bœuf disponible"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), "Availability switch missing on Home")
        toggle.tap()
        XCTAssertTrue(app.buttons["Épuisés · 1"].waitForExistence(timeout: 3), "Sold-out filter did not count the dish")
        app.buttons["Épuisés · 1"].tap()
        XCTAssertTrue(app.staticTexts["Mafé bœuf"].waitForExistence(timeout: 3))
        shot("02_home_sold_out")
        app.buttons["Tous"].tap()

        // Dish card
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Thieboudienne'")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Fiche plat"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.switches["Disponible"].exists && app.switches["À la une"].exists)
        shot("03_dish_card")
        app.swipeUp()
        shot("04_dish_card_details")
        app.buttons["Retour"].tap()

        // Drafts, then a draft's "who is this photo for" screen
        app.buttons["draftsButton"].tap()
        XCTAssertTrue(app.staticTexts["Brouillons"].waitForExistence(timeout: 4))
        shot("05_drafts")
        let draft = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Brouillon du'")).firstMatch
        XCTAssertTrue(draft.waitForExistence(timeout: 4), "Mock drafts not listed")
        draft.tap()
        XCTAssertTrue(app.buttons["Créer un nouveau plat"].waitForExistence(timeout: 4), "Attach screen not shown")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Koki'")).firstMatch.tap()
        XCTAssertTrue(app.buttons["attachButton"].isEnabled, "Attach stays disabled after picking a dish")
        shot("06_attach")

        // New dish form from the draft: the disabled save button says what is missing.
        app.buttons["Créer un nouveau plat"].tap()
        XCTAssertTrue(app.staticTexts["Nouveau plat"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["Ajoutez un nom et un prix pour enregistrer."].waitForExistence(timeout: 4),
                      "Missing-fields hint not shown")
        shot("07_new_dish")
        app.buttons["Retour"].tap()
        app.buttons["Retour"].tap()
        app.buttons["Retour"].tap()

        // Profile
        XCTAssertTrue(app.buttons["profileButton"].waitForExistence(timeout: 4))
        app.buttons["profileButton"].tap()
        XCTAssertTrue(app.buttons["Se déconnecter"].waitForExistence(timeout: 4))
        shot("08_profile")
    }

    // MARK: - Helpers

    private func signInToChezFlora() {
        for label in ["Continuer", "Continuer", "Commencer"] {
            let button = app.buttons[label]
            if button.waitForExistence(timeout: 4) { button.tap() }
        }
        let email = app.textFields.firstMatch
        XCTAssertTrue(email.waitForExistence(timeout: 5))
        email.tap(); email.typeText("chef@resto.cm")
        let password = app.secureTextFields.firstMatch
        password.tap(); password.typeText("test")
        app.buttons["Se connecter"].tap()
        let chezFlora = app.buttons["restaurant_Chez Flora"]
        XCTAssertTrue(chezFlora.waitForExistence(timeout: 8))
        let cta = app.buttons["Continuer"]
        // iOS may show "Save password?" over the picker and swallow taps: retry until the CTA enables.
        for _ in 0..<4 where !cta.isEnabled {
            if app.buttons["Plus tard"].exists { app.buttons["Plus tard"].tap() }
            sleep(1)
            chezFlora.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap()
            sleep(1)
        }
        cta.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["cameraButton"].waitForExistence(timeout: 6), "Home not reached")
        sleep(1)
    }

    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
