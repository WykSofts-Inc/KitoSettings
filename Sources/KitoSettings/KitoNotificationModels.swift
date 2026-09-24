//
//  KitoNotificationModels.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

/// Where a notification can arrive.
public enum KitoNotificationChannel: String, CaseIterable, Identifiable, Codable, Sendable {
    case push, email, sms

    public var id: Self { self }

    public var title: String {
        switch self {
        case .push: return "Push"
        case .email: return "Email"
        case .sms: return "SMS"
        }
    }

    public var systemImage: String {
        switch self {
        case .push: return "iphone.radiowaves.left.and.right"
        case .email: return "envelope.fill"
        case .sms: return "message.fill"
        }
    }
}

/// A kind of notification people can turn on or off, such as "Order updates".
public struct KitoNotificationTopic: Identifiable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var subtitle: String?
    public var systemImage: String
    public var color: Color
    public var isOn: Bool
    /// The channels this topic arrives on while it's on.
    public var channels: Set<KitoNotificationChannel>

    public init(_ id: String, title: String, subtitle: String? = nil, systemImage: String,
                color: Color = .red, isOn: Bool = true, channels: Set<KitoNotificationChannel> = [.push]) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.color = color
        self.isOn = isOn
        self.channels = channels
    }

    /// Turns a channel on or off, never leaving an enabled topic with no channel: removing the
    /// last one turns the topic off instead.
    public mutating func toggle(_ channel: KitoNotificationChannel) {
        if channels.contains(channel) {
            channels.remove(channel)
            if channels.isEmpty { isOn = false }
        } else {
            channels.insert(channel)
            isOn = true
        }
    }

    /// "Push, Email", or "Off".
    public var summary: String {
        guard isOn, !channels.isEmpty else { return "Off" }
        return KitoNotificationChannel.allCases.filter(channels.contains).map(\.title).joined(separator: ", ")
    }
}
