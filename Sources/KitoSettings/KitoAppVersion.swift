//
//  KitoAppVersion.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// The app's marketing version and build number, formatted for an About screen.
public struct KitoAppVersion: Hashable, Sendable {
    public enum Style: Sendable {
        /// "1.4" — major and minor only.
        case short
        /// "1.4.2 (318)".
        case standard
        /// "Version 1.4.2 (Build 318)".
        case full
    }

    /// CFBundleShortVersionString, e.g. "1.4.2".
    public var version: String
    /// CFBundleVersion, e.g. "318". Nil or empty when there isn't one.
    public var build: String?

    public init(version: String, build: String? = nil) {
        self.version = version.trimmingCharacters(in: .whitespacesAndNewlines)
        self.build = build?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Read from a bundle's Info.plist; "1.0" when the version is missing.
    public init(bundle: Bundle) {
        let info = bundle.infoDictionary ?? [:]
        self.init(version: info["CFBundleShortVersionString"] as? String ?? "1.0",
                  build: info["CFBundleVersion"] as? String)
    }

    /// The running app's version.
    public static var current: KitoAppVersion { KitoAppVersion(bundle: .main) }

    /// The build, unless it's empty or just repeats the version.
    var meaningfulBuild: String? {
        guard let build, !build.isEmpty, build != version else { return nil }
        return build
    }

    public func formatted(_ style: Style = .standard) -> String {
        switch style {
        case .short:
            return Self.shortVersion(version)
        case .standard:
            guard let build = meaningfulBuild else { return version }
            return "\(version) (\(build))"
        case .full:
            guard let build = meaningfulBuild else { return "Version \(version)" }
            return "Version \(version) (Build \(build))"
        }
    }

    /// "1.4.2" → "1.4", "2" → "2.0", "1.10.0-beta" → "1.10".
    static func shortVersion(_ version: String) -> String {
        let core = version.split(whereSeparator: { $0 == "-" || $0 == "+" || $0 == " " }).first.map(String.init) ?? version
        let parts = core.split(separator: ".").map(String.init)
        guard let major = parts.first, !major.isEmpty else { return version }
        let minor = parts.count > 1 ? parts[1] : "0"
        return "\(major).\(minor)"
    }
}
