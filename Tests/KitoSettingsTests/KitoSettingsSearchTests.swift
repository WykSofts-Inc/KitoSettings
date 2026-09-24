//
//  KitoSettingsSearchTests.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import XCTest
@testable import KitoSettings

private struct Item: KitoSettingsSearchable, Equatable {
    let searchTitle: String
    var searchSubtitle: String?
    var searchKeywords: [String] = []
}

final class KitoSettingsSearchTests: XCTestCase {
    private let items = [
        Item(searchTitle: "Notifications", searchSubtitle: "Alerts, sounds, badges"),
        Item(searchTitle: "Wi-Fi", searchKeywords: ["network", "internet"]),
        Item(searchTitle: "Appearance", searchSubtitle: "Dark mode, text size"),
        Item(searchTitle: "Café mode"),
        Item(searchTitle: "Face ID & passcode", searchKeywords: ["unlock"]),
    ]

    func testEmptyQueryReturnsEverythingInOrder() {
        XCTAssertEqual(KitoSettingsSearch.filter(items, query: "  "), items)
        XCTAssertEqual(KitoSettingsSearch.score(items[0], query: ""), 1)
    }

    func testTitlePrefixScoresHighest() {
        XCTAssertEqual(KitoSettingsSearch.score(items[0], query: "noti"), 1)
    }

    func testMatchesHiddenKeywords() {
        XCTAssertEqual(KitoSettingsSearch.filter(items, query: "network").map(\.searchTitle), ["Wi-Fi"])
        XCTAssertEqual(KitoSettingsSearch.score(items[1], query: "internet"), 0.75, accuracy: 0.0001)
    }

    func testMatchesSubtitleWords() {
        XCTAssertEqual(KitoSettingsSearch.filter(items, query: "dark").map(\.searchTitle), ["Appearance"])
    }

    func testIgnoresCaseAndAccents() {
        XCTAssertTrue(KitoSettingsSearch.matches(items[3], query: "CAFE"))
        XCTAssertEqual(KitoSettingsSearch.highlightRange(in: "Café mode", query: "cafe").map { "Café mode"[$0] }, "Café")
    }

    func testEveryWordMustMatch() {
        XCTAssertTrue(KitoSettingsSearch.matches(items[4], query: "face unlock"))
        XCTAssertFalse(KitoSettingsSearch.matches(items[4], query: "face network"))
    }

    func testMidTitleNeedsThreeLetters() {
        XCTAssertTrue(KitoSettingsSearch.matches(items[0], query: "cat"))
        XCTAssertFalse(KitoSettingsSearch.matches(items[0], query: "ca"))
    }

    func testBestMatchComesFirst() {
        let list = [Item(searchTitle: "Privacy", searchKeywords: ["mode"]), Item(searchTitle: "Mode")]
        XCTAssertEqual(KitoSettingsSearch.filter(list, query: "mode").map(\.searchTitle), ["Mode", "Privacy"])
    }

    func testNoMatch() {
        XCTAssertTrue(KitoSettingsSearch.filter(items, query: "bluetooth").isEmpty)
        XCTAssertNil(KitoSettingsSearch.highlightRange(in: "Wi-Fi", query: "blue"))
    }

    func testTokensSplitOnPunctuation() {
        XCTAssertEqual(KitoSettingsSearch.tokens("Face ID & Passcode"), ["face", "id", "passcode"])
    }
}

final class KitoSettingsSectionFilterTests: XCTestCase {
    private var sections: [KitoSettingsSection] {
        [
            KitoSettingsSection("General", footer: "Applies everywhere.") {
                KitoToggleRow("Haptics", systemImage: "hand.tap.fill", isOn: .constant(true)).keywords("vibration")
                KitoValueRow("Version", value: "1.0")
            },
            KitoSettingsSection("Privacy") {
                KitoToggleRow("Personalised ads", isOn: .constant(false))
                KitoLinkRow("Policy", url: URL(string: "https://example.com")!)
            },
            KitoSettingsSection("Language") {
                KitoPickerRow("App language", selection: .constant("sw"),
                              options: [KitoPickerOption("Kiswahili", value: "sw"), KitoPickerOption("Français", value: "fr")])
            },
        ]
    }

    func testKeepsOnlyMatchingRowsAndDropsEmptySections() {
        let result = KitoSettingsSection.filter(sections, query: "vibration")
        XCTAssertEqual(result.map(\.title), ["General"])
        XCTAssertEqual(result.first?.rows.map(\.title), ["Haptics"])
        XCTAssertNil(result.first?.footer)
    }

    func testMatchingSectionTitleKeepsEveryRow() {
        let result = KitoSettingsSection.filter(sections, query: "privacy")
        XCTAssertEqual(result.first?.rows.count, 2)
    }

    func testPickerOptionsAreSearchable() {
        XCTAssertEqual(KitoSettingsSection.filter(sections, query: "francais").first?.rows.first?.title, "App language")
    }

    func testEmptyQueryKeepsFooters() {
        XCTAssertEqual(KitoSettingsSection.filter(sections, query: "").first?.footer, "Applies everywhere.")
    }

    func testMatchCount() {
        XCTAssertEqual(KitoSettingsSection.matchCount(sections, query: "p"), 2)
        XCTAssertEqual(KitoSettingsSection.matchCount(sections, query: "zzz"), 0)
    }

    func testBuilderHandlesConditionsAndLoops() {
        let showsExtra = false
        let section = KitoSettingsSection("Loop") {
            for name in ["A", "B"] { KitoValueRow(name, value: name) }
            if showsExtra { KitoValueRow("C", value: "C") } else { KitoInfoRow("No extras") }
        }
        XCTAssertEqual(section.rows.map(\.title), ["A", "B", "No extras"])
    }

    func testRowModifiers() {
        let row = KitoValueRow("Build", value: "42").badge(.new).rowDisabled().rowID("build")
        XCTAssertEqual(row.badge, .new)
        XCTAssertTrue(row.isDisabled)
        XCTAssertEqual(row.id, "build")
    }
}
