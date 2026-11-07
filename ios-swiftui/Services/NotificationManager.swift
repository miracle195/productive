//
//  NotificationManager.swift
//  Productive - Interactive Local Push Notifications & Lock Screen Quick Actions
//

import Foundation
import Combine
import UserNotifications

public final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationManager()
    
    public static let categoryIdentifier = "PRODUCTIVE_HABIT_REMINDER"
    public static let markDoneActionId = "MARK_HABIT_DONE"
    public static let snooze15ActionId = "SNOOZE_15_MIN"
    
    @Published public var isAuthorized: Bool = false
    public var onMarkHabitDone: ((UUID) -> Void)?
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        registerInteractiveCategories()
        refreshAuthorizationStatus()
    }
    
    public func refreshAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional)
            }
        }
    }
    
    public func requestPermission(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                completion?(granted)
            }
        }
    }
    
    private func registerInteractiveCategories() {
        let markDone = UNNotificationAction(
            identifier: Self.markDoneActionId,
            title: "✓ Mark Completed",
            options: [.authenticationRequired]
        )
        let snooze = UNNotificationAction(
            identifier: Self.snooze15ActionId,
            title: "Snooze 15m",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [markDone, snooze],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    public func syncHabitReminder(_ habit: Habit) {
        let identifier = "habit-reminder-\(habit.id.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        
        guard habit.reminderEnabled, !habit.isArchived else { return }
        
        if !isAuthorized {
            requestPermission { [weak self] granted in
                if granted { self?.scheduleHabitNotification(habit, identifier: identifier) }
            }
        } else {
            scheduleHabitNotification(habit, identifier: identifier)
        }
    }
    
    private func scheduleHabitNotification(_ habit: Habit, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = habit.name
        content.body = "Time for your \(habit.timeOfDay.rawValue.lowercased()) routine • \(habit.summaryGoalLabel)"
        content.sound = .default
        content.categoryIdentifier = Self.categoryIdentifier
        content.userInfo = ["habitId": habit.id.uuidString]
        
        var dateComponents = DateComponents()
        dateComponents.hour = habit.reminderHour
        dateComponents.minute = habit.reminderMinute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    public func removeHabitReminder(id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["habit-reminder-\(id.uuidString)"])
    }
    
    public func scheduleTimerCompletionAlert(habitName: String, seconds: TimeInterval) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["focus-timer-done"])
        guard seconds > 1 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Session Complete! 🎉"
        content.body = "Your focus timer for \"\(habitName)\" has finished."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let req = UNNotificationRequest(identifier: "focus-timer-done", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }
    
    public func cancelTimerAlert() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["focus-timer-done"])
    }
    
    public func configureDailyDigests(morningEnabled: Bool, eveningEnabled: Bool) {
        let ids = ["daily-morning-digest", "daily-evening-digest"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        
        if morningEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Good Morning! ☀️"
            content.body = "Review today's habits and start your morning routine."
            content.sound = .default
            var comps = DateComponents()
            comps.hour = 8
            comps.minute = 0
            let req = UNNotificationRequest(
                identifier: "daily-morning-digest",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            )
            UNUserNotificationCenter.current().add(req)
        }
        
        if eveningEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Evening Wrap-Up 🌙"
            content.body = "Check off any remaining habits to protect your streaks."
            content.sound = .default
            var comps = DateComponents()
            comps.hour = 20
            comps.minute = 30
            let req = UNNotificationRequest(
                identifier: "daily-evening-digest",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            )
            UNUserNotificationCenter.current().add(req)
        }
    }
    
    // MARK: - Foreground & Quick Action Handling
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let idStr = userInfo["habitId"] as? String, let habitId = UUID(uuidString: idStr) {
            if response.actionIdentifier == Self.markDoneActionId {
                DispatchQueue.main.async {
                    self.onMarkHabitDone?(habitId)
                }
            } else if response.actionIdentifier == Self.snooze15ActionId {
                let snoozeContent = response.notification.request.content.mutableCopy() as? UNMutableNotificationContent ?? UNMutableNotificationContent()
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15 * 60, repeats: false)
                let req = UNNotificationRequest(identifier: "snooze-\(habitId.uuidString)", content: snoozeContent, trigger: trigger)
                UNUserNotificationCenter.current().add(req)
            }
        }
        completionHandler()
    }
}
