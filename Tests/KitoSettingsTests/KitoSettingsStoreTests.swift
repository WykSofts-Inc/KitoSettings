//
//  KitoSettingsStoreTests.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import XCTest
@testable import KitoSettings

private enum Theme: String, KitoSettingValue { case light, dark }

private struct Profile: Codable, Equatable, Sendable {
    var name: String
    var age: Int
}

private enum Keys {
    static let haptics = KitoSettingKey("haptics", default: true)
    static let volume = KitoSettingKey("volume", default: 0.5)
    static let count = KitoSettingKey("count", default: 3)
    static let name = KitoSettingKey("name", default: "Wycliff")
    static let theme = KitoSettingKey("theme", default: Theme.light)
    static let tags = KitoSettingKey("tags", default: ["a"])
    static let site = KitoSettingKey("site", default: URL(string: "https://example.com")!)
    static let since = KitoSettingKey("since", default: Date(timeIntervalSince1970: 0))
    static let nickname = KitoSettingKey<String?>("nickname", default: "Wyk")
    static let profile = KitoSettingKey("profile", default: KitoCodableSetting(Profile(name: "A", age: 1)))
}

final class KitoSettingsStoreTests: XCTestCase {
    private var suiteName = ""
    private var defaults: UserDefaults!
    private var store: KitoSettingsStore!

    override func setUp() {
        super.setUp()
        suiteName = "KitoSettingsTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        store = KitoSettingsStore(defaults: defaults, namespace: "app")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testDefaultsBeforeAnythingIsSet() {
        XCTAssertTrue(store[Keys.haptics])
        XCTAssertEqual(store[Keys.theme], .light)
        XCTAssertFalse(store.contains(Keys.haptics))
    }

    func testRoundTripsEveryType() {
        store[Keys.haptics] = false
        store[Keys.volume] = 0.8
        store[Keys.count] = 7
        store[Keys.name] = "Amina"
        store[Keys.theme] = .dark
        store[Keys.tags] = ["x", "y"]
        store[Keys.site] = URL(string: "https://wyksoftsinc.com")!
        store[Keys.since] = Date(timeIntervalSince1970: 1_000)
        store[Keys.profile] = KitoCodableSetting(Profile(name: "Wycliff", age: 30))

        let reread = KitoSettingsStore(defaults: defaults, namespace: "app")
        XCTAssertFalse(reread[Keys.haptics])
        XCTAssertEqual(reread[Keys.volume], 0.8)
        XCTAssertEqual(reread[Keys.count], 7)
        XCTAssertEqual(reread[Keys.name], "Amina")
        XCTAssertEqual(reread[Keys.theme], .dark)
        XCTAssertEqual(reread[Keys.tags], ["x", "y"])
        XCTAssertEqual(reread[Keys.site].host, "wyksoftsinc.com")
        XCTAssertEqual(reread[Keys.since], Date(timeIntervalSince1970: 1_000))
        XCTAssertEqual(reread[Keys.profile].value, Profile(name: "Wycliff", age: 30))
    }

    func testOptionalNilDiffersFromUnset() {
        XCTAssertEqual(store[Keys.nickname], "Wyk")
        store[Keys.nickname] = nil
        XCTAssertNil(store[Keys.nickname])
        XCTAssertTrue(store.contains(Keys.nickname))
        store[Keys.nickname] = "Njenga"
        XCTAssertEqual(store[Keys.nickname], "Njenga")
    }

    func testWrongStoredTypeFallsBackToDefault() {
        defaults.set("loud", forKey: "app.volume")
        XCTAssertEqual(store[Keys.volume], 0.5)
        defaults.set("purple", forKey: "app.theme")
        XCTAssertEqual(store[Keys.theme], .light)
    }

    func testIntegerReadsAsDouble() {
        defaults.set(2, forKey: "app.volume")
        XCTAssertEqual(store[Keys.volume], 2)
    }

    func testNamespacedKeys() {
        store[Keys.count] = 9
        XCTAssertEqual(defaults.integer(forKey: "app.count"), 9)
        XCTAssertEqual(KitoSettingsStore(defaults: defaults, namespace: "").storageKey("count"), "count")
    }

    func testResetOneKey() {
        store[Keys.count] = 9
        store[Keys.name] = "Amina"
        store.reset(Keys.count)
        XCTAssertEqual(store[Keys.count], 3)
        XCTAssertFalse(store.contains(Keys.count))
        XCTAssertEqual(store[Keys.name], "Amina")
    }

    func testResetSeveralKeys() {
        store[Keys.count] = 9
        store[Keys.name] = "Amina"
        store[Keys.haptics] = false
        store.reset([Keys.count.erased, Keys.name.erased])
        XCTAssertEqual(store[Keys.count], 3)
        XCTAssertEqual(store[Keys.name], "Wycliff")
        XCTAssertFalse(store[Keys.haptics])
    }

    func testResetAllOnlyTouchesItsNamespace() {
        store[Keys.count] = 9
        store[Keys.theme] = .dark
        defaults.set("keep", forKey: "other.value")
        defaults.set("keep", forKey: "appish")
        store.resetAll()
        XCTAssertEqual(store[Keys.count], 3)
        XCTAssertEqual(store[Keys.theme], .light)
        XCTAssertEqual(defaults.string(forKey: "other.value"), "keep")
        XCTAssertEqual(defaults.string(forKey: "appish"), "keep")
    }

    func testResetAllWithoutNamespaceDoesNothing() {
        let bare = KitoSettingsStore(defaults: defaults, namespace: "")
        bare[Keys.count] = 4
        bare.resetAll()
        XCTAssertEqual(bare[Keys.count], 4)
    }

    func testWritesPostChangeNotification() {
        let posted = expectation(forNotification: KitoSettingsStore.didChange, object: nil)
        store[Keys.haptics] = false
        wait(for: [posted], timeout: 1)
    }
}

// MARK: - Keys as static members

extension KitoSettingKey where Value == Int {
    static let launches = KitoSettingKey("launches", default: 1)
}

/// Compiles only if `@KitoSetting(.launches)` infers its type from the key.
private struct LaunchCounter: View {
    @KitoSetting(.launches, store: KitoSettingsStore(namespace: "kito.tests")) private var launches

    var body: some View {
        Stepper("Launches: \(launches)", value: $launches, in: 0...10)
    }
}

final class KitoSettingKeyMemberTests: XCTestCase {
    func testStaticKeysResolveByLeadingDot() {
        let defaults = UserDefaults(suiteName: "KitoSettingKeyMemberTests")!
        defer { defaults.removePersistentDomain(forName: "KitoSettingKeyMemberTests") }
        let store = KitoSettingsStore(defaults: defaults, namespace: "app")
        XCTAssertEqual(store[.launches], 1)
        store[.launches] = 5
        XCTAssertEqual(store.value(for: .launches), 5)
        store.reset(.launches)
        XCTAssertEqual(store[.launches], 1)
    }
}
