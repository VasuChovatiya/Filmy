import XCTest

/// End-to-end smoke tests on the offline demo catalog, so they pass without a TMDB token or network.
@MainActor
final class FilmyUITests: XCTestCase {
    private func launch() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["-UITestDemoData", "-UITestInMemoryStore"]
        app.launch()
        return app
    }

    func testOpenMovieAndSaveItToFavorites() {
        let app = launch()
        let card = app.element("movie-card")
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        let summary = card.label

        card.tap()
        let addButton = app.buttons["Add to Favorites"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()
        XCTAssertTrue(app.buttons["Remove from Favorites"].waitForExistence(timeout: 2))

        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tab("Favorites").tap()

        let saved = app.element("favorite-card")
        XCTAssertTrue(saved.waitForExistence(timeout: 5))
        XCTAssertEqual(saved.label, summary)
    }

    func testSearchFindsAMovie() {
        let app = launch()
        app.tab("Search").tap()

        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("orbit")

        let result = app.element("search-result")
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        XCTAssertTrue(result.label.hasPrefix("Orbit of Glass"), result.label)
    }

    func testMoreLikeThisOpensAnotherMovie() {
        let app = launch()
        let card = app.element("movie-card")
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        card.tap()

        let related = app.element("related-card")
        for _ in 0..<6 where !related.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(related.isHittable)
        let title = String(related.label.prefix { $0 != "," })

        related.tap()

        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5), "Expected the detail for \(title)")
    }
}

extension XCUIApplication {
    /// A tab button. iPhone shows a tab bar; iPad shows the tabs at the top, outside any tab bar.
    func tab(_ title: String) -> XCUIElement {
        let inTabBar = tabBars.buttons[title]
        return inTabBar.exists ? inTabBar : buttons[title].firstMatch
    }

    /// Any element with this accessibility identifier. Rows and cards surface as buttons or cells
    /// depending on the container, so this doesn't pin the type.
    func element(_ identifier: String) -> XCUIElement {
        descendants(matching: .any).matching(identifier: identifier).firstMatch
    }
}
