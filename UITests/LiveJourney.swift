import XCTest

/// Full user journey against the real backend, slowed down so a person can watch it on the simulator.
/// Same credentials as LiveTest (skipped without them). Creates one dish "Parcours live" (clean it up after).
final class LiveJourney: XCTestCase {

    var app: XCUIApplication!

    func testJourney() throws {
        let env = ProcessInfo.processInfo.environment
        guard let email = env["ATF_LIVE_EMAIL"], let password = env["ATF_LIVE_PASSWORD"] else {
            throw XCTSkip("ATF_LIVE_EMAIL / ATF_LIVE_PASSWORD not set")
        }
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()

        // 1. Onboarding (fresh install)
        XCTAssertTrue(app.buttons["Passer"].waitForExistence(timeout: 15), "Onboarding not shown on fresh install")
        pause(); app.buttons["Continuer"].tap()
        pause(); app.buttons["Continuer"].tap()
        pause(); app.buttons["Commencer"].tap()

        // 2. Login: wrong password first, then the right one
        XCTAssertTrue(app.buttons["Se connecter"].waitForExistence(timeout: 10))
        let emailField = app.textFields.firstMatch
        emailField.tap(); emailField.typeText(email)
        let secure = app.secureTextFields.firstMatch
        secure.tap(); secure.typeText("mauvais-mot-de-passe")
        app.buttons["Se connecter"].tap()
        sleep(4); shot("login_error")
        secure.tap()
        secure.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 30))
        secure.typeText(password)
        app.buttons["Se connecter"].tap()
        let home = app.buttons["cameraButton"]
        XCTAssertTrue(home.waitForExistence(timeout: 20), "Home not reached")
        dismissPasswordPrompt(); pause()

        // 3. Home filters
        app.buttons["Plats"].tap(); pause()
        app.buttons["Tous"].tap(); pause()

        // 4. Edit a dish: price + sold out, then put it back
        openDish("Poulet DG")
        let price = app.textFields.element(boundBy: 1)
        let oldPrice = (price.value as? String) ?? ""
        replaceText(in: price, with: "6900"); pause()
        app.buttons["Terminé"].tap()
        app.switches["Disponible"].tap(); pause()
        XCTAssertEqual(price.value as? String, "6900", "Price not typed")
        XCTAssertEqual(app.switches["Disponible"].value as? String, "0", "Not marked sold out")
        shot("before_save")
        app.buttons["Enregistrer les modifications"].tap()
        XCTAssertTrue(home.waitForExistence(timeout: 15), "Save failed")
        let edited = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Poulet DG'")).firstMatch
        XCTAssertTrue(edited.label.filter(\.isNumber).contains("6900"), "Home not refreshed: \(edited.label)")
        pause(); shot("home_after_edit")
        openDish("Poulet DG")
        XCTAssertEqual(app.switches["Disponible"].value as? String, "0", "Sold out not reloaded")
        replaceText(in: app.textFields.element(boundBy: 1), with: oldPrice)
        app.buttons["Terminé"].tap()
        app.switches["Disponible"].tap(); pause()
        app.buttons["Enregistrer les modifications"].tap()
        XCTAssertTrue(home.waitForExistence(timeout: 15), "Restore failed")
        pause()

        // 5. Photo from the gallery, kept as a draft
        home.tap(); pause()
        app.buttons["galleryButton"].tap(); sleep(3)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.16, dy: 0.72)).tap()   // first photo (system picker)
        let use = app.buttons["Utiliser cette photo"]
        XCTAssertTrue(use.waitForExistence(timeout: 15), "Preview not shown")
        pause(); use.tap()
        let keep = app.buttons["saveDraftButton"]
        XCTAssertTrue(keep.waitForExistence(timeout: 10)); pause()
        keep.tap()
        // Batch shooting: back to the camera for the next dish.
        XCTAssertTrue(app.buttons["galleryButton"].waitForExistence(timeout: 20), "Draft save failed")
        pause(); app.buttons["Fermer"].tap()
        XCTAssertTrue(home.waitForExistence(timeout: 10)); pause()

        // 6. Drafts: turn the draft into a new dish
        app.buttons["draftsButton"].tap()
        let draft = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Brouillon du'")).firstMatch
        XCTAssertTrue(draft.waitForExistence(timeout: 15)); pause()
        let usedDraft = app.buttons[draft.label]   // older drafts may remain: track this one only
        draft.tap()
        let newDish = app.buttons["Créer un nouveau plat"]
        XCTAssertTrue(newDish.waitForExistence(timeout: 10)); pause()
        newDish.tap()
        XCTAssertTrue(app.staticTexts["Nouveau plat"].waitForExistence(timeout: 5))
        let name = app.textFields.element(boundBy: 0)
        name.tap(); name.typeText("Parcours live")
        let newPrice = app.textFields.element(boundBy: 1)
        newPrice.tap(); newPrice.typeText("4500")
        app.buttons["Terminé"].tap(); pause()
        let save = app.buttons["Enregistrer"]
        for _ in 0..<10 where !save.isEnabled { sleep(1) }
        save.tap()
        XCTAssertTrue(app.staticTexts["Brouillons"].waitForExistence(timeout: 20), "Create failed")
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: usedDraft)
        wait(for: [gone], timeout: 10)
        pause(); app.buttons["Retour"].tap()
        let created = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Parcours live'")).firstMatch
        XCTAssertTrue(created.waitForExistence(timeout: 10), "New dish not on Home")
        created.swipeUp(); pause(); app.swipeDown(); pause()

        // 7. Photo from the gallery, attached to an existing dish (replaces its photo)
        home.tap(); pause()
        app.buttons["galleryButton"].tap(); sleep(3)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.16, dy: 0.72)).tap()
        XCTAssertTrue(app.buttons["Utiliser cette photo"].waitForExistence(timeout: 15), "Preview not shown")
        pause(); app.buttons["Utiliser cette photo"].tap()
        let row = app.staticTexts["Parcours live"]
        XCTAssertTrue(row.waitForExistence(timeout: 15), "Dish list not loaded"); pause()
        row.tap(); pause()
        app.buttons["attachButton"].tap()
        XCTAssertTrue(app.staticTexts["Photo attachée !"].waitForExistence(timeout: 20), "Photo not attached")
        pause(); shot("home_photo_attached")

        // 8. Profile: deletion dialog (cancelled), then sign out
        app.buttons["profileButton"].tap(); pause()
        app.swipeUp(); pause()
        app.staticTexts["Supprimer mon compte"].tap(); pause()
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08)).tap(); pause()   // dismiss, nothing deleted
        app.buttons["Se déconnecter"].tap()
        XCTAssertTrue(app.buttons["Se connecter"].waitForExistence(timeout: 10), "Sign-out failed")
        pause(); shot("signed_out")
    }

    // MARK: - Helpers

    private func pause() { sleep(2) }

    private func openDish(_ prefix: String) {
        let dish = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
        XCTAssertTrue(dish.waitForExistence(timeout: 15), "\(prefix) not loaded")
        dish.tap()
        XCTAssertTrue(app.staticTexts["Fiche plat"].waitForExistence(timeout: 5)); pause()
    }

    private func dismissPasswordPrompt() {
        // The iOS Passwords prompt can come several seconds after login, from the app or from SpringBoard.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        // It can come back after a first tap: continue only after 4 quiet seconds.
        var quiet = 0
        for _ in 0..<20 where quiet < 4 {
            let later = [app.buttons["Plus tard"], springboard.buttons["Plus tard"]].first { $0.exists }
            if let later { later.tap(); quiet = 0 } else { quiet += 1 }
            sleep(1)
        }
    }

    private func replaceText(in field: XCUIElement, with text: String) {
        field.tap()
        if let current = field.value as? String, !current.isEmpty {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        field.typeText(text)
    }

    override func record(_ issue: XCTIssue) {
        if let app {
            shot("failure")
            let tree = XCTAttachment(string: app.debugDescription)
            tree.name = "failure_tree"; tree.lifetime = .keepAlways
            add(tree)
        }
        super.record(issue)
    }

    private func shot(_ name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = name; a.lifetime = .keepAlways
        add(a)
    }
}
