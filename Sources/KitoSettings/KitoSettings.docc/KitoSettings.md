# ``KitoSettings``

Settings screens for SwiftUI with typed rows, search, ready-made screens and typed UserDefaults storage.

## Overview

KitoSettings builds a settings list in four styles — inset grouped, cards,
minimal and bold — from typed rows such as toggles, pickers, steppers, sliders,
links and actions. A search field at the top filters every row by title,
subtitle, hidden keywords and picker options, ignoring case and accents.

The package also ships a profile header and plan card, ready-made Appearance,
Notifications, Privacy, Language, About and Delete account screens, and
``KitoSetting``, a property wrapper over typed UserDefaults keys with
reset-to-defaults.

```swift
import KitoSettings

extension KitoSettingKey where Value == Bool {
    static let haptics = KitoSettingKey("haptics", default: true)
}

struct SettingsScreen: View {
    @KitoSetting(.haptics) private var haptics
    @State private var appearance = KitoAppearanceMode.system

    var body: some View {
        NavigationStack {
            KitoSettingsList(style: .insetGrouped) {
                KitoSettingsSection("General") {
                    KitoNavigationRow("Appearance", systemImage: "paintbrush.fill", color: .purple,
                                      value: appearance.title) {
                        KitoAppearanceSettings(mode: $appearance)
                    }
                    KitoToggleRow("Haptics", systemImage: "hand.tap.fill", color: .pink, isOn: $haptics)
                        .keywords("vibration")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
```

Set the style once with `kitoSettingsStyle(_:)` and every list and ready-made
screen below it follows. Every control has a VoiceOver label and value, text
and icons grow with Dynamic Type, and animations respect Reduce Motion.

## Topics

### Essentials

- ``KitoSettingsList``
- ``KitoSettingsSection``
- ``KitoSettingsStyle``
- ``KitoSettings/KitoSettings``

### Rows

- ``KitoNavigationRow``
- ``KitoToggleRow``
- ``KitoPickerRow``
- ``KitoPickerOption``
- ``KitoPickerRowStyle``
- ``KitoStepperRow``
- ``KitoSliderRow``
- ``KitoValueRow``
- ``KitoLinkRow``
- ``KitoActionRow``
- ``KitoInfoRow``
- ``KitoCustomRow``
- ``KitoSettingsRow``
- ``KitoSettingsRowConvertible``
- ``KitoSettingsIcon``
- ``KitoSettingsBadge``

### Profile and Plan

- ``KitoSettingsProfileHeader``
- ``KitoPlanCard``

### Appearance

- ``KitoAppearanceSettings``
- ``KitoAppearanceMode``
- ``KitoAppearanceModePicker``
- ``KitoAccentOption``
- ``KitoAccentGrid``
- ``KitoAppIconOption``
- ``KitoAppIconGrid``
- ``KitoAppIcon``
- ``KitoAppIconError``
- ``KitoTextSizeControl``
- ``KitoPhonePreview``

### Notifications, Privacy and Language

- ``KitoNotificationSettings``
- ``KitoNotificationTopic``
- ``KitoNotificationChannel``
- ``KitoQuietHoursEditor``
- ``KitoQuietHoursDial``
- ``KitoSettingsQuietHours``
- ``KitoTimeOfDay``
- ``KitoPrivacySettings``
- ``KitoPrivacyToggle``
- ``KitoLanguagePicker``
- ``KitoLanguage``

### About and Account

- ``KitoAboutScreen``
- ``KitoAboutLink``
- ``KitoLicense``
- ``KitoLicensesList``
- ``KitoAppVersion``
- ``KitoDeleteAccountFlow``
- ``KitoDeleteReason``
- ``KitoDeleteRequest``
- ``KitoDeleteStep``
- ``KitoDeleteConfirmation``

### Storage

- <doc:StoringSettings>
- ``KitoSetting``
- ``KitoSettingKey``
- ``KitoAnySettingKey``
- ``KitoSettingsStore``
- ``KitoSettingValue``
- ``KitoCodableSetting``

### Search and Building Blocks

- ``KitoSettingsSearch``
- ``KitoSettingsSearchable``
- ``KitoSettingsSearchField``
- ``KitoSettingsRowBuilder``
- ``KitoSettingsSectionBuilder``
- ``KitoSettingsIconTile``
- ``KitoSettingsBadgeView``
