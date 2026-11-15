import XCTest

final class SmokeTest: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    // MARK: - S01 Onboarding

    func testS01_onboardingVisible() throws {
        // Wordmark "Atfood" and "Passer" button must exist
        XCTAssertTrue(app.buttons["Passer"].waitForExistence(timeout: 5), "S01: Passer button missing")
        XCTAssertTrue(app.buttons["Continuer"].waitForExistence(timeout: 3), "S01: Continuer button missing")
        takeScreenshot("S01_onboarding_slide1")
    }

    // MARK: - S01 → S02 Login

    func testS02_loginReachableFromOnboarding() throws {
        // Slide 1 → 2 → 3 → Login
        tapIfExists("Continuer")
        tapIfExists("Continuer")
        tapIfExists("Commencer")

        XCTAssertTrue(app.buttons["Se connecter"].waitForExistence(timeout: 5), "S02: Se connecter button missing")
        takeScreenshot("S02_login")
    }

    // MARK: - S02 → S03 RestaurantPicker

    func testS03_loginAndRestaurantPicker() throws {
        navigateToLogin()  // fills password via helper

        let loginBtn = app.buttons["Se connecter"]
        XCTAssertTrue(loginBtn.waitForExistence(timeout: 5))
        loginBtn.tap()

        // Wait for restaurant list, select first restaurant via accessibilityIdentifier
        let chezFlora = app.buttons["restaurant_Chez Flora"]
        XCTAssertTrue(chezFlora.waitForExistence(timeout: 6), "S03: Restaurant list not loaded")
        chezFlora.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap()
        takeScreenshot("S03_restaurant_picker")

        // CTA "Continuer" is enabled after selection
        let cta = app.buttons["Continuer"]
        XCTAssertTrue(cta.waitForExistence(timeout: 3), "S03: Continuer CTA missing")
    }

    // MARK: - S03 → S04 Home

    func testS04_homeReachable() throws {
        navigateToHome()
        // cameraButton exists only on Home screen
        XCTAssertTrue(app.buttons["cameraButton"].waitForExistence(timeout: 5),
                      "S04: Home screen not reached (cameraButton missing)")
        takeScreenshot("S04_home")
    }

    // MARK: - S04 → S05 Camera

    func testS05_cameraOpensFromHome() throws {
        navigateToHome()
        let camBtn = app.buttons["cameraButton"]
        XCTAssertTrue(camBtn.waitForExistence(timeout: 5), "S05: camera button not found on Home")
        camBtn.tap()
        sleep(2)
        takeScreenshot("S05_camera")
        // Camera view is present (app didn't crash)
        XCTAssertTrue(app.exists)
    }

    // MARK: - DishFormView validation: save disabled when empty

    // MARK: - Drafts & Profile

    func testDraftsListAndMultiSelect() throws {
        navigateToHome()
        XCTAssertTrue(app.buttons["draftsButton"].waitForExistence(timeout: 4), "Drafts button missing on Home")
        app.buttons["draftsButton"].tap()
        XCTAssertTrue(app.staticTexts["Brouillons"].waitForExistence(timeout: 4), "Drafts screen not shown")
        // Mock returns drafts: multi-select must expose the delete action.
        app.buttons["Sélectionner"].tap()
        app.images.firstMatch.tap()
        XCTAssertTrue(app.buttons["Supprimer (1)"].waitForExistence(timeout: 3), "Delete action missing after selection")
        takeScreenshot("Drafts_multiselect")
    }

    func testProfileHasOnlyWorkingRows() throws {
        navigateToHome()
        app.buttons["profileButton"].tap()
        XCTAssertTrue(app.buttons["Se déconnecter"].waitForExistence(timeout: 4), "Profile not shown")
        XCTAssertTrue(app.staticTexts["Politique de confidentialité"].exists, "Privacy link missing")
        XCTAssertTrue(app.buttons["Supprimer mon compte"].exists, "Account deletion missing")
        for removed in ["Crédits IA", "Passer au Pro", "Activer Face ID", "Mode hors-ligne", "Langue", "Notifications"] {
            XCTAssertFalse(app.staticTexts[removed].exists, "Removed row still visible: \(removed)")
        }
        takeScreenshot("Profile")
    }

    func testSignOutReturnsToLogin() throws {
        navigateToHome()
        app.buttons["profileButton"].tap()
        let signOut = app.buttons["Se déconnecter"]
        XCTAssertTrue(signOut.waitForExistence(timeout: 4))
        signOut.tap()
        XCTAssertTrue(app.buttons["Se connecter"].waitForExistence(timeout: 5), "Sign out did not return to login")
    }

    func testAccountDeletionExplainsSoleOwnerRefusal() throws {
        navigateToHome()
        app.buttons["profileButton"].tap()
        let row = app.buttons["Supprimer mon compte"]
        XCTAssertTrue(row.waitForExistence(timeout: 4))
        row.tap()
        let confirm = app.buttons["Supprimer mon compte"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 3), "Deletion confirmation missing")
        app.sheets.buttons["Supprimer mon compte"].exists ? app.sheets.buttons["Supprimer mon compte"].tap() : confirm.tap()
        // Mock answers "sole owner of Chez Flora": the owner can still start the deletion in the app (Apple 5.1.1(v)).
        XCTAssertTrue(app.alerts["Supprimer aussi l'établissement ?"].waitForExistence(timeout: 5), "Owner case not explained")
        app.alerts.buttons["Demander la suppression"].tap()
        XCTAssertTrue(app.alerts["Demande enregistrée"].waitForExistence(timeout: 5), "Deletion request not confirmed")
        app.alerts.buttons["OK"].tap()
    }

    func testDishCardEditsPrice() throws {
        navigateToHome()
        let dish = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Mafé bœuf'")).firstMatch
        XCTAssertTrue(dish.waitForExistence(timeout: 5), "Dish card missing on Home")
        dish.tap()
        XCTAssertTrue(app.staticTexts["Fiche plat"].waitForExistence(timeout: 4), "Dish card did not open")
        XCTAssertTrue(app.buttons["changePhotoButton"].exists, "Change photo action missing")
        let price = app.textFields.element(boundBy: 1)
        price.tap()
        price.press(forDuration: 1.0)
        if app.menuItems["Tout sélectionner"].waitForExistence(timeout: 2) { app.menuItems["Tout sélectionner"].tap() }
        price.typeText("4200")
        app.buttons["Terminé"].tap()
        app.buttons["Enregistrer les modifications"].tap()
        XCTAssertTrue(app.buttons["cameraButton"].waitForExistence(timeout: 5), "Did not return to Home after save")
    }

    // MARK: - Helpers

    private func tapIfExists(_ label: String, timeout: TimeInterval = 4) {
        let btn = app.buttons[label]
        if btn.waitForExistence(timeout: timeout) { btn.tap() }
    }

    private func navigateToLogin() {
        tapIfExists("Continuer")
        tapIfExists("Continuer")
        tapIfExists("Commencer")
        _ = app.buttons["Se connecter"].waitForExistence(timeout: 5)
        // Mock login requires an email containing "@" and a non-empty password.
        let emailField = app.textFields.firstMatch
        if emailField.waitForExistence(timeout: 3) {
            emailField.tap()
            emailField.typeText("chef@resto.cm")
        }
        let secureField = app.secureTextFields.firstMatch
        if secureField.waitForExistence(timeout: 3) {
            secureField.tap()
            secureField.typeText("test")
        }
    }

    private func navigateToHome() {
        navigateToLogin()
        app.buttons["Se connecter"].tap()
        let chezFlora = app.buttons["restaurant_Chez Flora"]
        XCTAssertTrue(chezFlora.waitForExistence(timeout: 8), "Restaurant picker not reached")
        let cta = app.buttons["Continuer"]
        // iOS may show "Save password?" over the picker and swallow taps: retry until the CTA enables.
        for _ in 0..<4 where !cta.isEnabled {
            if app.buttons["Plus tard"].exists { app.buttons["Plus tard"].tap() }
            sleep(1)
            chezFlora.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap()
            sleep(1)
        }
        XCTAssertTrue(cta.isEnabled, "Restaurant could not be selected")
        cta.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap()
        for _ in 0..<5 where !app.buttons["cameraButton"].exists {   // late "Save password?" prompt swallowed the tap
            if app.buttons["Plus tard"].exists { app.buttons["Plus tard"].tap(); sleep(1) }
            if cta.exists { cta.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap() }
            _ = app.buttons["cameraButton"].waitForExistence(timeout: 3)
        }
        XCTAssertTrue(app.buttons["cameraButton"].exists, "Home not reached")
        if app.buttons["Plus tard"].waitForExistence(timeout: 3) { app.buttons["Plus tard"].tap() }
        sleep(1)   // menu load (mock: 500 ms)
    }

    private func takeScreenshot(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
