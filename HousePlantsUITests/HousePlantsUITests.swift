import XCTest

final class HousePlantsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-hasCompletedOnboarding", "YES",
            "-appearanceMode", "light",
            "-catalogLayout", "grid"
        ]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testCatalogOpensNativePlantDetail() throws {
        XCTAssertTrue(app.tabBars.buttons["Discover"].waitForExistence(timeout: 8))

        let jadeCard = app.descendants(matching: .any)["catalog.card.featured.p_012"].firstMatch
        XCTAssertTrue(jadeCard.waitForExistence(timeout: 8))
        jadeCard.tap()

        XCTAssertTrue(app.navigationBars["Jade Plant"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["plant-detail.jungle-toggle"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.tabBars.firstMatch.exists, "The tab bar should stay out of a focused detail flow")
    }

    @MainActor
    func testCatalogFiltersAreReachable() throws {
        let filters = app.buttons["catalog.filters"]
        XCTAssertTrue(filters.waitForExistence(timeout: 8))
        filters.tap()

        XCTAssertTrue(app.navigationBars["Refine plants"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.switches["Pet-safe plants only"].exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Show '")).firstMatch.exists)
    }

    @MainActor
    func testToolsCanBeFoundByTask() throws {
        XCTAssertTrue(app.tabBars.buttons["Tools"].waitForExistence(timeout: 8))
        app.tabBars.buttons["Tools"].tap()

        let search = app.textFields["tools.search"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("pet safety")

        XCTAssertTrue(app.buttons["Toxicity Checker"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Watering Guide"].exists)
    }
}
