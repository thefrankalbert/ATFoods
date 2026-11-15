import XCTest

/// QA tour on the mock backend: walks every screen and state, checks what each must do, and keeps a screenshot of each
/// for visual review. Run on several devices (iPhone, iPad window) before a release.
final class ScreensTest: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "UI_TESTING_CAMERA"]   // second flag: camera controls without a camera
        app.launch()
    }

    func testRedesignedScreens() throws {
        // Onboarding and login
        XCTAssertTrue(app.buttons["Passer"].waitForExistence(timeout: 5))
        shot("01_onboarding")
        app.buttons["Passer"].tap()
        XCTAssertTrue(app.buttons["Se connecter"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Se connecter"].isEnabled, "Login enabled with empty fields")
        XCTAssertTrue(app.buttons["Confidentialité"].exists, "Privacy link missing before sign-in")
        shot("02_login")
        signInToChezFlora()

        // Home: availability switch works from the list, filters count it.
        shot("04_home")

        // The restaurant name opens the list of every restaurant; going back keeps the current one.
        app.navigationBars["Chez Flora"].buttons["Chez Flora"].tap()
        let switchButton = app.buttons["Changer d'établissement"]
        XCTAssertTrue(switchButton.waitForExistence(timeout: 3), "No restaurant switch on the title")
        shot("04a_title_menu")
        switchButton.tap()
        XCTAssertTrue(app.buttons["restaurant_Le Maquis du Port"].waitForExistence(timeout: 5), "Restaurant list not shown")
        shot("04b_restaurant_list")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["cameraButton"].waitForExistence(timeout: 4), "Back from the list did not return to Home")
        XCTAssertTrue(app.navigationBars["Chez Flora"].exists, "Restaurant changed without a choice")
        let toggle = app.switches["Mafé bœuf disponible"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), "Availability switch missing on Home")
        toggle.tap()
        // Category bar: a tap brings the category to the top and highlights it.
        let drinks = app.buttons["category_Boisson"]
        XCTAssertTrue(drinks.waitForExistence(timeout: 3), "Category bar missing")
        let bar = app.scrollViews["categoryBar"]
        for _ in 0..<3 where drinks.frame.maxX > bar.frame.maxX { bar.swipeLeft() }   // last chips: scroll the bar
        drinks.tap()
        XCTAssertTrue(app.staticTexts["Jus de bissap"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Jus de bissap"].isHittable, "Category tap did not scroll to its dishes")
        XCTAssertTrue(drinks.isSelected, "Tapped category not highlighted")
        shot("05a_home_category")
        // Work queues behind the filter button.
        app.buttons["filterMenu"].tap()
        XCTAssertTrue(app.buttons["Épuisés · 1"].waitForExistence(timeout: 3), "Sold-out filter did not count the dish")
        app.buttons["Épuisés · 1"].tap()
        XCTAssertTrue(app.staticTexts["Mafé bœuf"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["Thieboudienne"].exists, "Sold-out filter did not filter")
        shot("05_home_sold_out")
        app.buttons["filterMenu"].tap()
        app.buttons["Tous les plats"].tap()
        let search = app.textFields["searchField"]
        search.tap(); search.typeText("koki")
        XCTAssertTrue(app.staticTexts["Koki"].waitForExistence(timeout: 3), "Search did not find the dish")
        XCTAssertFalse(app.staticTexts["Thieboudienne"].exists, "Search did not filter")
        shot("06_home_search")
        app.buttons["Annuler"].firstMatch.tap()   // leaves search and clears the query

        // Dish card: system back button, and a question before losing an edit.
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Thieboudienne'")).firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Fiche plat"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.switches["Disponible"].exists && app.switches["À la une"].exists)
        shot("07_dish_card")
        app.swipeUp()
        shot("08_dish_card_details")
        app.swipeDown()
        app.switches["À la une"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["Abandonner"].waitForExistence(timeout: 3), "No question before discarding an edit")
        shot("09_discard_dialog")
        app.buttons["Abandonner"].tap()
        XCTAssertTrue(app.buttons["cameraButton"].waitForExistence(timeout: 4), "Discard did not return to Home")

        // Camera (controls only on the simulator)
        app.buttons["cameraButton"].tap()
        XCTAssertTrue(app.buttons["shutterButton"].waitForExistence(timeout: 4))
        shot("10_camera")
        let banner = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'photo' OR label CONTAINS 'Inclinez' OR label CONTAINS 'plat'")).firstMatch
        if banner.exists {
            XCTAssertGreaterThanOrEqual(banner.frame.minY, app.navigationBars.firstMatch.frame.maxY,
                                        "Camera hint overlaps the navigation bar")
        }
        app.navigationBars.buttons.firstMatch.tap()

        // Drafts, multi-select, then "who is this photo for"
        XCTAssertTrue(app.buttons["draftsButton"].waitForExistence(timeout: 4))
        app.buttons["draftsButton"].tap()
        XCTAssertTrue(app.navigationBars["Brouillons"].waitForExistence(timeout: 4))
        shot("11_drafts")
        app.buttons["Sélectionner"].tap()
        app.images.firstMatch.tap()
        XCTAssertTrue(app.buttons["Supprimer (1)"].waitForExistence(timeout: 3))
        shot("12_drafts_select")
        app.buttons["Annuler"].tap()
        let draft = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Brouillon du'")).firstMatch
        XCTAssertTrue(draft.waitForExistence(timeout: 4), "Mock drafts not listed")
        draft.tap()
        XCTAssertTrue(app.buttons["Créer un nouveau plat"].waitForExistence(timeout: 4), "Attach screen not shown")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Koki'")).firstMatch.tap()
        XCTAssertTrue(app.buttons["attachButton"].isEnabled, "Attach stays disabled after picking a dish")
        shot("13_attach")

        // New dish: the disabled save button says what is missing; new category sheet.
        app.buttons["Créer un nouveau plat"].tap()
        XCTAssertTrue(app.navigationBars["Nouveau plat"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["Ajoutez un nom et un prix pour enregistrer."].waitForExistence(timeout: 4),
                      "Missing-fields hint not shown")
        shot("14_new_dish")
        app.buttons["newCategoryButton"].tap()
        XCTAssertTrue(app.staticTexts["Nouvelle catégorie"].waitForExistence(timeout: 3))
        shot("15_new_category")
        app.buttons["Annuler"].tap()
        for _ in 0..<3 { app.navigationBars.buttons.firstMatch.tap(); usleep(700_000) }

        // Profile: every row answers on its whole width.
        XCTAssertTrue(app.buttons["profileButton"].waitForExistence(timeout: 4))
        app.buttons["profileButton"].tap()
        XCTAssertTrue(app.buttons["Se déconnecter"].waitForExistence(timeout: 4))
        shot("16_profile")
        let deleteRow = app.staticTexts["Supprimer mon compte"]
        deleteRow.coordinate(withNormalizedOffset: .init(dx: 1.5, dy: 0.5)).tap()   // empty part of the row, right of the label
        XCTAssertTrue(app.staticTexts["Supprimer définitivement votre compte ?"].waitForExistence(timeout: 3),
                      "Profile row dead outside its label")
        shot("17_delete_confirm")
        if app.buttons["Annuler"].exists { app.buttons["Annuler"].tap() }   // sheet on older iOS
        else { app.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.62)).tap() }   // popover: tap outside
        sleep(1)

        // Swipe right goes back from a pushed screen (on the window: in an iPad window it is not at the screen origin).
        app.windows.firstMatch.swipeRight(velocity: .fast)
        XCTAssertTrue(app.buttons["cameraButton"].waitForExistence(timeout: 4), "Back swipe did not return to Home")
    }

    // MARK: - Helpers

    private func signInToChezFlora() {
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
        shot("03_picker")
        // The system "Save password?" prompt can show up late and swallow the tap: dismiss it and tap again.
        for _ in 0..<5 where !app.buttons["cameraButton"].exists {
            if app.buttons["Plus tard"].exists { app.buttons["Plus tard"].tap(); sleep(1) }
            if cta.exists { cta.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap() }
            _ = app.buttons["cameraButton"].waitForExistence(timeout: 3)
        }
        XCTAssertTrue(app.buttons["cameraButton"].exists, "Home not reached")
        // On iOS 27 the prompt can also arrive once Home is on screen.
        if app.buttons["Plus tard"].waitForExistence(timeout: 4) { app.buttons["Plus tard"].tap() }
        sleep(1)
    }

    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
