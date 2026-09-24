//
//  KitoDeleteAccountFlow.swift
//  KitoSettings
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// Deleting an account in three steps: why they're leaving, what they'll lose and typing DELETE
/// to confirm, then a warm goodbye. Present it in a sheet or push it.
///
/// ```swift
/// .sheet(isPresented: $deleting) {
///     KitoDeleteAccountFlow(onDelete: { request in try await api.deleteAccount(reason: request.reason?.id) },
///                           onFinish: { signOut() }, onCancel: { deleting = false })
/// }
/// ```
public struct KitoDeleteAccountFlow: View {
    private let reasons: [KitoDeleteReason]
    private let consequences: [String]
    private let confirmation: KitoDeleteConfirmation
    private let farewellMessage: String
    private let onDelete: (KitoDeleteRequest) async throws -> Void
    private let onFinish: () -> Void
    private let onCancel: (() -> Void)?

    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step: KitoDeleteStep = .reason
    @State private var reason: KitoDeleteReason?
    @State private var feedback = ""
    @State private var typed = ""
    @State private var isDeleting = false
    @State private var errorMessage: String?

    public static let defaultConsequences = [
        "Your profile, photos and messages",
        "Your order history and saved addresses",
        "Any subscription still running, with no refund for time left",
    ]

    /// - Parameters:
    ///   - onDelete: Deletes the account. Throw to show an error and let them try again.
    ///   - onFinish: Called from the goodbye screen's Done button; sign out here.
    ///   - onCancel: "Keep my account"; nil hides it.
    public init(reasons: [KitoDeleteReason] = KitoDeleteReason.defaults,
                consequences: [String] = KitoDeleteAccountFlow.defaultConsequences,
                confirmation: KitoDeleteConfirmation = KitoDeleteConfirmation(),
                farewellMessage: String = "Asante for being with us. You're welcome back any time.",
                onDelete: @escaping (KitoDeleteRequest) async throws -> Void,
                onFinish: @escaping () -> Void, onCancel: (() -> Void)? = nil) {
        self.reasons = reasons
        self.consequences = consequences
        self.confirmation = confirmation
        self.farewellMessage = farewellMessage
        self.onDelete = onDelete
        self.onFinish = onFinish
        self.onCancel = onCancel
    }

    private var motion: Animation? { reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.86) }

    private var transition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                           removal: .move(edge: .leading).combined(with: .opacity))
    }

    public var body: some View {
        VStack(spacing: 0) {
            if step != .farewell {
                KitoDeleteProgress(step: step, tint: theme.colors.danger)
                    .padding(.horizontal, theme.spacing.xl)
                    .padding(.top, theme.spacing.lg)
            }
            ZStack {
                switch step {
                case .reason: reasonStep.transition(transition)
                case .confirm: confirmStep.transition(transition)
                case .farewell: KitoFarewell(message: farewellMessage, onFinish: onFinish).transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(theme.colors.background.ignoresSafeArea())
        .interactiveDismissDisabled(isDeleting || step == .farewell)
    }

    private func go(to next: KitoDeleteStep) {
        withAnimation(motion) { step = next }
    }

    // MARK: Reason

    private var reasonStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                KitoDeleteTitle(title: "Why are you leaving?",
                                subtitle: "Your answer helps us do better. It's optional.")
                VStack(spacing: theme.spacing.sm) {
                    ForEach(reasons) { item in
                        KitoDeleteReasonCard(reason: item, isSelected: item == reason) {
                            withAnimation(motion) { reason = item }
                        }
                    }
                }
                if reason != nil {
                    TextField("Anything we could have done better?", text: $feedback, axis: .vertical)
                        .lineLimit(3...6)
                        .font(theme.settingsFont(.body))
                        .padding(theme.spacing.md)
                        .background(RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous).fill(theme.colors.surface))
                        .overlay(RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous).strokeBorder(theme.colors.border, lineWidth: 0.5))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(theme.spacing.xl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            KitoDeleteButtons(primary: "Continue", primaryIsDestructive: false, isEnabled: true,
                              isWorking: false, secondary: onCancel == nil ? nil : "Keep my account",
                              primaryAction: { go(to: .confirm) }, secondaryAction: { onCancel?() })
        }
    }

    // MARK: Confirm

    private var confirmStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                KitoDeleteTitle(title: "This can't be undone",
                                subtitle: "Deleting your account removes, for good:")
                KitoConsequenceList(items: consequences)
                KitoDeletePhraseField(text: $typed, confirmation: confirmation)
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(theme.settingsFont(.label))
                        .foregroundStyle(theme.colors.danger)
                        .transition(.opacity)
                }
            }
            .padding(theme.spacing.xl)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            KitoDeleteButtons(primary: "Delete my account", primaryIsDestructive: true,
                              isEnabled: confirmation.isConfirmed(by: typed), isWorking: isDeleting,
                              secondary: "Back", primaryAction: delete, secondaryAction: { go(to: .reason) })
        }
    }

    private func delete() {
        guard confirmation.isConfirmed(by: typed), !isDeleting else { return }
        isDeleting = true
        errorMessage = nil
        let request = KitoDeleteRequest(reason: reason, feedback: feedback)
        Task { @MainActor in
            do {
                try await onDelete(request)
                isDeleting = false
                go(to: .farewell)
            } catch {
                isDeleting = false
                withAnimation(motion) { errorMessage = "Your account wasn't deleted. Check your connection and try again." }
            }
        }
    }
}
