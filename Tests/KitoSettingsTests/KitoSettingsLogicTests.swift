//
//  KitoSettingsLogicTests.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
@testable import KitoSettings

final class KitoQuietHoursTests: XCTestCase {
    private func time(_ hour: Int, _ minute: Int = 0) -> KitoTimeOfDay { KitoTimeOfDay(hour: hour, minute: minute) }
    private let night = KitoSettingsQuietHours(start: KitoTimeOfDay(hour: 22), end: KitoTimeOfDay(hour: 7))

    func testTimeOfDayWraps() {
        XCTAssertEqual(time(25, 10), time(1, 10))
        XCTAssertEqual(time(-1), time(23))
        XCTAssertEqual(KitoTimeOfDay(minutesSinceMidnight: 1_500).formatted, "01:00")
        XCTAssertEqual(time(7, 5).formatted, "07:05")
    }

    func testWindowAcrossMidnight() {
        XCTAssertTrue(night.crossesMidnight)
        XCTAssertTrue(night.contains(time(22)))
        XCTAssertTrue(night.contains(time(23, 59)))
        XCTAssertTrue(night.contains(time(0)))
        XCTAssertTrue(night.contains(time(6, 59)))
        XCTAssertFalse(night.contains(time(7)))
        XCTAssertFalse(night.contains(time(12)))
        XCTAssertFalse(night.contains(time(21, 59)))
        XCTAssertEqual(night.durationMinutes, 9 * 60)
    }

    func testSameDayWindow() {
        let lunch = KitoSettingsQuietHours(start: time(12), end: time(13, 30))
        XCTAssertFalse(lunch.crossesMidnight)
        XCTAssertTrue(lunch.contains(time(13)))
        XCTAssertFalse(lunch.contains(time(13, 30)))
        XCTAssertFalse(lunch.contains(time(11, 59)))
        XCTAssertEqual(lunch.formattedDuration, "1 h 30 min")
    }

    func testStartEqualToEndIsAllDay() {
        let always = KitoSettingsQuietHours(start: time(9), end: time(9))
        XCTAssertEqual(always.durationMinutes, 1_440)
        XCTAssertTrue(always.contains(time(3)))
        XCTAssertEqual(always.formattedDuration, "24 h")
    }

    func testOverlaps() {
        let earlyMorning = KitoSettingsQuietHours(start: time(5), end: time(8))
        let evening = KitoSettingsQuietHours(start: time(18), end: time(22))
        let lateNight = KitoSettingsQuietHours(start: time(21), end: time(23))
        XCTAssertTrue(night.overlaps(earlyMorning))
        XCTAssertTrue(earlyMorning.overlaps(night))
        XCTAssertFalse(night.overlaps(evening), "22:00 end touches 22:00 start without sharing a minute")
        XCTAssertTrue(night.overlaps(lateNight))
        XCTAssertFalse(evening.overlaps(earlyMorning))
    }

    func testIsQuietAtDateUsesCalendarAndEnabled() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Africa/Nairobi"))
        // 2026-09-24 20:30 UTC is 23:30 in Nairobi.
        let date = Date(timeIntervalSince1970: 1_790_281_800)
        XCTAssertEqual(KitoTimeOfDay(date, calendar: calendar), time(23, 30))
        XCTAssertTrue(night.isQuiet(at: date, calendar: calendar))
        var off = night
        off.isEnabled = false
        XCTAssertFalse(off.isQuiet(at: date, calendar: calendar))
    }

    func testMinutesUntilQuiet() {
        XCTAssertEqual(night.minutesUntilQuiet(from: time(20, 40)), 80)
        XCTAssertEqual(night.minutesUntilQuiet(from: time(23)), 0)
        XCTAssertEqual(night.minutesUntilQuiet(from: time(7)), 15 * 60)
    }

    func testFormatted() {
        XCTAssertEqual(night.formatted, "22:00 – 07:00")
        XCTAssertEqual(night.formattedDuration, "9 h")
        XCTAssertEqual(KitoSettingsQuietHours(start: time(1), end: time(1, 45)).formattedDuration, "45 min")
    }
}

final class KitoAppVersionTests: XCTestCase {
    func testStandardAndFull() {
        let version = KitoAppVersion(version: "1.4.2", build: "318")
        XCTAssertEqual(version.formatted(), "1.4.2 (318)")
        XCTAssertEqual(version.formatted(.full), "Version 1.4.2 (Build 318)")
        XCTAssertEqual(version.formatted(.short), "1.4")
    }

    func testDropsMissingOrRepeatedBuild() {
        XCTAssertEqual(KitoAppVersion(version: "2.0").formatted(), "2.0")
        XCTAssertEqual(KitoAppVersion(version: "2.0", build: " ").formatted(.full), "Version 2.0")
        XCTAssertEqual(KitoAppVersion(version: "3.1", build: "3.1").formatted(), "3.1")
    }

    func testShortVersion() {
        XCTAssertEqual(KitoAppVersion.shortVersion("2"), "2.0")
        XCTAssertEqual(KitoAppVersion.shortVersion("1.10.0-beta"), "1.10")
        XCTAssertEqual(KitoAppVersion.shortVersion("0.9.1+45"), "0.9")
    }

    func testTrimsWhitespace() {
        XCTAssertEqual(KitoAppVersion(version: " 1.2.3\n", build: " 7 ").formatted(), "1.2.3 (7)")
    }
}

final class KitoDeleteConfirmationTests: XCTestCase {
    private let check = KitoDeleteConfirmation()

    func testExactPhraseConfirms() {
        XCTAssertTrue(check.isConfirmed(by: "DELETE"))
        XCTAssertTrue(check.isConfirmed(by: "  DELETE \n"))
    }

    func testCaseSensitiveByDefault() {
        XCTAssertFalse(check.isConfirmed(by: "delete"))
        XCTAssertTrue(KitoDeleteConfirmation(isCaseSensitive: false).isConfirmed(by: "Delete"))
    }

    func testRejectsPartialAndLongerInput() {
        XCTAssertFalse(check.isConfirmed(by: "DELET"))
        XCTAssertFalse(check.isConfirmed(by: "DELETED"))
        XCTAssertFalse(check.isConfirmed(by: ""))
    }

    func testMatchedCountAndMistakes() {
        XCTAssertEqual(check.matchedCount(of: "DEL"), 3)
        XCTAssertEqual(check.matchedCount(of: "DEX"), 2)
        XCTAssertFalse(check.hasMistake(in: "DEL"))
        XCTAssertTrue(check.hasMistake(in: "DEX"))
        XCTAssertTrue(check.hasMistake(in: "DELETEX"))
        XCTAssertFalse(check.hasMistake(in: ""))
        XCTAssertEqual(check.progress(of: "DEL"), 0.5, accuracy: 0.0001)
    }

    func testEmptyPhraseNeverConfirms() {
        XCTAssertFalse(KitoDeleteConfirmation(phrase: "").isConfirmed(by: ""))
        XCTAssertEqual(KitoDeleteConfirmation(phrase: "").progress(of: "x"), 0)
    }

    func testRequestTrimsFeedback() {
        XCTAssertEqual(KitoDeleteRequest(reason: nil, feedback: "  too noisy \n").feedback, "too noisy")
    }
}
