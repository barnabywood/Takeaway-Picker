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
        choices[currentIndex % choices.count]
    }

    private var previousChoice: String {
        let index = (currentIndex - 1 + choices.count) % choices.count
        return choices[index]
    }

    private var nextChoice: String {
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
            let height = proxy.size.height
            let safeTop = proxy.safeAreaInsets.top
            let safeBottom = proxy.safeAreaInsets.bottom
            let availableHeight = max(0, height - safeTop - safeBottom)

            // Size classes can still report as `.compact` when an iPhone-only app is running on iPad.
            let isPadLike = (UIDevice.current.userInterfaceIdiom == .pad) || (horizontalSizeClass == .regular)

            // We do not truly support iPad layouts, but the App Store "iPhone on iPad" frame can look cramped.
            // Detect that case and give the layout a touch more breathing room without changing iPhone behaviour.
            let isPhoneCompatOnPad = (UIDevice.current.userInterfaceIdiom == .pad) && (horizontalSizeClass == .compact)

            // Keep the cabinet framed nicely on iPad by constraining the interactive column width.
            let contentMaxWidth: CGFloat = isPadLike ? (isPhoneCompatOnPad ? 390 : 430) : .infinity

            // iPhone insets and panel width should flex with screen size to avoid awkward spacing.
            let sideInset: CGFloat = isPadLike ? 48 : min(max(width * 0.055, 16), 28)
            let actionPanelMaxWidth: CGFloat = isPadLike ? contentMaxWidth : min(360, max(280, width - (sideInset * 2)))

            // Scale the internal spacing of SlotMachineChrome.
            let spacingScale: CGFloat = {
                if isPadLike {
                    let spacingDivisor: CGFloat = isPhoneCompatOnPad ? 1050 : 800
                    let spacingFloor: CGFloat = isPhoneCompatOnPad ? 0.95 : 0.85
                    let spacingCeiling: CGFloat = isPhoneCompatOnPad ? 1.05 : 1.10
                    return min(max(availableHeight / spacingDivisor, spacingFloor), spacingCeiling)
                }

                let phoneT = min(max((availableHeight - 640) / 260, 0), 1)
                return 0.34 + (phoneT * 0.22)
            }()

            // Scale the whole mechanism a touch for short/tall iPhones.
            let mechanismScale: CGFloat = {
                if isPadLike {
                    return isPhoneCompatOnPad ? 0.92 : 0.82
                }

                if availableHeight < 700 { return 0.92 }
                if availableHeight > 900 { return 1.02 }
                return 0.98
            }()

            // Small top bias so the mechanism sits naturally in the cabinet art.
            let reelTopBias: CGFloat = {
                if isPadLike {
                    return isPhoneCompatOnPad ? 34 : 24
                }

                if availableHeight < 720 { return -14 }
                if availableHeight > 860 { return -4 }
                return -8
            }()

            // Tighten bottom padding on shorter iPhones so actions do not float too high.
            let actionBottomPadding: CGFloat = max(10, safeBottom + (isPadLike ? 14 : (availableHeight < 720 ? 8 : 14)))

            // Keep Chrome text and dial sizing balanced on narrow iPhones.
            let chromeUiScale: CGFloat = isPadLike ? 1.0 : min(max((width - (sideInset * 2)) / 390, 0.90), 1.0)

            // Used for sizing the mechanism content.
            let innerMaxWidth = min(width, contentMaxWidth.isInfinite ? width : contentMaxWidth)
            let layout = buildLayout(innerMaxWidth: innerMaxWidth, isPadLike: isPadLike)

            ZStack {
                // Geometry-driven cabinet background (scales cleanly across iPhone + iPad)
                CabinetBackground(
                    title: "Eat Something",
                    reelWidth: layout.reelWidth
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    SlotMachineChrome(dialProgress: dialProgress, spacingScale: spacingScale, uiScale: chromeUiScale) {
                        // Centre the REEL in the available space, then place the handle to the right.
                        // Reel is the visual anchor (handle does not affect centring).
                        ZStack {
                            // The main reel window (centred)
                            ZStack {
                                // Outer chrome frame
                                RoundedRectangle(cornerRadius: layout.outerCornerRadius, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color("MachineChromeLight"),
                                                Color("MachineChromeMid"),
                                                Color("MachineChromeDark")
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .black.opacity(0.35), radius: 16 * layout.scale, x: 0, y: 8 * layout.scale)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: layout.outerCornerRadius, style: .continuous)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(0.95),
                                                        Color.white.opacity(0.4),
                                                        Color.black.opacity(0.7)
                                                    ],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                ),
                                                lineWidth: layout.chromeStrokeWidth
                                            )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: layout.innerCornerRadius, style: .continuous)
                                            .stroke(Color.black.opacity(0.85), lineWidth: 1.2 * layout.scale)
                                            .padding(5 * layout.scale)
                                    )
                                    .overlay(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.55),
                                                Color.white.opacity(0.1),
                                                .clear
                                            ],
                                            startPoint: .top,
                                            endPoint: .center
                                        )
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: layout.outerCornerRadius, style: .continuous)
                                        )
                                    )

                                // Inner reel band
                                RoundedRectangle(cornerRadius: layout.innerCornerRadius, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color("ReelBandLight"),
                                                Color("ReelBandShadow")
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .padding(6 * layout.scale)

                                // Slot content
                                VStack(spacing: 0) {
                                    Text(previousChoice)
                                        .font(.system(size: layout.fontSmall, weight: .medium, design: .rounded))
                                        .foregroundColor(.black.opacity(0.45))
                                        .frame(height: effectiveRowHeight)
                                        .frame(maxWidth: .infinity)

                                    Text(currentChoice)
                                        .font(.system(size: layout.fontLarge, weight: .bold, design: .rounded))
                                        .foregroundColor(.black)
                                        .shadow(color: .white.opacity(0.7), radius: 2 * layout.scale, x: 0, y: 1 * layout.scale)
                                        .frame(height: effectiveRowHeight)
                                        .frame(maxWidth: .infinity)

                                    Text(nextChoice)
                                        .font(.system(size: layout.fontSmall, weight: .medium, design: .rounded))
                                        .foregroundColor(.black.opacity(0.45))
                                        .frame(height: effectiveRowHeight)
                                        .frame(maxWidth: .infinity)
                                }
                                .offset(y: reelOffset)
                                .mask(
                                    RoundedRectangle(cornerRadius: layout.innerCornerRadius, style: .continuous)
                                        .padding(6 * layout.scale)
                                )
                                .overlay(
                                    VStack {
                                        Rectangle()
                                            .fill(Color.black.opacity(0.15))
                                            .frame(height: 1)
                                            .padding(.horizontal, 26 * layout.scale)
                                            .offset(y: -effectiveRowHeight)

                                        Spacer()

                                        Rectangle()
                                            .fill(Color.black.opacity(0.15))
                                            .frame(height: 1)
                                            .padding(.horizontal, 26 * layout.scale)
                                            .offset(y: effectiveRowHeight)
                                    }
                                )
                            }
                            .frame(width: layout.reelWidth, height: effectiveRowHeight * 3)
                            .scaleEffect(isSpinning ? 1.02 : 1.0)
                            .onTapGesture { roll() }

                            // Slot machine handle (does NOT affect reel centring)
                            VStack {
                                Spacer()

                                ZStack {
                                    // Handle track / housing
                                    RoundedRectangle(cornerRadius: 20 * layout.scale, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color("Background").opacity(0.95),
                                                    Color("Background").opacity(0.6)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20 * layout.scale, style: .continuous)
                                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                        )
                                        .shadow(color: .black.opacity(0.3), radius: 6 * layout.scale, x: 0, y: 4 * layout.scale)
                                        .frame(width: layout.handleTrackWidth, height: layout.handleTrackHeight)

                                    // Actual handle assembly
                                    VStack(spacing: 0) {
                                        ZStack {
                                            VStack(spacing: 10 * layout.scale) {
                                                Circle()
                                                    .fill(
                                                        RadialGradient(
                                                            colors: [
                                                                Color("AccentGreen"),
                                                                Color("AccentGreen").opacity(0.4)
                                                            ],
                                                            center: .center,
                                                            startRadius: 2 * layout.scale,
                                                            endRadius: 20 * layout.scale
                                                        )
                                                    )
                                                    .overlay(
                                                        Circle()
                                                            .stroke(Color.white.opacity(0.9), lineWidth: 1.5 * layout.scale)
                                                    )
                                                    .shadow(color: Color("AccentGreen").opacity(0.7), radius: 8 * layout.scale, x: 0, y: 4 * layout.scale)
                                                    .frame(
                                                        width: layout.handleKnobBase + handlePullAmount * layout.handleKnobDelta,
                                                        height: layout.handleKnobBase + handlePullAmount * layout.handleKnobDelta
                                                    )

                                                RoundedRectangle(cornerRadius: 3 * layout.scale, style: .continuous)
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [
                                                                Color.white.opacity(0.9),
                                                                Color.white.opacity(0.7)
                                                            ],
                                                            startPoint: .top,
                                                            endPoint: .bottom
                                                        )
                                                    )
                                                    .frame(width: layout.handleStemWidth, height: layout.handleStemHeight)
                                                    .shadow(color: .black.opacity(0.25), radius: 3 * layout.scale, x: 0, y: 2 * layout.scale)
                                            }
                                            .padding(.top, 6 * layout.scale)
                                            .zIndex(2)
                                            .offset(y: handleOffsetY)
                                            .rotation3DEffect(
                                                .degrees(Double(handlePullAmount) * 14),
                                                axis: (x: 1.0, y: 0.0, z: 0.0),
                                                anchor: .bottom
                                            )
                                            .shadow(color: .black.opacity(0.4), radius: 6 * layout.scale, x: 0, y: handlePullAmount * (4 * layout.scale))
                                        }
                                        .frame(height: layout.handleClipHeight)
                                        .clipped()

                                        Circle()
                                            .fill(
                                                RadialGradient(
                                                    colors: [
                                                        Color("MachineChromeMid"),
                                                        Color("MachineChromeDark")
                                                    ],
                                                    center: .center,
                                                    startRadius: 3 * layout.scale,
                                                    endRadius: 22 * layout.scale
                                                )
                                            )
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.black.opacity(0.4), lineWidth: 0.8 * layout.scale)
                                            )
                                            .shadow(color: .black.opacity(0.5), radius: 2 * layout.scale, x: 0, y: 1 * layout.scale)
                                            .frame(width: layout.handlePivotSize, height: layout.handlePivotSize)
                                    }
                                }
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            let drag = max(0, value.translation.height)
                                            let clamped = min(drag, 50)
                                            handleOffsetY = clamped
                                            handlePullAmount = clamped / 50
                                        }
                                        .onEnded { value in
                                            let drag = value.translation.height
                                            if drag > 25 { roll() }

                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                                handleOffsetY = 0
                                                handlePullAmount = 0
                                            }
                                        }
                                )

                                Spacer()
                            }
                            .offset(x: (layout.reelWidth / 2) + layout.reelToHandleGap + (layout.handleTrackWidth / 2))
                        }
                        .task(id: layout.rowHeight) {
                            effectiveRowHeight = layout.rowHeight
                        }
                    }
                    .frame(maxWidth: contentMaxWidth)
                    .scaleEffect(mechanismScale)
                    .padding(.horizontal, sideInset)
                    .padding(.top, safeTop + reelTopBias)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom) {
                    // Keep the bottom controls visually in proportion with the mechanism.
                    // Clamp so iPhone stays punchy, and iPad iPhone-compatibility frames shrink slightly.
                    let b: CGFloat = max(0.85, min(1.0, layout.scale))
                    let actionsEnabled = hasSpunOnce && !isSpinning
                    let controlsOpacity: CGFloat = hasSpunOnce ? (isSpinning ? 0.62 : 1.0) : 0.46

                    VStack(spacing: 10 * b) {
                        if #available(iOS 16.0, *) {
                            ShareLink(item: shareMessage) {
                                Label("Check with Others", systemImage: "person.2.fill")
                                    .font(.system(size: 13.5 * b, weight: .heavy, design: .rounded))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12 * b)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color(red: 0.50, green: 0.13, blue: 0.06),
                                                        Color(red: 0.86, green: 0.29, blue: 0.10),
                                                        Color(red: 1.00, green: 0.76, blue: 0.24)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .overlay(
                                                Capsule(style: .continuous)
                                                    .stroke(Color.white.opacity(0.62), lineWidth: 1)
                                            )
                                            .overlay(
                                                Capsule(style: .continuous)
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [Color.white.opacity(0.35), .clear],
                                                            startPoint: .top,
                                                            endPoint: .center
                                                        )
                                                    )
                                            )
                                    )
                                    .foregroundColor(.white.opacity(0.98))
                            }
                            .disabled(!actionsEnabled)
                        }

                        Button {
                            showTakeawaySearch = true
                        } label: {
                            Label("Select a Local Restaurant", systemImage: "fork.knife.circle.fill")
                                .font(.system(size: 13.5 * b, weight: .heavy, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12 * b)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.70, green: 0.17, blue: 0.07),
                                                    Color(red: 0.96, green: 0.46, blue: 0.13),
                                                    Color(red: 1.00, green: 0.84, blue: 0.30)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .overlay(
                                            Capsule(style: .continuous)
                                                .stroke(Color.white.opacity(0.58), lineWidth: 1)
                                        )
                                        .overlay(
                                            Capsule(style: .continuous)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color.white.opacity(0.30), .clear],
                                                        startPoint: .top,
                                                        endPoint: .center
                                                    )
                                                )
                                        )
                                )
                                .foregroundColor(.white)
                        }
                        .disabled(!actionsEnabled)
                    }
                    .opacity(controlsOpacity)
                    .padding(.horizontal, 12 * b)
                    .padding(.vertical, 11 * b)
                    .background(
                        RoundedRectangle(cornerRadius: 30 * b, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30 * b, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.16, green: 0.04, blue: 0.03).opacity(0.85),
                                                Color(red: 0.04, green: 0.01, blue: 0.01).opacity(0.90)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 30 * b, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 1.00, green: 0.94, blue: 0.72).opacity(0.62),
                                                Color(red: 1.00, green: 0.70, blue: 0.20).opacity(0.16),
                                                Color.black.opacity(0.62)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1.3
                                    )
                            )
                            .shadow(color: .black.opacity(0.80), radius: 16 * b, x: 0, y: 8 * b)
                    )
                    .frame(maxWidth: actionPanelMaxWidth)
                    .padding(.horizontal, sideInset)
                    .padding(.bottom, actionBottomPadding)

                }
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.7))
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                                )
                        )
                        .shadow(color: .black.opacity(0.75), radius: 8, x: 0, y: 3)
                }
                .padding(.trailing, 8)
                .padding(.top, 8)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(choices: $choices, defaultChoices: Self.defaultChoices)
        }
        .sheet(isPresented: $showTakeawaySearch) {
            TakeawaySearchView(chosenType: currentChoice)
        }
        .onChange(of: choices) { newValue in
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

        withAnimation(.easeInOut(duration: duration)) {
            reelOffset = -effectiveRowHeight
            dialProgress = fractionDone
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
