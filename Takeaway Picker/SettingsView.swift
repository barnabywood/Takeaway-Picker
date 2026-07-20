//
//  SettingsView.swift
//  Takeaway Picker
//
//  Created by Barnaby Wood on 14/01/2026.
//

import SwiftUI
import StoreKit

enum MapsProvider: String, CaseIterable, Identifiable {
    case apple
    case google

    var id: String { rawValue }

    var title: String {
        switch self {
        case .apple:
            "Apple Maps"
        case .google:
            "Google Maps"
        }
    }

    var systemImage: String {
        switch self {
        case .apple:
            "map.fill"
        case .google:
            "globe"
        }
    }
}

enum PickerMode: String, CaseIterable, Identifiable {
    case dinner
    case restaurant

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dinner: "Dinner Options"
        case .restaurant: "Restaurant Options"
        }
    }

    var subtitle: String {
        switch self {
        case .dinner: "Spin through cuisines and dinner ideas."
        case .restaurant: "Spin through your favourite places to eat."
        }
    }
}

struct SettingsView: View {
    @Binding var choices: [String]
    @Binding var restaurantChoices: [String]
    @Binding var pickerModeRawValue: String

    // The app's default set of choices (from MainPickerView)
    let defaultChoices: [String]

    @Environment(\.dismiss) private var dismiss

    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL

    /// Optional fallback if the in-app review prompt is not shown.
    /// Replace with your real App Store app id from App Store Connect (App Information -> Apple ID).
    private let appStoreAppID = "6757822919"

    @State private var newChoiceText: String = ""

    private var pickerMode: PickerMode {
        PickerMode(rawValue: pickerModeRawValue) ?? .dinner
    }

    private var activeChoices: [String] {
        pickerMode == .dinner ? choices : restaurantChoices
    }

    private var optionPlaceholder: String {
        pickerMode == .dinner ? "Add a new option (e.g. Pasta)" : "Add a favourite (e.g. Franco Manca)"
    }

    // Reminder settings persisted via AppStorage
    @AppStorage("TakeawayReminderEnabled") private var isReminderEnabled: Bool = false
    @AppStorage("TakeawayReminderWeekday") private var reminderWeekday: Int = 6   // Friday by default
    @AppStorage("TakeawayReminderHour") private var reminderHour: Int = 17        // 17:00 by default
    @AppStorage("TakeawayReminderMinute") private var reminderMinute: Int = 0
    @AppStorage("TakeawayDidTapLeaveReview") private var didTapLeaveReview: Bool = false
    @AppStorage("EatSomethingMapsProvider") private var preferredMapsProvider: String = MapsProvider.apple.rawValue

    private let weekdayNames = [
        "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
    ]

