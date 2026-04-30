//
//  ReminderManager.swift
//  Takeaway Picker
//
//  Created by Barnaby Wood on 14/01/2026.
//

import Foundation
import OSLog
import UserNotifications

/// Handles local notifications for Eat Something,
/// such as the weekly "time to think about dinner" reminder.
struct ReminderManager {

    private static let logger = Logger(subsystem: "com.barnabywood.EatSomething", category: "reminders")
    private static let weeklyReminderIdentifier = "EatSomethingWeeklyReminder"
    private static let legacyWeeklyReminderIdentifier = "TakeawayWeeklyReminder"

    /// Shared instance for convenience.
    static let shared = ReminderManager()

    /// Request notification permission if not already determined.
    func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                completion(true)
            case .denied:
                completion(false)
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            @unknown default:
                completion(false)
            }
        }
    }

    /// Schedules a weekly reminder on the specified weekday and time.
    /// - Parameters:
    ///   - weekday: 1 = Sunday, 2 = Monday, ... 7 = Saturday (Calendar.current)
    ///   - hour: 24-hour clock
    ///   - minute: minute
    func scheduleWeeklyReminder(weekday: Int = 6, hour: Int = 17, minute: Int = 0) {
        let center = UNUserNotificationCenter.current()

        center.removePendingNotificationRequests(withIdentifiers: [
            Self.weeklyReminderIdentifier,
            Self.legacyWeeklyReminderIdentifier
        ])

        let content = UNMutableNotificationContent()
        content.title = "Time to think about tonight's dinner"
        content.body = "Give Eat Something a spin and decide what to eat."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: Self.weeklyReminderIdentifier,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                Self.logger.error("Failed to schedule weekly reminder: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// Cancels the weekly reminder, if scheduled.
    func cancelWeeklyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            Self.weeklyReminderIdentifier,
            Self.legacyWeeklyReminderIdentifier
        ])
    }
}
