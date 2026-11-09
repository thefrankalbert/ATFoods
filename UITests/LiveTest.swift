import XCTest

/// End-to-end against the real Supabase backend (no mock). Skipped unless credentials are given:
///   TEST_RUNNER_ATF_LIVE_EMAIL=… TEST_RUNNER_ATF_LIVE_PASSWORD=… xcodebuild test … -only-testing:ATFoodUITests/LiveTest
/// Expects the App Review demo restaurant (docs/app-store/demo-account.sql). testLive02 also needs one pending draft.
final class LiveTest: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        let env = ProcessInfo.processInfo.environment
        guard let email = env["ATF_LIVE_EMAIL"], let password = env["ATF_LIVE_PASSWORD"] else {
            throw XCTSkip("ATF_LIVE_EMAIL / ATF_LIVE_PASSWORD not set")
        }
        app = XCUIApplication()
        app.launch()
        signInIfNeeded(email: email, password: password)
    }

    func testLive01_editPriceAndAvailability() throws {
        let dish = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Poulet DG'")).firstMatch
        XCTAssertTrue(dish.waitForExistence(timeout: 15), "Demo dish not loaded from Supabase")
        dish.tap()
        XCTAssertTrue(app.staticTexts["Fiche plat"].waitForExistence(timeout: 5))
        let price = app.textFields.element(boundBy: 1)
        replaceText(in: price, with: "6600")
        app.buttons["Terminé"].tap()
        app.switches.firstMatch.tap()   // available -> sold out
        app.buttons["Enregistrer les modifications"].tap()
        XCTAssertTrue(app.buttons["cameraButton"].waitForExistence(timeout: 15), "Save failed: \(errorText())")
        shot("live01_after_save")
    }

    func testLive02_newDishFromDraft() throws {
        app.buttons["draftsButton"].tap()
        let draft = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Brouillon du'")).firstMatch
        XCTAssertTrue(draft.waitForExistence(timeout: 15), "Seeded draft not listed")
        shot("live02_drafts")
        draft.tap()
        let newDish = app.buttons["+ Nouveau plat"]
        XCTAssertTrue(newDish.waitForExistence(timeout: 10))
        newDish.tap()
        XCTAssertTrue(app.staticTexts["Nouveau plat"].waitForExistence(timeout: 5))
        let name = app.textFields.element(boundBy: 0)
        name.tap(); name.typeText("Plat test Atfood")
        let price = app.textFields.element(boundBy: 1)
        price.tap(); price.typeText("3500")
        app.buttons["Terminé"].tap()
        let save = app.buttons["Enregistrer"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        for _ in 0..<10 where !save.isEnabled { sleep(1) }   // categories load
        save.tap()
        // After a draft, the app goes back to the drafts list to illustrate the next one.
        XCTAssertTrue(app.staticTexts["Brouillons"].waitForExistence(timeout: 20), "Create failed: \(errorText())")
        XCTAssertTrue(app.staticTexts["Aucun brouillon"].waitForExistence(timeout: 10), "Used draft still listed")
        app.buttons["Retour"].tap()
        XCTAssertTrue(app.buttons["cameraButton"].waitForExistence(timeout: 10))
        let created = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Plat test Atfood'")).firstMatch
        XCTAssertTrue(created.waitForExistence(timeout: 10), "New dish not on Home")
        shot("live02_home_with_new_dish")
    }

    /// Run alone, with a THROWAWAY non-owner account as ATF_LIVE_EMAIL: it really deletes that account.
    func testLive03_deleteThrowawayAccount() throws {
        guard ProcessInfo.processInfo.environment["ATF_LIVE_ALLOW_DELETE"] == "1" else {
            throw XCTSkip("Set ATF_LIVE_ALLOW_DELETE=1 with a throwaway account")
        }
        app.buttons["profileButton"].tap()
        let row = app.staticTexts["Supprimer mon compte"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        let confirm = app.sheets.buttons["Supprimer mon compte"].exists
            ? app.sheets.buttons["Supprimer mon compte"] : app.buttons["Supprimer mon compte"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
        XCTAssertTrue(app.buttons["Se connecter"].waitForExistence(timeout: 20), "Deletion did not sign out")
    }

    // MARK: - Helpers

    override func record(_ issue: XCTIssue) {
        if let app {
            shot("failure")
            let tree = XCTAttachment(string: app.debugDescription)
            tree.name = "failure_tree"; tree.lifetime = .keepAlways
            add(tree)
        }
        super.record(issue)
    }

    private func signInIfNeeded(email: String, password: String) {
        // Session restore hits the network: wait for whichever screen comes first.
        for _ in 0..<15 where !app.buttons["cameraButton"].exists && !app.buttons["Passer"].exists
            && !app.buttons["Se connecter"].exists { sleep(1) }
        if app.buttons["cameraButton"].exists { dismissPasswordPrompt(); return }   // session restored
        for label in ["Continuer", "Continuer", "Commencer"] where app.buttons[label].waitForExistence(timeout: 3) {
            if app.buttons["Se connecter"].exists { break }
            app.buttons[label].tap()
        }
        XCTAssertTrue(app.buttons["Se connecter"].waitForExistence(timeout: 5), "Login not reached")
        let emailField = app.textFields.firstMatch
        emailField.tap(); emailField.typeText(email)
        let secure = app.secureTextFields.firstMatch
        secure.tap(); secure.typeText(password)
        app.buttons["Se connecter"].tap()
        // One restaurant: the app opens it directly. Several: pick the demo one.
        let restaurant = app.buttons["restaurant_Restaurant Démo Atfood"]
        let home = app.buttons["cameraButton"]
        for _ in 0..<20 where !home.exists && !restaurant.exists { sleep(1) }
        if restaurant.exists {
            let cta = app.buttons["Continuer"]
            for _ in 0..<4 where !cta.isEnabled {
                dismissPasswordPrompt()
                restaurant.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap()
                sleep(1)
            }
            cta.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap()
        }
        XCTAssertTrue(home.waitForExistence(timeout: 15), "Home not reached")
        sleep(2)
        dismissPasswordPrompt()
    }

    /// iOS "Enregistrer le mot de passe ?" sheet swallows taps and typing until dismissed.
    private func dismissPasswordPrompt() {
        let later = app.buttons["Plus tard"]
        if later.waitForExistence(timeout: 2) { later.tap(); sleep(1) }
    }

    private func replaceText(in field: XCUIElement, with text: String) {
        field.tap()
        if let current = field.value as? String, !current.isEmpty {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        field.typeText(text)
    }

    private func errorText() -> String {
        app.staticTexts.allElementsBoundByIndex.map { $0.label }.filter { $0.contains("!") || $0.lowercased().contains("erreur") || $0.contains("impossible") }.joined(separator: " | ")
    }

    private func shot(_ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = name; a.lifetime = .keepAlways
        add(a)
    }
}
