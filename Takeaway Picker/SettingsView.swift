//
//  SettingsView.swift
//  Takeaway Picker
//
//  Created by Barnaby Wood on 14/01/2026.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    // Binding so MainPickerView can pass in and persist the current choices
    @Binding var choices: [String]

    // The app's default set of choices (from MainPickerView)
    let defaultChoices: [String]

    @Environment(\.dismiss) private var dismiss

    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL

    /// Optional fallback if the in-app review prompt is not shown.
    /// Replace with your real App Store app id from App Store Connect (App Information -> Apple ID).
    private let appStoreAppID = "6757822919"

    @State private var newChoiceText: String = ""

    // Reminder settings persisted via AppStorage
    @AppStorage("TakeawayReminderEnabled") private var isReminderEnabled: Bool = false
    @AppStorage("TakeawayReminderWeekday") private var reminderWeekday: Int = 6   // Friday by default
    @AppStorage("TakeawayReminderHour") private var reminderHour: Int = 17        // 17:00 by default
    @AppStorage("TakeawayReminderMinute") private var reminderMinute: Int = 0
    @AppStorage("TakeawayDidTapLeaveReview") private var didTapLeaveReview: Bool = false

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
                    // Section: Dinner options
                    Section(header: Text("Dinner options")) {
                        ForEach(choices, id: \.self) { choice in
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
                            TextField("Add a new option (e.g. Pasta)", text: $newChoiceText)
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
                            // Reset to the app defaults
                            choices = defaultChoices
                            newChoiceText = ""
                        } label: {
                            Label("Reset dinner options to defaults", systemImage: "arrow.counterclockwise")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .tint(Color(red: 1.0, green: 0.45, blue: 0.28))
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

                    // Section: Feedback and support
                    Section(header: Text("Feedback & support")) {
                        if let feedbackURL = URL(string: "mailto:app.inventory.me@gmail.com?subject=Eat%20Something") {
                            Link(destination: feedbackURL) {
                                Label("Send feedback", systemImage: "envelope")
                            }
                        }

                        if let privacyURL = URL(string: "https://raw.githubusercontent.com/barnabywood/Takeaway-Picker/main/README.md") {
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
        if !choices.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            choices.append(trimmed)
        }
        newChoiceText = ""
    }

    private func remove(choice: String) {
        choices.removeAll { $0 == choice }
    }
}

#Preview {
    SettingsView(
        choices: .constant(["Indian", "Chinese", "Pizza", "Fish and Chips", "Burgers"]),
        defaultChoices: ["Indian", "Chinese", "Pizza", "Fish and Chips", "Burgers"]
    )
}
