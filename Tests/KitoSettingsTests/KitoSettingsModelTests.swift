//
//  KitoSettingsModelTests.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import XCTest
@testable import KitoSettings

final class KitoSettingsBadgeTests: XCTestCase {
    func testCountLabels() {
        XCTAssertEqual(KitoSettingsBadge.count(7).label, "7")
        XCTAssertEqual(KitoSettingsBadge.count(100).label, "99+")
        XCTAssertNil(KitoSettingsBadge.count(0).label)
        XCTAssertFalse(KitoSettingsBadge.count(0).isVisible)
        XCTAssertEqual(KitoSettingsBadge.count(120).accessibilityLabel, "More than 99 new")
    }

    func testOtherBadges() {
        XCTAssertEqual(KitoSettingsBadge.new.label, "New")
        XCTAssertNil(KitoSettingsBadge.dot.label)
        XCTAssertTrue(KitoSettingsBadge.dot.isVisible)
        XCTAssertFalse(KitoSettingsBadge.text("").isVisible)
    }
}

final class KitoNotificationTopicTests: XCTestCase {
    func testTogglingChannels() {
        var topic = KitoNotificationTopic("orders", title: "Orders", systemImage: "bag.fill", channels: [.push])
        topic.toggle(.email)
        XCTAssertEqual(topic.channels, [.push, .email])
        XCTAssertEqual(topic.summary, "Push, Email")
        topic.toggle(.push)
        topic.toggle(.email)
        XCTAssertFalse(topic.isOn, "removing the last channel turns the topic off")
        XCTAssertEqual(topic.summary, "Off")
        topic.toggle(.sms)
        XCTAssertTrue(topic.isOn)
        XCTAssertEqual(topic.summary, "SMS")
    }
}

final class KitoSettingsControlLogicTests: XCTestCase {
    func testStepperClampsToRange() {
        XCTAssertEqual(KitoAnyStepper.stepped(9, by: 2, in: 0...10), 10)
        XCTAssertEqual(KitoAnyStepper.stepped(1, by: -5, in: 0...10), 0)
        XCTAssertEqual(KitoAnyStepper.stepped(4, by: 1, in: 0...10), 5)
    }

    func testSliderPercentFormat() {
        XCTAssertEqual(KitoSliderRow.percent(0.456), "46%")
    }

    func testPickerRowErasesSelection() {
        var chosen = 1
        let binding = Binding(get: { chosen }, set: { chosen = $0 })
        let row = KitoPickerRow("Size", selection: binding,
                                options: [KitoPickerOption("Small", value: 1), KitoPickerOption("Large", value: 2)])
        guard case .picker(let picker) = row.settingsRow.kind else { return XCTFail("not a picker") }
        XCTAssertEqual(picker.selectedTitle, "Small")
        picker.selection.wrappedValue = AnyHashable(2)
        XCTAssertEqual(chosen, 2)
        picker.selection.wrappedValue = AnyHashable("wrong type")
        XCTAssertEqual(chosen, 2)
    }
}

final class KitoLanguageTests: XCTestCase {
    func testSuggestedFollowsDeviceOrder() {
        let suggested = KitoLanguage.suggested(from: KitoLanguage.common, preferred: ["sw-KE", "fr-FR", "sw", "xx"])
        XCTAssertEqual(suggested.map(\.code), ["sw", "fr"])
    }

    func testScriptCodesMatchExactly() {
        let suggested = KitoLanguage.suggested(from: KitoLanguage.common, preferred: ["zh-Hans-CN"])
        XCTAssertEqual(suggested.map(\.code), ["zh-Hans"])
    }

    func testSearchByEnglishNameOrCode() {
        XCTAssertEqual(KitoSettingsSearch.filter(KitoLanguage.common, query: "swahili").map(\.code), ["sw"])
        XCTAssertEqual(KitoSettingsSearch.filter(KitoLanguage.common, query: "amh").map(\.code), ["am"])
        XCTAssertEqual(KitoSettingsSearch.filter(KitoLanguage.common, query: "francais").map(\.code), ["fr"])
    }
}

@MainActor
final class KitoSettingsViewLogicTests: XCTestCase {
    func testInitials() {
        XCTAssertEqual(KitoSettingsProfileHeader.initials("Wycliff N"), "WN")
        XCTAssertEqual(KitoSettingsProfileHeader.initials("amina"), "A")
        XCTAssertEqual(KitoSettingsProfileHeader.initials("Wycliff Kamau Njenga"), "WK")
        XCTAssertEqual(KitoSettingsProfileHeader.initials(""), "")
    }

    func testTextSizeLabel() {
        XCTAssertEqual(KitoTextSizeControl.label(1.0), "Default")
        XCTAssertEqual(KitoTextSizeControl.label(1.15), "115%")
    }

    func testQuietHoursWaitText() {
        XCTAssertEqual(KitoQuietHoursEditor.duration(45), "45 min")
        XCTAssertEqual(KitoQuietHoursEditor.duration(120), "2 h")
        XCTAssertEqual(KitoQuietHoursEditor.duration(135), "2 h 15 min")
    }

    func testDialOffsetPutsMidnightAtTop() {
        let top = KitoQuietHoursDial.offset(hour: 0, radius: 10)
        XCTAssertEqual(top.width, 0, accuracy: 0.0001)
        XCTAssertEqual(top.height, -10, accuracy: 0.0001)
        let six = KitoQuietHoursDial.offset(hour: 6, radius: 10)
        XCTAssertEqual(six.width, 10, accuracy: 0.0001)
    }
}

final class KitoAppearanceModelTests: XCTestCase {
    func testModesMapToColorSchemes() {
        XCTAssertNil(KitoAppearanceMode.system.colorScheme)
        XCTAssertEqual(KitoAppearanceMode.dark.colorScheme, .dark)
        XCTAssertEqual(KitoAppearanceMode(storedValue: "light"), .light)
    }

    func testAccentLookupFallsBackToFirst() {
        XCTAssertEqual(KitoAccentOption.option("green")?.name, "Green")
        XCTAssertEqual(KitoAccentOption.option("nope")?.id, "blue")
    }

    func testAppIconOptionIDs() {
        XCTAssertEqual(KitoAppIconOption("Default", alternateIconName: nil).id, "primary")
        XCTAssertEqual(KitoAppIconOption("Night", alternateIconName: "Night").id, "Night")
    }
}
