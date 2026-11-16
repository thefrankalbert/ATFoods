import XCTest

/// Back and dismiss gestures (edge swipe, swipe from anywhere on iOS 26+, slow and fast, swipe down on sheets) never
/// leave a screen that must stay: Home, the first restaurant picker, an unsaved dish, a sheet holding typed text.
/// Pushed screens still go back with a swipe. Mock backend.
final class GestureSafetyTest: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    func testRiskyGesturesKeepTheScreen() throws {
        if app.buttons["Passer"].waitForExistence(timeout: 5) { app.buttons["Passer"].tap() }
        let email = app.textFields.firstMatch
        XCTAssertTrue(email.waitForExistence(timeout: 5))
        email.tap(); email.typeText("chef@resto.cm")
        app.secureTextFields.firstMatch.tap(); app.secureTextFields.firstMatch.typeText("test")
        app.buttons["Se connecter"].tap()

        // First restaurant picker: nothing behind it to go back to.
        let flora = app.buttons["restaurant_Chez Flora"]
        XCTAssertTrue(flora.waitForExistence(timeout: 8))
        if app.buttons["Plus tard"].waitForExistence(timeout: 2) { app.buttons["Plus tard"].tap() }
        swipeBack(.slow); swipeBack(.fast)
        XCTAssertTrue(flora.waitForExistence(timeout: 3), "A swipe left the first restaurant picker")
        XCTAssertFalse(app.buttons["Se connecter"].exists, "A swipe uncovered the login screen")
        XCTAssertFalse(app.buttons["restaurant_Le Maquis du Port"].isSelected, "A swipe picked a restaurant")

        let cta = app.buttons["Continuer"]
        for _ in 0..<6 where !app.buttons["cameraButton"].exists {
            if app.buttons["Plus tard"].exists { app.buttons["Plus tard"].tap(); sleep(1) }
            if !cta.isEnabled { flora.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap(); sleep(1) }
            if cta.exists && cta.isEnabled { cta.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap() }
            _ = app.buttons["cameraButton"].waitForExistence(timeout: 3)
        }
        XCTAssertTrue(app.buttons["cameraButton"].exists, "Home not reached")
        if app.buttons["Plus tard"].waitForExistence(timeout: 3) { app.buttons["Plus tard"].tap() }
        sleep(1)
        XCTAssertTrue(app.buttons["restaurantSwitch"].label.hasPrefix("Chez Flora"), "Home opened another restaurant")
        XCTAssertTrue(app.buttons["profileButton"].isHittable && app.buttons["draftsButton"].isHittable,
                      "Toolbar buttons hidden in an overflow menu")

        // Home: swipes on the list and on the category bar keep Home.
        swipeBack(.slow); swipeBack(.fast)
        let bar = app.scrollViews["categoryBar"]
        bar.swipeLeft(); bar.swipeRight(); bar.swipeRight()
        dragRight(on: bar, velocity: .slow)
        XCTAssertTrue(app.buttons["cameraButton"].waitForExistence(timeout: 3), "A swipe left Home")
        XCTAssertFalse(app.buttons["Se connecter"].exists, "A swipe uncovered the login screen")

        // Unsaved edit on a dish: neither a slow nor a fast swipe drops it.
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Thieboudienne'")).firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Fiche plat"].waitForExistence(timeout: 4))
        turnOnFeatured()
        sleep(1)
        swipeBack(.slow); swipeBack(.fast)
        XCTAssertTrue(app.navigationBars["Fiche plat"].exists, "A swipe left a dish with an unsaved edit")
        XCTAssertEqual(app.switches["À la une"].value as? String, "1", "A swipe dropped the unsaved edit")

        // New category sheet with a typed name: a swipe down does not close it.
        app.buttons["newCategoryButton"].tap()
        XCTAssertTrue(app.staticTexts["Nouvelle catégorie"].waitForExistence(timeout: 3))
        app.textFields.firstMatch.tap()
        app.textFields.firstMatch.typeText("Desserts")
        app.staticTexts["Nouvelle catégorie"].swipeDown(velocity: .fast)
        sleep(1)
        XCTAssertTrue(app.staticTexts["Nouvelle catégorie"].exists, "A swipe down lost the typed category name")
        app.buttons["Annuler"].tap()

        // Leave the dish the normal way, then a pushed screen still goes back with a swipe.
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["Abandonner"].waitForExistence(timeout: 3))
        app.buttons["Abandonner"].tap()
        XCTAssertTrue(app.buttons["cameraButton"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["profileButton"].waitForExistence(timeout: 6))
        app.buttons["profileButton"].tap()
        XCTAssertTrue(app.buttons["Se déconnecter"].waitForExistence(timeout: 4))
        swipeBack(.fast)
        XCTAssertTrue(app.buttons["cameraButton"].waitForExistence(timeout: 4), "Swipe no longer goes back from a pushed screen")
    }

    // MARK: - Helpers

    /// Flip "À la une" on and check it took: the row's switch is the inner control (the element spans the row on iPad).
    private func turnOnFeatured() {
        let row = app.switches["À la une"]
        XCTAssertTrue(row.waitForExistence(timeout: 4))
        let control = row.switches.firstMatch.exists ? row.switches.firstMatch : row
        control.tap()
        if row.value as? String != "1" { row.coordinate(withNormalizedOffset: .init(dx: 0.93, dy: 0.5)).tap() }
        XCTAssertEqual(row.value as? String, "1", "Could not turn on À la une")
        print("PROBE featured frame=\(row.frame) value=\(String(describing: row.value))")
    }

    private func swipeBack(_ velocity: XCUIGestureVelocity) {
        app.windows.firstMatch.swipeRight(velocity: velocity)
        sleep(1)
    }

    private func dragRight(on element: XCUIElement, velocity: XCUIGestureVelocity) {
        let origin = app.windows.firstMatch.coordinate(withNormalizedOffset: .zero)
        let frame = element.frame
        origin.withOffset(CGVector(dx: frame.minX + 40, dy: frame.midY))
            .press(forDuration: 0.1, thenDragTo: origin.withOffset(CGVector(dx: frame.minX + 260, dy: frame.midY)),
                   withVelocity: velocity, thenHoldForDuration: 0.1)
        sleep(1)
    }
}
