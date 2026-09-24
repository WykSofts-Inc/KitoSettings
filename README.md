# KitoSettings

**[Documentation](https://wyksofts-inc.github.io/KitoSettings/documentation/kitosettings/)**

Settings screens for SwiftUI. A settings list in four styles with typed rows and a search field
that filters every row, a profile header and plan card, ready-made Appearance, Notifications,
Privacy, Language, About and Delete account screens, and typed UserDefaults storage with
reset-to-defaults. Part of the [Kito](https://github.com/WykSofts-Inc/KitoDevKit) ecosystem.

## A settings screen in a few lines

```swift
import KitoSettings

struct SettingsScreen: View {
    @KitoSetting(.haptics) private var haptics
    @KitoSetting(.appearance) private var appearance
    @KitoSetting(.accent) private var accent

    var body: some View {
        NavigationStack {
            KitoSettingsList(style: .insetGrouped) {
                KitoSettingsProfileHeader(name: "Wycliff N", detail: "wycliff@example.com",
                                          plan: "Kito Pro", onEdit: { editProfile() })
            } sections: {
                KitoSettingsSection("General") {
                    KitoNavigationRow("Appearance", systemImage: "paintbrush.fill", color: .purple,
                                      value: appearance.title) {
                        KitoAppearanceSettings(mode: $appearance, accent: $accent)
                    }
                    KitoToggleRow("Haptics", systemImage: "hand.tap.fill", color: .pink, isOn: $haptics)
                        .keywords("vibration")
                    KitoNavigationRow("What's new", systemImage: "sparkles", color: .orange) { WhatsNew() }
                        .badge(.new)
                }
                KitoSettingsSection.account(email: "wycliff@example.com",
                                            onSignOut: { signOut() }, onDeleteAccount: { deleting = true })
            }
            .navigationTitle("Settings")
        }
    }
}

extension KitoSettingKey where Value == Bool {
    static let haptics = KitoSettingKey("haptics", default: true)
}
extension KitoSettingKey where Value == KitoAppearanceMode {
    static let appearance = KitoSettingKey("appearance", default: .system)
}
extension KitoSettingKey where Value == String {
    static let accent = KitoSettingKey("accent", default: "blue")
}
```

The search field at the top matches titles, subtitles, hidden keywords and picker options,
ignoring case and accents ("cafe" finds "Café"). Matching rows are highlighted; sections with
no matches disappear; a section whose title matches keeps all its rows. Pass `searchPrompt: nil`
to hide it.

## Styles

```swift
KitoSettingsList(style: .bold) { … }      // .insetGrouped, .cards, .minimal, .bold
    .kitoSettingsTint(.indigo)            // or tint: on any view; defaults to theme.colors.primary
```

| Style | Looks like |
|---|---|
| `.insetGrouped` | iOS Settings: rounded groups, small coloured icon squares, inset dividers |
| `.cards` | Raised cards with soft shadows and tinted icon circles |
| `.minimal` | No boxes, tinted glyphs, hairline dividers |
| `.bold` | Large glossy gradient icon tiles, bold headings |

Set `.kitoSettingsStyle(_:)` once and every list and ready-made screen below it follows.
A `KitoSettingsSection` is also a view, so a single group works inside any scroll view.

## Rows

```swift
KitoNavigationRow("Language", systemImage: "globe", color: .indigo, value: "Kiswahili") { LanguageScreen() }
KitoToggleRow("Wi-Fi", systemImage: "wifi", color: .blue, subtitle: "Home", isOn: $wifi)
KitoPickerRow("Units", systemImage: "ruler", selection: $units,
              options: [KitoPickerOption("Metric", value: .metric), KitoPickerOption("Imperial", value: .imperial)],
              style: .menu)                                    // .inline, .sheet, .segmented
KitoStepperRow("Reminders", systemImage: "bell", value: $count, in: 0...10) { "\($0) a day" }
KitoSliderRow("Volume", systemImage: "speaker.wave.2.fill", value: $volume,
              minimumSymbol: "speaker.fill", maximumSymbol: "speaker.wave.3.fill")
KitoValueRow("Build", value: "318", isCopyable: true)
KitoLinkRow("Help centre", systemImage: "questionmark.circle.fill", url: help)
KitoActionRow("Sign out", role: .destructive, confirmation: "Sign out of this device?") { signOut() }
KitoInfoRow("Changes apply on every device.")
KitoCustomRow("Storage", keywords: ["cache", "space"]) { StorageBar() }
```

Every row takes `.keywords(…)`, `.badge(.new | .count(3) | .text("Beta") | .dot)`,
`.rowDisabled()` and `.rowID(_:)`. Sections and rows support `if`, `if let`, `switch` and `for`.

## Profile and plan

```swift
KitoSettingsProfileHeader(name: "Wycliff N", detail: "wycliff@example.com", plan: "Kito Pro",
                          avatar: Image("me"), isVerified: true, layout: .centered, onEdit: { … })
KitoPlanCard(plan: "Kito Pro", price: "KES 499 / month", renewal: "Renews 24 October",
             perks: ["Every kit", "Priority support"], actionTitle: "Upgrade") { showPaywall() }
```

## Ready-made screens

```swift
KitoAppearanceSettings(mode: $mode, accent: $accent,
                       appIcons: [KitoAppIconOption("Default", alternateIconName: nil),
                                  KitoAppIconOption("Night", alternateIconName: "AppIcon-Night",
                                                    previewImageName: "NightPreview")],
                       textScale: $textScale)
KitoNotificationSettings(topics: $topics, quietHours: $quietHours, channels: [.push, .email, .sms],
                         isSystemAllowed: authorised)
KitoPrivacySettings(toggles: $privacy, policyURL: policy,
                    onExportData: { await api.exportData() }, onDeleteAccount: { deleting = true })
KitoLanguagePicker(selection: $language)            // native names, device languages first
KitoAboutScreen(appName: "Kito", tagline: "Every kit, live.", links: links, licenses: licenses)
KitoDeleteAccountFlow(onDelete: { request in try await api.delete(reason: request.reason?.id) },
                      onFinish: { signOut() }, onCancel: { deleting = false })
```

Apply the appearance with `.preferredColorScheme(mode.colorScheme)` at your root view.

**Alternate app icons** need work in the host app: add each icon set to the asset catalog and
list it under the target's "Alternate App Icon Sets" build setting (or `CFBundleAlternateIcons`
in Info.plist). App icon sets can't be drawn as images, so add a copy of each as an image set
and pass its name as `previewImageName`. Without that, options show a gradient stand-in and
tapping explains that icons can't be changed.

`KitoDeleteAccountFlow` walks through a reason (with optional feedback), a list of what will be
lost with "type DELETE to confirm" (letters light up as they're typed, a wrong letter shakes the
field), then a goodbye. Throw from `onDelete` to show an error and let them retry.

## Storing settings

```swift
let store = KitoSettingsStore(namespace: "settings")   // UserDefaults.standard by default
store[.haptics] = false
store.reset(.haptics)
store.reset([KitoSettingKey<Bool>.haptics.erased, KitoSettingKey<String>.accent.erased])
store.resetAll()                                        // only "settings." keys

@KitoSetting(.haptics, store: store) private var haptics   // a live Binding with $haptics
```

Bool, Int, Double, String, Date, Data, URL, arrays and optionals of them work as values, and so
does any enum with a String or Int raw value once it adopts `KitoSettingValue`. Wrap anything
`Codable` in `KitoCodableSetting`.

## Logic you can use directly

```swift
KitoSettingsSearch.filter(items, query: "dark")                 // any KitoSettingsSearchable
KitoSettingsQuietHours(start: .init(hour: 22), end: .init(hour: 7)).isQuiet(at: .now)
KitoAppVersion.current.formatted(.full)                         // "Version 1.4.2 (Build 318)"
KitoDeleteConfirmation().isConfirmed(by: "DELETE")
```

## Accessibility

Every control has a VoiceOver label and value, steppers are adjustable, selection is announced,
Dynamic Type grows text and icons (rows stack at accessibility sizes) with the default Kito
typography, and every animation respects Reduce Motion.

## Right-to-left

- Rows, sections, controls and the plan card mirror automatically in Arabic/Hebrew layouts (the sheen sweeps in reading direction).
- Navigation-row chevrons and the plan card's button arrow use `chevron.forward` / `arrow.forward`, so they point the right way in RTL.
- The sign-out icon (`rectangle.portrait.and.arrow.right`) and external-link arrows are left as Apple uses them.
- The quiet-hours dial is a clock, so it stays clockwise with midnight at the top in every layout; the goodbye ring draws in from the top.

## Installation

```swift
.package(url: "https://github.com/WykSofts-Inc/KitoSettings.git", from: "0.1.0")
```

## License

MIT — see [LICENSE](LICENSE).
