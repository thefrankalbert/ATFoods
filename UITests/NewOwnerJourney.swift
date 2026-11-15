import XCTest

/// A brand-new restaurant owner (empty menu) going through everything, against the real backend.
/// Slowed down to be watched. Needs a fresh owner account with an empty restaurant:
///   TEST_RUNNER_ATF_QA_EMAIL / TEST_RUNNER_ATF_QA_PASSWORD. Delete that account afterwards.
final class NewOwnerJourney: XCTestCase {

    var app: XCUIApplication!

    func testNewOwner() throws {
        let env = ProcessInfo.processInfo.environment
        guard let email = env["ATF_QA_EMAIL"], let password = env["ATF_QA_PASSWORD"] else {
            throw XCTSkip("ATF_QA_EMAIL / ATF_QA_PASSWORD not set")
        }
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()

        // 1. Onboarding + login
        XCTAssertTrue(app.buttons["Passer"].waitForExistence(timeout: 15), "Onboarding not shown on fresh install")
        pause(); app.buttons["Continuer"].tap()
        pause(); app.buttons["Continuer"].tap()
        pause(); app.buttons["Commencer"].tap()
        XCTAssertTrue(app.buttons["Se connecter"].waitForExistence(timeout: 10))
        let emailField = app.textFields.firstMatch
        emailField.tap(); emailField.typeText(email)
        let secure = app.secureTextFields.firstMatch
        secure.tap(); secure.typeText(password)
        app.buttons["Se connecter"].tap()
        let home = app.buttons["cameraButton"]
        XCTAssertTrue(home.waitForExistence(timeout: 20), "Home not reached")
        dismissPasswordPrompt()

        // 2. Empty restaurant: Home says so
        XCTAssertTrue(app.staticTexts["Aucun plat pour l'instant"].waitForExistence(timeout: 15), "Empty state missing")
        pause(); shot("empty_home")

        // 3. First dish: gallery photo -> new dish -> first category
        pickGalleryPhoto()
        XCTAssertTrue(app.staticTexts["Aucun plat pour l'instant : créez-en un."].waitForExistence(timeout: 15))
        pause(); app.buttons["Créer un nouveau plat"].tap()
        XCTAssertTrue(app.staticTexts["Nouveau plat"].waitForExistence(timeout: 5))
        fillDish(name: "Attiéké poisson", price: "3000")
        app.buttons["newCategoryButton"].tap()
        let catName = app.textFields.firstMatch
        XCTAssertTrue(catName.waitForExistence(timeout: 5)); pause()
        catName.tap(); catName.typeText("Plats")
        pause(); app.buttons["Créer"].tap()
        XCTAssertTrue(app.buttons["Plats"].waitForExistence(timeout: 15), "Category not created"); pause()
        save(app.buttons["Enregistrer"])
        let first = dishCard("Attiéké poisson")
        XCTAssertTrue(first.waitForExistence(timeout: 20), "First dish not on Home")
        pause(); shot("first_dish")

        // 4. Second photo kept as a draft, then a second dish from the drafts
        pickGalleryPhoto(index: 1)
        let keep = app.buttons["saveDraftButton"]
        XCTAssertTrue(keep.waitForExistence(timeout: 15)); pause()
        keep.tap()
        XCTAssertTrue(app.buttons["galleryButton"].waitForExistence(timeout: 20), "Draft save failed")
        pause(); app.navigationBars.buttons.firstMatch.tap()
        app.buttons["draftsButton"].tap()
        let draft = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Brouillon du'")).firstMatch
        XCTAssertTrue(draft.waitForExistence(timeout: 15)); pause()
        draft.tap()
        XCTAssertTrue(app.buttons["Créer un nouveau plat"].waitForExistence(timeout: 10)); pause()
        app.buttons["Créer un nouveau plat"].tap()
        fillDish(name: "Alloco", price: "1500")
        XCTAssertTrue(app.buttons["Plats"].waitForExistence(timeout: 10))
        app.buttons["Plats"].tap(); pause()
        save(app.buttons["Enregistrer"])
        XCTAssertTrue(app.staticTexts["Aucun brouillon"].waitForExistence(timeout: 20), "Draft dish failed")
        pause(); app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(dishCard("Alloco").waitForExistence(timeout: 15), "Second dish not on Home")
        pause()

        // 5. Edit the first dish: the whole web sheet (price, sold out, description, featured,
        //    allergens, calories, English translation), then an extra photo.
        dishCard("Attiéké poisson").tap()
        XCTAssertTrue(app.staticTexts["Fiche plat"].waitForExistence(timeout: 5)); pause()
        let price = app.textFields.element(boundBy: 1)
        price.tap()
        price.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 10))
        price.typeText("3500")
        app.buttons["Terminé"].tap()
        app.switches["Disponible"].tap(); pause()
        let description = textInput("Description")
        description.tap(); description.typeText("Attiéké, poisson braisé, oignons et piment")
        app.buttons["Terminé"].tap(); pause()
        app.switches["À la une"].tap()
        app.buttons["Poisson"].tap(); app.buttons["Arachides"].tap(); pause()
        let calories = app.textFields["Calories"]
        calories.tap(); calories.typeText("650")
        app.buttons["Terminé"].tap()
        app.buttons["Traduction anglaise"].tap(); pause()
        let nameEn = app.textFields["Nom (traduction)"]
        nameEn.tap(); nameEn.typeText("Attieke with grilled fish")
        app.buttons["Terminé"].tap(); pause()
        shot("full_sheet")
        app.buttons["Enregistrer les modifications"].tap()
        XCTAssertTrue(home.waitForExistence(timeout: 15), "Edit failed")
        // Prices use a narrow no-break space ("3 500"): compare digits only.
        let label = dishCard("Attiéké poisson").label
        XCTAssertTrue(label.filter(\.isNumber).contains("3500"), "New price not shown: \(label)")
        pause(); shot("after_edit")

        // Reopen: everything saved must come back, then add an extra photo.
        dishCard("Attiéké poisson").tap()
        XCTAssertTrue(app.staticTexts["Fiche plat"].waitForExistence(timeout: 5)); pause()
        XCTAssertEqual(app.switches["À la une"].value as? String, "1", "Featured not saved")
        XCTAssertTrue(app.buttons["Poisson"].isSelected, "Allergen not saved")
        XCTAssertEqual(app.textFields["Calories"].value as? String, "650", "Calories not saved")
        app.buttons["addGalleryPhotoButton"].tap(); sleep(3)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.49, dy: 0.72)).tap()
        XCTAssertTrue(app.buttons["Retirer cette photo"].waitForExistence(timeout: 20), "Extra photo not added")
        pause(); shot("extra_photo")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(home.waitForExistence(timeout: 10), "Back asked to discard though everything was saved")
        pause()

        // 6. Profile: a sole owner cannot delete the account; then sign out
        app.buttons["profileButton"].tap(); pause()
        app.swipeUp(); pause()
        app.staticTexts["Supprimer mon compte"].tap()
        let confirm = app.sheets.buttons["Supprimer mon compte"].exists
            ? app.sheets.buttons["Supprimer mon compte"] : app.buttons["Supprimer mon compte"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5)); pause()
        confirm.tap()
        XCTAssertTrue(app.staticTexts["Compte non supprimé"].waitForExistence(timeout: 20), "Owner guard not shown")
        let ownerMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'propriétaire'")).firstMatch
        XCTAssertTrue(ownerMessage.exists, "Owner told the account is managed by the À Table team")
        pause(); shot("sole_owner"); pause()
        app.buttons["OK"].tap(); pause()
        app.buttons["Se déconnecter"].tap()
        XCTAssertTrue(app.buttons["Se connecter"].waitForExistence(timeout: 10), "Sign-out failed")
        pause()
    }

    /// Run after testNewOwner once the QA restaurant was edited on the web side (same database):
    /// Alloco 2000 F, featured, gluten, new description; new category "Boissons" (order 1) with "Bissap".
    func testWebEditsShowInApp() throws {
        let env = ProcessInfo.processInfo.environment
        guard let email = env["ATF_QA_EMAIL"], let password = env["ATF_QA_PASSWORD"], env["ATF_QA_WEB_EDITED"] != nil else {
            throw XCTSkip("ATF_QA_EMAIL / ATF_QA_PASSWORD / ATF_QA_WEB_EDITED not set")
        }
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        if app.buttons["Passer"].waitForExistence(timeout: 10) { app.buttons["Passer"].tap() }
        XCTAssertTrue(app.buttons["Se connecter"].waitForExistence(timeout: 10))
        let emailField = app.textFields.firstMatch
        emailField.tap(); emailField.typeText(email)
        let secure = app.secureTextFields.firstMatch
        secure.tap(); secure.typeText(password)
        app.buttons["Se connecter"].tap()
        XCTAssertTrue(app.buttons["cameraButton"].waitForExistence(timeout: 20), "Home not reached")
        dismissPasswordPrompt()

        // New web category and dish are there, in the web order (Plats before Boissons).
        XCTAssertTrue(app.buttons["Boissons"].waitForExistence(timeout: 15), "Web category missing")
        let bissap = dishCard("Bissap"), alloco = dishCard("Alloco")
        XCTAssertTrue(bissap.waitForExistence(timeout: 15), "Web dish missing")
        XCTAssertTrue(alloco.label.filter(\.isNumber).contains("2000"), "Web price not shown: \(alloco.label)")
        XCTAssertLessThan(alloco.frame.minY, bissap.frame.minY, "Order differs from the web")
        pause(); shot("web_edits_home")
        app.buttons["category_Boissons"].tap(); pause(); shot("web_category_jump")

        // The web edits on the dish sheet.
        alloco.tap()
        XCTAssertTrue(app.staticTexts["Fiche plat"].waitForExistence(timeout: 5)); pause()
        XCTAssertEqual(app.switches["À la une"].value as? String, "1", "Web featured not shown")
        XCTAssertTrue(app.buttons["Gluten"].isSelected, "Web allergen not shown")
        let description = (textInput("Description").value as? String) ?? ""
        XCTAssertTrue(description.contains("modifié depuis le web"), "Web description not shown: \(description)")
        pause(); shot("web_edits_sheet")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["cameraButton"].waitForExistence(timeout: 10))
        pause()
    }

    // MARK: - Helpers

    private func pause() { sleep(2) }

    /// Multi-line fields show up as text views, single-line ones as text fields.
    private func textInput(_ label: String) -> XCUIElement {
        app.textViews[label].exists ? app.textViews[label] : app.textFields[label]
    }

    private func dishCard(_ name: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
    }

    private func pickGalleryPhoto(index: Int = 0) {
        // Another app sharing the simulator can steal the foreground: bring Atfood back and retry.
        let gallery = app.buttons["galleryButton"]
        for _ in 0..<3 where !gallery.exists {
            app.activate()
            app.buttons["cameraButton"].tap()
            _ = gallery.waitForExistence(timeout: 5)
        }
        pause()
        gallery.tap(); sleep(3)
        // System photo picker runs out of process: tap a thumbnail by position.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.16 + 0.33 * Double(index), dy: 0.72)).tap()
        let use = app.buttons["Utiliser"]
        XCTAssertTrue(use.waitForExistence(timeout: 15), "Preview not shown")
        pause(); use.tap()
    }

    private func fillDish(name: String, price: String) {
        let nameField = app.textFields.element(boundBy: 0)
        nameField.tap(); nameField.typeText(name)
        let priceField = app.textFields.element(boundBy: 1)
        priceField.tap(); priceField.typeText(price)
        app.buttons["Terminé"].tap(); pause()
    }

    private func save(_ button: XCUIElement) {
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        for _ in 0..<10 where !button.isEnabled { sleep(1) }
        button.tap()
    }

    private func dismissPasswordPrompt() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        var quiet = 0
        for _ in 0..<20 where quiet < 4 {
            let later = [app.buttons["Plus tard"], springboard.buttons["Plus tard"]].first { $0.exists }
            if let later { later.tap(); quiet = 0 } else { quiet += 1 }
            sleep(1)
        }
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
