//
//  BeloteUITests.swift
//  BeloteUITests
//
//  Created by Alexandre Odet on 30/07/2026.
//

import XCTest

final class BeloteUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCreatesMatchFromEmptyState() throws {
        let app = launchApp()

        app.buttons["new-match-empty-button"].tap()

        XCTAssertTrue(app.navigationBars["Nouvelle partie"].waitForExistence(timeout: 2))
        app.buttons["Créer"].tap()

        XCTAssertTrue(app.staticTexts["Nous vs Eux"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Code"].exists)
    }

    @MainActor
    func testOpensJoinMatchSheetFromEmptyState() throws {
        let app = launchApp()

        app.buttons["join-match-empty-button"].tap()

        XCTAssertTrue(app.navigationBars["Rejoindre"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.textFields["join-match-code-field"].exists)
        XCTAssertTrue(app.buttons["join-match-import-button"].exists)
    }

    @MainActor
    func testShowsQRCodeForCreatedMatch() throws {
        let app = launchApp()

        app.buttons["new-match-empty-button"].tap()
        XCTAssertTrue(app.navigationBars["Nouvelle partie"].waitForExistence(timeout: 2))
        app.buttons["Créer"].tap()
        XCTAssertTrue(app.staticTexts["Nous vs Eux"].waitForExistence(timeout: 2))

        app.buttons["show-match-qr-code-button"].tap()

        XCTAssertTrue(app.navigationBars["Rejoindre la partie"].waitForExistence(timeout: 2))
        let joinURL = app.staticTexts["match-join-url-text"]
        XCTAssertTrue(joinURL.waitForExistence(timeout: 2))
        XCTAssertTrue(joinURL.label.hasPrefix("belote://join?code="))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments = ["-uiTesting"]
            app.launch()
        }
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
        return app
    }
}
