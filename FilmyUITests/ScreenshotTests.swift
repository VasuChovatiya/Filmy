import XCTest

/// Captures the README screenshots and drives the flow recorded for the README GIF. Uses live TMDB
/// data, so it needs a token, and is skipped unless `FILMY_CAPTURE=1`:
///
///     TEST_RUNNER_FILMY_CAPTURE=1 xcodebuild test -only-testing:FilmyUITests/ScreenshotTests ...
@MainActor
final class ScreenshotTests: XCTestCase {
    private func launch() throws -> XCUIApplication {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["FILMY_CAPTURE"] == "1", "Set FILMY_CAPTURE=1 to capture screenshots.")
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["-UITestInMemoryStore"]
        app.launch()
        return app
    }

    /// Attaches the screenshot to the result bundle and, when `FILMY_CAPTURE_DIR` is set, also writes
    /// it there as `<name>.png` (the simulator can write to the Mac's file system).
    private func capture(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        if let directory = ProcessInfo.processInfo.environment["FILMY_CAPTURE_DIR"] {
            let url = URL(fileURLWithPath: directory).appending(path: "\(name).png")
            XCTAssertNoThrow(try screenshot.pngRepresentation.write(to: url))
        }
    }

    /// Lets posters and backdrops finish loading before a capture.
    private func settle(_ seconds: TimeInterval = 2.5) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    func testCaptureScreens() throws {
        let app = try launch()
        let cards = app.descendants(matching: .any).matching(identifier: "movie-card")
        XCTAssertTrue(cards.firstMatch.waitForExistence(timeout: 15))
        settle(4)
        capture("01-discover")

        cards.element(boundBy: 1).tap()
        settle(3)
        capture("02-detail")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        settle(1)

        for index in [0, 1, 2, 3] {
            cards.element(boundBy: index).tap()
            XCTAssertTrue(app.buttons["Add to Favorites"].waitForExistence(timeout: 5))
            app.buttons["Add to Favorites"].tap()
            app.navigationBars.buttons.element(boundBy: 0).tap()
            settle(1)
        }

        app.tab("Search").tap()
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("dune")
        settle(3)
        capture("03-search")

        // A well-known title, so every section (trailer, videos, where to watch, more like this) has data.
        let duneTwo = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == 'search-result' AND label BEGINSWITH 'Dune: Part Two'"))
            .firstMatch
        XCTAssertTrue(duneTwo.waitForExistence(timeout: 5))
        duneTwo.tap()
        settle(3)
        capture("04-detail-trailer")
        app.swipeUp()
        settle(2.5)
        capture("05-detail-sections")
        app.swipeUp()
        settle(2.5)
        capture("06-detail-more")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.tab("Favorites").tap()
        settle(2)
        capture("07-favorites")
    }

    /// Paced for a screen recording: poster zooms into the detail, scroll, zoom back, repeat.
    func testZoomFlowForRecording() throws {
        let app = try launch()
        let cards = app.descendants(matching: .any).matching(identifier: "movie-card")
        XCTAssertTrue(cards.firstMatch.waitForExistence(timeout: 15))
        settle(4)

        for index in [0, 4] {
            cards.element(boundBy: index).tap()
            settle(2)
            app.swipeUp(velocity: .slow)
            settle(1.5)
            app.swipeDown(velocity: .slow)
            settle(1)
            app.navigationBars.buttons.element(boundBy: 0).tap()
            settle(1.5)
        }
    }
}
