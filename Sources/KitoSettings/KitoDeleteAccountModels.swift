//
//  KitoDeleteAccountModels.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// Why someone is leaving.
public struct KitoDeleteReason: Identifiable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var systemImage: String

    public init(_ id: String, title: String, systemImage: String) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
    }

    public static let defaults: [KitoDeleteReason] = [
        KitoDeleteReason("unused", title: "I don't use it any more", systemImage: "moon.zzz.fill"),
        KitoDeleteReason("duplicate", title: "I have another account", systemImage: "person.2.fill"),
        KitoDeleteReason("privacy", title: "I'm worried about my privacy", systemImage: "lock.fill"),
        KitoDeleteReason("noise", title: "Too many notifications", systemImage: "bell.badge.fill"),
        KitoDeleteReason("missing", title: "It's missing something I need", systemImage: "puzzlepiece.fill"),
        KitoDeleteReason("other", title: "Something else", systemImage: "ellipsis.bubble.fill"),
    ]
}

/// What `KitoDeleteAccountFlow` hands your delete call.
public struct KitoDeleteRequest: Hashable, Sendable {
    public var reason: KitoDeleteReason?
    /// Anything they typed about why; empty when nothing.
    public var feedback: String

    public init(reason: KitoDeleteReason?, feedback: String) {
        self.reason = reason
        self.feedback = feedback.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// The steps of `KitoDeleteAccountFlow`.
public enum KitoDeleteStep: Int, CaseIterable, Sendable {
    case reason, confirm, farewell
}
