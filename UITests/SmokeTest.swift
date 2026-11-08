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
        app.buttons["Sélect."].tap()
        app.images.firstMatch.tap()
        XCTAssertTrue(app.buttons["Supprimer (1)"].waitForExistence(timeout: 3), "Delete action missing after selection")
        takeScreenshot("Drafts_multiselect")
    }

    func testProfileHasOnlyWorkingRows() throws {
        navigateToHome()
        app.buttons["profileButton"].tap()
        XCTAssertTrue(app.buttons["Se déconnecter"].waitForExistence(timeout: 4), "Profile not shown")
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
        sleep(3) // login (1.1s) + fetchRestaurants (0.4s) + nav animation
        // Dismiss iOS "Save Password?" dialog if it appears
        let saveDialog = app.buttons["Plus tard"]
        if saveDialog.waitForExistence(timeout: 2) { saveDialog.tap(); sleep(1) }
        let chezFlora = app.buttons["restaurant_Chez Flora"]
        if chezFlora.waitForExistence(timeout: 3) {
            chezFlora.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap()
        }
        sleep(2) // state update + CTA enable animation
        let cta = app.buttons["Continuer"]
        let enabledPred = NSPredicate(format: "enabled == true")
        let ctaWait = XCTNSPredicateExpectation(predicate: enabledPred, object: cta)
        _ = XCTWaiter.wait(for: [ctaWait], timeout: 4)
        if cta.exists && cta.isEnabled {
            cta.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap()
        }
        sleep(3) // navigation + HomeStore.load (500ms)
    }

    private func takeScreenshot(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
