//
//  KitoAccountSection.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

public extension KitoSettingsSection {
    /// The usual account rows: email and phone, change password, sign out (asks first) and
    /// delete account. Leave out a closure to leave out its row.
    static func account(_ title: String = "Account", email: String? = nil, phone: String? = nil,
                        onChangePassword: (() -> Void)? = nil,
                        onSignOut: (() -> Void)? = nil,
                        onDeleteAccount: (() -> Void)? = nil) -> KitoSettingsSection {
        KitoSettingsSection(title) {
            if let email {
                KitoValueRow("Email", systemImage: "envelope.fill", color: .blue, value: email, isCopyable: true)
                    .keywords("mail", "address")
            }
            if let phone {
                KitoValueRow("Phone", systemImage: "phone.fill", color: .green, value: phone, isCopyable: true)
                    .keywords("number", "mobile")
            }
            if let onChangePassword {
                KitoActionRow("Change password", systemImage: "key.fill", color: .orange,
                              showsChevron: true, action: onChangePassword)
                    .keywords("security", "passcode")
            }
            if let onSignOut {
                KitoActionRow("Sign out", systemImage: "rectangle.portrait.and.arrow.right", color: .gray,
                              confirmation: "Sign out of this device?", action: onSignOut)
                    .keywords("log out", "logout")
            }
            if let onDeleteAccount {
                KitoActionRow("Delete account", systemImage: "trash.fill", role: .destructive,
                              action: onDeleteAccount)
                    .keywords("remove", "close")
            }
        }
    }
}