    // Binding to bridge stored hour/minute into a Date for the DatePicker
    private var reminderTime: Binding<Date> {
        Binding<Date>(
            get: {
                var components = DateComponents()
                components.hour = reminderHour
                components.minute = reminderMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                reminderHour = comps.hour ?? 17
                reminderMinute = comps.minute ?? 0
            }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DinnerSpinnerBackground()

                List {
                    Section(header: Text("What do you want to spin?")) {
                        Picker("Picker mode", selection: Binding(
                            get: { pickerMode },
                            set: {
                                pickerModeRawValue = $0.rawValue
                                newChoiceText = ""
                            }
                        )) {
                            ForEach(PickerMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text(pickerMode.subtitle)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.58))
                            .padding(.vertical, 2)
                    }
                    .listRowBackground(settingsRowBackground)

                    Section(header: Text(pickerMode.title)) {
                        if activeChoices.isEmpty {
                            Label(
                                pickerMode == .dinner
                                    ? "Add a dinner option below to start spinning."
                                    : "Add a favourite restaurant below to start spinning.",
                                systemImage: "plus.circle"
                            )
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.66))
                        }

                        ForEach(activeChoices, id: \.self) { choice in
                            HStack {
                                Text(choice)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                Spacer()
                                Button {
                                    remove(choice: choice)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red.opacity(0.8))
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(.vertical, 4)
                        }

                        HStack {
                            TextField(
                                text: $newChoiceText,
                                prompt: Text(optionPlaceholder)
                                    .foregroundColor(.white.opacity(0.52))
                            ) {
                                Text(optionPlaceholder)
                            }
                                .textInputAutocapitalization(.words)
                                .disableAutocorrection(true)
                                .foregroundColor(.white)

                            Button {
                                addNewChoice()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(Color("AccentGreen"))
                                    .imageScale(.large)
                            }
                            .disabled(newChoiceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .padding(.vertical, 4)

                        Button {
                            resetActiveChoices()
                            newChoiceText = ""
                        } label: {
                            Label(
                                pickerMode == .dinner ? "Reset dinner options to defaults" : "Remove all restaurant options",
                                systemImage: pickerMode == .dinner ? "arrow.counterclockwise" : "trash"
                            )
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .tint(Color(red: 1.0, green: 0.45, blue: 0.28))
                        .disabled(pickerMode == .restaurant && restaurantChoices.isEmpty)
                    }
                    .listRowBackground(settingsRowBackground)

                    // Section: Reminders
                    Section(header: Text("Reminders")) {
                        Toggle(isOn: $isReminderEnabled) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Weekly reminder")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                Text("Choose the day and time to be reminded")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.58))
                            }
                        }
                        .tint(Color("AccentGreen"))

                        if isReminderEnabled {
                            Picker("Day", selection: $reminderWeekday) {
                                ForEach(1...7, id: \.self) { index in
                                    Text(weekdayNames[index - 1]).tag(index)
                                }
                            }

                            DatePicker(
                                "Time",
                                selection: reminderTime,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.compact)
                        }
                    }
                    .listRowBackground(settingsRowBackground)

                    // Section: Maps
                    Section(header: Text("Maps")) {
                        VStack(alignment: .leading, spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Open restaurant searches in")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                Text("Eat Something will keep using this choice until you change it.")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.58))
                            }

                            HStack(spacing: 8) {
                                ForEach(MapsProvider.allCases) { provider in
                                    mapsProviderButton(provider)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(settingsRowBackground)

                    // Section: Feedback and support
                    Section(header: Text("Feedback & support")) {
                        if let feedbackURL = URL(string: "mailto:app.inventory.me@gmail.com?subject=Eat%20Something") {
                            Link(destination: feedbackURL) {
                                Label("Send feedback", systemImage: "envelope")
                            }
                        }

                        if let privacyURL = URL(string: "https://barnabywood.github.io/Takeaway-Picker/") {
                            Link(destination: privacyURL) {
                                Label("Privacy policy", systemImage: "lock.shield")
                            }
                        }
                        Button {
                            // User explicitly opted into review flow; stop automatic prompts.
                            didTapLeaveReview = true

                            // Preferred: ask iOS to present the native in-app review prompt.
                            requestReview()

                            // Fallback: open the App Store review page (needs the real app id).
                            if let url = URL(string: "https://apps.apple.com/app/id\(appStoreAppID)?action=write-review") {
                                // Delay slightly so we do not compete with the system prompt.
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    openURL(url)
                                }
                            }
                        } label: {
                            Label("Leave a review", systemImage: "star.bubble")
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(settingsRowBackground)
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
                .foregroundColor(.white)
                .tint(Color("AccentGreen"))
            }
            .navigationTitle("Help & Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                }
            }
        }
        .onChange(of: isReminderEnabled) { _, newValue in
            if newValue {
                ReminderManager.shared.requestAuthorizationIfNeeded { granted in
                    if granted {
                        ReminderManager.shared.scheduleWeeklyReminder(
                            weekday: reminderWeekday,
                            hour: reminderHour,
                            minute: reminderMinute
                        )
                    } else {
                        // If permission denied, turn the toggle back off on the main thread
                        DispatchQueue.main.async {
                            isReminderEnabled = false
                        }
                    }
                }
            } else {
                ReminderManager.shared.cancelWeeklyReminder()
            }
        }
        .onChange(of: reminderWeekday, initial: false) { _, _ in
            rescheduleReminderIfNeeded()
        }
        .onChange(of: reminderHour, initial: false) { _, _ in
            rescheduleReminderIfNeeded()
        }
        .onChange(of: reminderMinute, initial: false) { _, _ in
            rescheduleReminderIfNeeded()
        }
    }

    private var settingsRowBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.70),
                        Color(red: 0.16, green: 0.08, blue: 0.04).opacity(0.86)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(red: 1.0, green: 0.76, blue: 0.30).opacity(0.22), lineWidth: 1)
            )
    }

    private func mapsProviderButton(_ provider: MapsProvider) -> some View {
        let isSelected = preferredMapsProvider == provider.rawValue

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                preferredMapsProvider = provider.rawValue
            }
        } label: {
            Label(provider.title, systemImage: provider.systemImage)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .padding(.horizontal, 8)
                .foregroundColor(isSelected ? .white : .white.opacity(0.68))
                .background(
                    Capsule(style: .continuous)
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: [
                                        Color("AccentGreen"),
                                        Color(red: 1.0, green: 0.62, blue: 0.12)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.10),
                                        Color.white.opacity(0.04)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(isSelected ? 0.24 : 0.14), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func rescheduleReminderIfNeeded() {
        guard isReminderEnabled else { return }
        ReminderManager.shared.scheduleWeeklyReminder(
            weekday: reminderWeekday,
            hour: reminderHour,
            minute: reminderMinute
        )
    }

    // MARK: - Actions

    private func addNewChoice() {
        let trimmed = newChoiceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // Avoid duplicates (case-insensitive)
        if !activeChoices.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            if pickerMode == .dinner {
                choices.append(trimmed)
            } else {
                restaurantChoices.append(trimmed)
            }
        }
        newChoiceText = ""
    }

    private func remove(choice: String) {
        if pickerMode == .dinner {
            choices.removeAll { $0 == choice }
        } else {
            restaurantChoices.removeAll { $0 == choice }
        }
    }

    private func resetActiveChoices() {
        if pickerMode == .dinner {
            choices = defaultChoices
        } else {
            restaurantChoices = []
        }
    }
}

#Preview {
    SettingsView(
        choices: .constant(["Indian", "Chinese", "Pizza", "Fish and Chips", "Burgers"]),
        restaurantChoices: .constant(["Franco Manca", "Dishoom"]),
        pickerModeRawValue: .constant(PickerMode.dinner.rawValue),
        defaultChoices: ["Indian", "Chinese", "Pizza", "Fish and Chips", "Burgers"]
    )
}
