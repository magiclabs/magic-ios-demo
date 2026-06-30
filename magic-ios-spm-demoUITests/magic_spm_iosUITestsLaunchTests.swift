//
//  magic_spm_iosUITestsLaunchTests.swift
//  magic-ios-spm-demoUITests
//

import XCTest

class magic_spm_iosUITestsLaunchTests: XCTestCase {

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
