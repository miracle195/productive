//
//  HabitAppIntents.swift
//  Productive - Native Siri, Shortcuts & iPhone 15 Pro Action Button Intents
//

import AppIntents
import SwiftUI

public struct LogNextHabitIntent: AppIntent {
    public static var title: LocalizedStringResource = "Quick Log Next Habit"
    public static var description = IntentDescription("Logs progress on your next uncompleted habit due today—ideal for the iPhone 15 Pro Action Button.")
    public static var openAppWhenRun: Bool = false
    
    public init() {}
    
    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        if let loggedName = HabitStore.shared.quickLogNextDueHabit() {
            return .result(dialog: "Logged \(loggedName) in Productive!")
        } else {
            return .result(dialog: "All due habits for today are already complete!")
        }
    }
}

public struct OpenMorningRoutineIntent: AppIntent {
    public static var title: LocalizedStringResource = "Start Guided Routine"
    public static var description = IntentDescription("Opens Productive directly into your guided daily routine player.")
    public static var openAppWhenRun: Bool = true
    
    public init() {}
    
    @MainActor
    public func perform() async throws -> some IntentResult {
        HabitStore.shared.requestedRoutineBucket = .morning
        return .result()
    }
}

public struct ProductiveShortcutsProvider: AppShortcutsProvider {
    @AppShortcutsBuilder
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogNextHabitIntent(),
            phrases: [
                "Log my next habit in \(.applicationName)",
                "Check in habit with \(.applicationName)"
            ],
            shortTitle: "Quick Log Habit",
            systemImageName: "checkmark.circle.fill"
        )
        AppShortcut(
            intent: OpenMorningRoutineIntent(),
            phrases: [
                "Start my routine in \(.applicationName)"
            ],
            shortTitle: "Start Routine",
            systemImageName: "play.circle.fill"
        )
    }
}
