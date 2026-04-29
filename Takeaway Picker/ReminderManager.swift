//
//  ReminderManager.swift
//  Takeaway Picker
//
//  Created by Barnaby Wood on 14/01/2026.
//

import Foundation
import UserNotifications

/// Handles local notifications for Takeaway Picker,
/// such as the weekly "time to think about a takeaway" reminder.
struct ReminderManager {

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

        // Remove any existing takeaway reminders before scheduling a new one.
        center.removePendingNotificationRequests(withIdentifiers: ["TakeawayWeeklyReminder"])

        let content = UNMutableNotificationContent()
        content.title = "Time to think about tonight's dinner"
        content.body = "Give the Takeaway Picker a spin and decide what to order."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "TakeawayWeeklyReminder",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule takeaway reminder: \(error)")
            }
        }
    }

    /// Cancels the weekly takeaway reminder, if scheduled.
    func cancelWeeklyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["TakeawayWeeklyReminder"])
    }
}
