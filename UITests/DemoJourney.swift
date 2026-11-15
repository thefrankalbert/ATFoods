import XCTest

/// Paced end-to-end user journey on the demo data, made to be screen-recorded (launch videos, App Store preview).
/// Same journey every run. Run it alone:
///   xcodebuild test -workspace ATFood.xcworkspace -scheme ATFood -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.3.1' -only-testing:ATFoodUITests/DemoJourney
final class DemoJourney: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    func testDemoJourney() throws {
        // 1. Onboarding: three slides, read at a human pace.
        for label in ["Continuer", "Continuer", "Commencer"] {
            let button = app.buttons[label]
            XCTAssertTrue(button.waitForExistence(timeout: 5))
            pause(3)
            button.tap()
        }

        // 2. Sign in
        let email = app.textFields.firstMatch
        XCTAssertTrue(email.waitForExistence(timeout: 5))
        pause(1.5)
        email.tap()
        type("mariam@chezflora.cm", into: email)
        let password = app.secureTextFields.firstMatch
        password.tap()
        type("motdepasse", into: password)
        pause(1)
        app.buttons["Se connecter"].tap()

        // 3. Choose the restaurant
        let chezFlora = app.buttons["restaurant_Chez Flora"]
        XCTAssertTrue(chezFlora.waitForExistence(timeout: 8))
        let cta = app.buttons["Continuer"]
        for _ in 0..<4 where !cta.isEnabled {
            if app.buttons["Plus tard"].exists { app.buttons["Plus tard"].tap() }   // iOS "Save password?"
            pause(1)
            chezFlora.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap()
            pause(1)
        }
        pause(1.5)
        if app.buttons["Plus tard"].exists { app.buttons["Plus tard"].tap() }   // iOS "Save password?" can cover the button
        cta.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap()

        // 4. Home: browse, search, mark a dish sold out, find it in the sold-out queue.
        for _ in 0..<5 where !app.buttons["cameraButton"].exists {   // late "Save password?" prompt swallowed the tap
            if app.buttons["Plus tard"].exists { app.buttons["Plus tard"].tap(); pause(1) }
            if cta.exists { cta.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap() }
            _ = app.buttons["cameraButton"].waitForExistence(timeout: 3)
        }
        XCTAssertTrue(app.buttons["cameraButton"].exists)
        if app.buttons["Plus tard"].waitForExistence(timeout: 4) { app.buttons["Plus tard"].tap() }
        pause(3)
        app.swipeUp(velocity: .slow)
        pause(1.5)
        app.swipeDown(velocity: .slow)
        pause(1.5)
        let search = app.textFields["searchField"]
        search.tap()
        type("ndole", into: search)
        pause(2.5)
        app.buttons["Annuler"].firstMatch.tap()   // leaves search and clears the query
        XCTAssertTrue(app.buttons["draftsButton"].waitForExistence(timeout: 3), "Search mode did not close")
        pause(1.5)

        let mafe = app.switches["Mafé bœuf disponible"]
        XCTAssertTrue(mafe.waitForExistence(timeout: 4))
        mafe.tap()
        pause(2)
        for category in ["Grillades", "Boisson", "Plat"] {   // the category bar jumps through the menu
            let chip = app.buttons["category_\(category)"]
            let bar = app.scrollViews["categoryBar"]
            for _ in 0..<3 where chip.frame.maxX > bar.frame.maxX { bar.swipeLeft() }   // scroll the bar toward the chip
            for _ in 0..<3 where chip.frame.minX < bar.frame.minX { bar.swipeRight() }
            chip.tap()
            pause(1.5)
        }
        app.buttons["filterMenu"].tap()
        pause(1)
        app.buttons["Épuisés · 1"].tap()
        pause(2.5)
        app.buttons["filterMenu"].tap()
        pause(1)
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Sans photo'")).firstMatch.tap()
        pause(2.5)
        app.buttons["filterMenu"].tap()
        pause(1)
        app.buttons["Tous les plats"].tap()
        pause(1.5)

        // 5. Dish card
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Thieboudienne'")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Fiche plat"].waitForExistence(timeout: 4))
        pause(3)
        app.swipeUp(velocity: .slow)
        pause(2)
        app.swipeDown(velocity: .slow)
        pause(1)
        app.navigationBars.buttons.firstMatch.tap()
        pause(1.5)

        // 6. From a photo to a new dish on the menu: drafts, "who is this photo for", new dish, save.
        app.buttons["draftsButton"].tap()
        XCTAssertTrue(app.staticTexts["Brouillons"].waitForExistence(timeout: 4))
        pause(2.5)
        let draft = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Brouillon du'")).firstMatch
        XCTAssertTrue(draft.waitForExistence(timeout: 4))
        draft.tap()
        XCTAssertTrue(app.buttons["Créer un nouveau plat"].waitForExistence(timeout: 4))
        pause(2.5)
        app.buttons["Créer un nouveau plat"].tap()
        XCTAssertTrue(app.staticTexts["Nouveau plat"].waitForExistence(timeout: 4))
        pause(2.5)

        let name = app.textFields.element(boundBy: 0)   // form order: name, then price
        name.tap()
        type("Salade avocat", into: name)
        let price = app.textFields.element(boundBy: 1)
        price.tap()
        type("2500", into: price)
        pause(1)
        app.buttons["Terminé"].tap()
        pause(1)
        app.buttons["Entrée"].tap()
        pause(2)
        let save = app.buttons["Enregistrer"]
        XCTAssertTrue(save.isEnabled, "Save should be enabled once name, price and category are set")
        save.tap()
        XCTAssertTrue(app.staticTexts["Plat enregistré"].waitForExistence(timeout: 6), "Save confirmation missing")
        pause(3)

        // 7. Back to the menu, then the profile.
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["profileButton"].waitForExistence(timeout: 4))
        pause(2)
        app.buttons["profileButton"].tap()
        XCTAssertTrue(app.buttons["Se déconnecter"].waitForExistence(timeout: 4))
        pause(3)
        app.swipeUp(velocity: .slow)
        pause(3)
    }

    // MARK: - Helpers

    /// Types one character at a time so the video shows natural typing.
    private func type(_ text: String, into element: XCUIElement) {
        for character in text {
            element.typeText(String(character))
            Thread.sleep(forTimeInterval: 0.08)
        }
    }

    private func pause(_ seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }
}
