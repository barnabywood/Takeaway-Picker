//
//  MainPickerView.swift
//  Takeaway Picker
//
//  Created by Barnaby Wood on 14/01/2026.
//

import SwiftUI
import UIKit
import CryptoKit
import StoreKit

struct MainPickerView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private static let choicesStorageKey = "TakeawayChoices"
    private static let userEditedStorageKey = "TakeawayChoicesUserEdited"
    private static let defaultsHashStorageKey = "TakeawayChoicesDefaultsHash"

    /// Edit this list in code when you want to change the app's built-in defaults.
    /// Settings will start from this list on first launch (or after defaults change).
    static let defaultChoices: [String] = [
        "Indian",
        "Chinese",
        "Pizza",
        "Fish and Chips",
        "Burgers",
        "Chicken",
        "Thai",
        "Japanese"
    ]

    @State private var isSpinning = false
    @State private var reelOffset: CGFloat = 0
    @State private var currentIndex: Int = 0
    @State private var totalSteps: Int = 0
    @State private var handleOffsetY: CGFloat = 0
    @State private var handlePullAmount: CGFloat = 0
    @State private var hasSpunOnce: Bool = false
    @State private var dialProgress: Double = 0.0
    @State private var wheelRotation: Double = 0.0
    @State private var showSettings: Bool = false
    @State private var showTakeawaySearch: Bool = false

    // MARK: - Review prompt (internal cadence)

    @AppStorage("TakeawaySpinCount") private var spinCount: Int = 0
    @AppStorage("TakeawayReviewNextPromptSpin") private var nextReviewPromptSpin: Int = 5
    @AppStorage("TakeawayDidTapLeaveReview") private var didTapLeaveReview: Bool = false

    private let baseRowHeight: CGFloat = 56
    @State private var effectiveRowHeight: CGFloat = 56

    // Choices are state-backed so SettingsView can edit them
    @State private var choices: [String]

    init() {
        self.init(choices: Self.defaultChoices)
    }

    init(choices: [String]) {
        let defaults = choices
        let defaultsHash = Self.hashForChoices(defaults)

        let userDefaults = UserDefaults.standard
        let userEdited = userDefaults.bool(forKey: Self.userEditedStorageKey)
        let savedDefaultsHash = userDefaults.string(forKey: Self.defaultsHashStorageKey)
        let savedChoices = userDefaults.stringArray(forKey: Self.choicesStorageKey) ?? []

        // First run: nothing saved yet.
        if savedDefaultsHash == nil || savedChoices.isEmpty {
            _choices = State(initialValue: defaults)
            userDefaults.set(defaults, forKey: Self.choicesStorageKey)
            userDefaults.set(defaultsHash, forKey: Self.defaultsHashStorageKey)
            userDefaults.set(false, forKey: Self.userEditedStorageKey)
            return
        }

        // If the app's default list changes (you edited defaults in code), refresh the stored defaults hash.
        // If the user has NOT customised their list, also replace the stored list with the new defaults.
        if savedDefaultsHash != defaultsHash {
            if userEdited {
                // User customised: keep their list.
                _choices = State(initialValue: savedChoices)
            } else {
                // Not customised: move to the new defaults.
                _choices = State(initialValue: defaults)
                userDefaults.set(defaults, forKey: Self.choicesStorageKey)
            }

            userDefaults.set(defaultsHash, forKey: Self.defaultsHashStorageKey)
            return
        }

        // Defaults unchanged: load saved list.
        _choices = State(initialValue: savedChoices)
    }

    private var currentChoice: String {
        guard !choices.isEmpty else { return "Dinner" }
        return choices[currentIndex % choices.count]
    }

    private var previousChoice: String {
        guard !choices.isEmpty else { return "Dinner" }
        let index = (currentIndex - 1 + choices.count) % choices.count
        return choices[index]
    }

    private var nextChoice: String {
        guard !choices.isEmpty else { return "Dinner" }
        let index = (currentIndex + 1) % choices.count
        return choices[index]
    }

    private var shareMessage: String {
        "Tonight's dinner suggestion: \(currentChoice)\nReply with 👍 or 👎 and what you'd like to eat."
    }

    // MARK: - Layout model (single source of truth)

    private struct MechanismLayout {
        let reelWidth: CGFloat
        let scale: CGFloat
        let rowHeight: CGFloat

        let fontSmall: CGFloat
        let fontLarge: CGFloat

        let handleTrackWidth: CGFloat
        let handleTrackHeight: CGFloat
        let handleClipHeight: CGFloat

        let handleKnobBase: CGFloat
        let handleKnobDelta: CGFloat
        let handleStemWidth: CGFloat
        let handleStemHeight: CGFloat
        let handlePivotSize: CGFloat

        let reelToHandleGap: CGFloat

        let outerCornerRadius: CGFloat
        let innerCornerRadius: CGFloat
        let chromeStrokeWidth: CGFloat
    }

    private func buildLayout(innerMaxWidth: CGFloat, isPadLike: Bool) -> MechanismLayout {
        // iPhone stays punchy, iPhone-compat on iPad shrinks a touch more.
        let reelMax: CGFloat = isPadLike ? 190 : 220
        let reelFrac: CGFloat = isPadLike ? 0.39 : 0.50
        let reelMin: CGFloat = isPadLike ? 150 : 170

        let reelWidth: CGFloat = max(reelMin, min(reelMax, innerMaxWidth * reelFrac))
        let scale: CGFloat = reelWidth / 220

        let rowHeight: CGFloat = max(42, baseRowHeight * scale)

        let fontSmall: CGFloat = max(15, 20 * scale)
        let fontLarge: CGFloat = max(21, 28 * scale)

        let handleTrackWidth: CGFloat = 34 * scale
        let handleTrackHeight: CGFloat = 160 * scale
        let handleClipHeight: CGFloat = 120 * scale

        let handleKnobBase: CGFloat = 30 * scale
        let handleKnobDelta: CGFloat = 10 * scale
        let handleStemWidth: CGFloat = 6 * scale
        let handleStemHeight: CGFloat = 60 * scale
        let handlePivotSize: CGFloat = 24 * scale

        let reelToHandleGap: CGFloat = 20 * scale

        let outerCornerRadius: CGFloat = max(26, 36 * scale)
        let innerCornerRadius: CGFloat = max(22, 30 * scale)
        let chromeStrokeWidth: CGFloat = max(2, 3 * scale)

        return MechanismLayout(
            reelWidth: reelWidth,
            scale: scale,
            rowHeight: rowHeight,
            fontSmall: fontSmall,
            fontLarge: fontLarge,
            handleTrackWidth: handleTrackWidth,
            handleTrackHeight: handleTrackHeight,
            handleClipHeight: handleClipHeight,
            handleKnobBase: handleKnobBase,
            handleKnobDelta: handleKnobDelta,
            handleStemWidth: handleStemWidth,
            handleStemHeight: handleStemHeight,
            handlePivotSize: handlePivotSize,
            reelToHandleGap: reelToHandleGap,
            outerCornerRadius: outerCornerRadius,
            innerCornerRadius: innerCornerRadius,
            chromeStrokeWidth: chromeStrokeWidth
        )
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let safeBottom = proxy.safeAreaInsets.bottom
            let sideInset: CGFloat = min(max(width * 0.055, 16), 28)
            let actionPanelMaxWidth: CGFloat = min(370, max(290, width - (sideInset * 2)))
            let actionBottomPadding: CGFloat = max(12, safeBottom + 16)
            let actionsEnabled = hasSpunOnce && !isSpinning
            let controlsOpacity: CGFloat = hasSpunOnce ? (isSpinning ? 0.62 : 1.0) : 0.48

            ZStack {
                DinnerSpinnerBackground()

                VStack(spacing: 0) {
                    Text("Eat Something")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.58)
                        .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, sideInset)
                    .padding(.top, proxy.safeAreaInsets.top + 14)

                    DinnerSpinnerView(
                        choices: choices,
                        currentIndex: currentIndex,
                        rotation: wheelRotation,
                        isSpinning: isSpinning,
                        hasSpunOnce: hasSpunOnce,
                        onSpin: roll
                    )
                    .padding(.horizontal, sideInset)

                    Spacer(minLength: 0)
                }
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 10) {
                        if #available(iOS 16.0, *) {
                            ShareLink(item: shareMessage) {
                                dinnerActionLabel(
                                    title: "Check with Others",
                                    systemImage: "person.2.fill"
                                )
                            }
                            .disabled(!actionsEnabled)
                        }

                        Button {
                            showTakeawaySearch = true
                        } label: {
                            dinnerActionLabel(
                                title: "Select a Local Restaurant",
                                systemImage: "fork.knife.circle.fill"
                            )
                        }
                        .disabled(!actionsEnabled)
                    }
                    .opacity(controlsOpacity)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .fill(Color.black.opacity(0.48))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.62), radius: 20, x: 0, y: 10)
                    )
                    .frame(maxWidth: actionPanelMaxWidth)
                    .padding(.horizontal, sideInset)
                    .padding(.bottom, actionBottomPadding)
                }

                VStack {
                    HStack {
                        Spacer()

                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.10))
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    .padding(.trailing, sideInset)
                    .padding(.top, max(8, proxy.safeAreaInsets.top * 0.38))

                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(choices: $choices, defaultChoices: Self.defaultChoices)
        }
        .sheet(isPresented: $showTakeawaySearch) {
            TakeawaySearchView(chosenType: currentChoice)
        }
        .onChange(of: choices) { _, newValue in
            let userDefaults = UserDefaults.standard
            userDefaults.set(true, forKey: Self.userEditedStorageKey)
            userDefaults.set(newValue, forKey: Self.choicesStorageKey)

            // If the list changes, make sure the reel index is valid.
            if currentIndex >= max(newValue.count, 1) {
                currentIndex = 0
                reelOffset = 0
            }
        }
    }

    private func dinnerActionLabel(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 15, weight: .heavy, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .foregroundColor(.white)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.16),
                                Color("AccentGreen").opacity(0.34),
                                Color(red: 1.0, green: 0.58, blue: 0.10).opacity(0.46)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.26), lineWidth: 1)
                    )
            )
    }

    private static func hashForChoices(_ choices: [String]) -> String {
        let normalised = choices
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .joined(separator: "|")

        let digest = SHA256.hash(data: Data(normalised.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Spin logic

    private func roll() {
        guard !isSpinning, !choices.isEmpty else { return }
        isSpinning = true
        trackSpinAndMaybeRequestReview()
        Haptics.lightTap()
        dialProgress = 0.0

        let count = choices.count
        let steps: Int

        if count <= 1 {
            steps = 20
        } else {
            let offset = Int.random(in: 1...(count - 1))
            let fullRotations = Int.random(in: 3...5)
            steps = fullRotations * count + offset
        }

        totalSteps = steps
        spinStep(remaining: steps)
    }

    // MARK: - Review prompt helpers

    private func trackSpinAndMaybeRequestReview() {
        // Count a use when the user initiates a spin.
        spinCount += 1

        // If the user explicitly tapped "Leave a review", stop automatic reminders.
        guard !didTapLeaveReview else { return }

        // Prompt every 5 spins until the user opts in via the Leave a review button.
        if spinCount >= max(5, nextReviewPromptSpin) {
            requestAppStoreReview()
            nextReviewPromptSpin = spinCount + 5
        }
    }

    private func requestAppStoreReview() {
        // Works for iOS and iPadOS. Must be called on the main thread.
        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive })
            else {
                return
            }

            if #available(iOS 18.0, *) {
                AppStore.requestReview(in: scene)
            } else {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }

    private func spinStep(remaining: Int) {
        guard remaining > 0 else {
            Haptics.success()
            isSpinning = false
            hasSpunOnce = true
            withAnimation(.easeOut(duration: 0.2)) {
                dialProgress = 1.0
            }
            return
        }

        if remaining > 5 {
            Haptics.tick()
        }

        let progress = Double(remaining) / Double(max(totalSteps, 1))
        let fractionDone = 1.0 - progress
        let duration = 0.04 + (1.0 - progress) * 0.05
        let degreesPerStep = 360.0 / Double(max(choices.count, 1))

        withAnimation(.easeInOut(duration: duration)) {
            reelOffset = -effectiveRowHeight
            dialProgress = fractionDone
            wheelRotation += degreesPerStep
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            currentIndex = (currentIndex + 1) % choices.count
            reelOffset = 0
            spinStep(remaining: remaining - 1)
        }
    }
}

// Simple haptics helper for the picker
private enum Haptics {
    static func lightTap() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Subtle "tick" used while the spinner steps through choices.
    static func tick() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

#Preview {
    MainPickerView(
        choices: [
            "Indian",
            "Chinese",
            "Pizza",
            "Fish and Chips",
            "Burger",
            "Chicken",
            "Thai",
            "Japanese"
        ]
    )
}
