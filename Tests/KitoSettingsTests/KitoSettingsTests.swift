//
//  KitoSettingsTests.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
@testable import KitoSettings

final class KitoSettingsVersionTests: XCTestCase {
    func testPackageVersion() {
        XCTAssertEqual(KitoSettings.version, "0.1.0")
    }
}
