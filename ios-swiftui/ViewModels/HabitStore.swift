//
//  HabitStore.swift
//  Productive State Management & Persistence
//  Updated with Dynamic Real-World Calendar Dates, Per-Date History Isolation,
//  and Clean Start (No Pre-Loaded Habits)
//

import SwiftUI

public class HabitStore: ObservableObject {
    @Published public var habits: [Habit] = []
    @Published public var selectedDate: Date = Date()
    @AppStorage("productive_week_start") public var weekStartDay: String = "Monday"
    @AppStorage("productive_app_theme") public var appTheme: String = "Dark"
    @AppStorage("productive_default_strictness") public var defaultStrictnessRaw: String = HabitStrictness.strict.rawValue
    @AppStorage("productive_haptics_enabled") public var soundHapticsEnabled: Bool = true
    
    private let storageKey = "productive_habits_store_v2"
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    public var todayKey: String {
        Self.dateFormatter.string(from: Date())
    }
    
    public init() {
        loadSavedHabits()
    }
    
    public func loadSavedHabits() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([Habit].self, from: data) {
            self.habits = saved
        } else {
            // Clean initial state: do not preload any habits, let the user create them
            self.habits = []
        }
    }
    
    public func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    public func exportJSON() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(habits) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    public func importJSON(_ jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8) else { return false }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let imported = try? decoder.decode([Habit].self, from: data) {
            self.habits = imported
            saveHabits()
            triggerHaptic(.success)
            return true
        }
        return false
    }
    
    public func resetDefaults() {
        self.habits = []
        UserDefaults.standard.removeObject(forKey: storageKey)
        weekStartDay = "Monday"
        appTheme = "Dark"
        defaultStrictnessRaw = HabitStrictness.strict.rawValue
        soundHapticsEnabled = true
        triggerHaptic(.medium)
    }
    
    public func completionPercentage(on dateKey: String) -> Int {
        guard !habits.isEmpty else { return 0 }
        let completed = habits.filter { $0.isCompleted(on: dateKey) }.count
        return Int((Double(completed) / Double(habits.count)) * 100)
    }
    
    public var completionPercentage: Int {
        return completionPercentage(on: todayKey)
    }
    
    public func toggleHabit(id: UUID, on dateKey: String? = nil) {
        let key = dateKey ?? todayKey
        if let index = habits.firstIndex(where: { $0.id == id }) {
            var rec = habits[index].history[key] ?? HabitDayRecord()
            rec.isCompleted.toggle()
            habits[index].history[key] = rec
            
            if key == todayKey {
                habits[index].isCompleted = rec.isCompleted
                if rec.isCompleted {
                    habits[index].streak += 1
                    habits[index].totalLogs += 1
                    if habits[index].streak > habits[index].bestStreak {
                        habits[index].bestStreak = habits[index].streak
                    }
                    habits[index].completedDates.append(Date())
                } else {
                    habits[index].streak = max(0, habits[index].streak - 1)
                    habits[index].totalLogs = max(0, habits[index].totalLogs - 1)
                }
            }
            
            saveHabits()
            if rec.isCompleted {
                triggerHaptic(.success)
            } else {
                triggerHaptic(.light)
            }
        }
    }
    
    public func incrementAmount(id: UUID, step: Double, on dateKey: String? = nil) {
        let key = dateKey ?? todayKey
        if let index = habits.firstIndex(where: { $0.id == id }) {
            var rec = habits[index].history[key] ?? HabitDayRecord()
            rec.amount = min(habits[index].targetAmount * 2, rec.amount + step)
            let isNowCompleted = rec.amount >= habits[index].targetAmount
            rec.isCompleted = isNowCompleted
            habits[index].history[key] = rec
            
            if key == todayKey {
                habits[index].currentAmount = rec.amount
                habits[index].isCompleted = isNowCompleted
            }
            
            saveHabits()
            if isNowCompleted {
                triggerHaptic(.success)
            } else {
                triggerHaptic(.light)
            }
        }
    }
    
    public func stepReps(id: UUID, delta: Int, on dateKey: String? = nil) {
        let key = dateKey ?? todayKey
        if let index = habits.firstIndex(where: { $0.id == id }) {
            var rec = habits[index].history[key] ?? HabitDayRecord()
            rec.reps = max(0, min(habits[index].targetReps, rec.reps + delta))
            let isNowCompleted = rec.reps >= habits[index].targetReps
            rec.isCompleted = isNowCompleted
            habits[index].history[key] = rec
            
            if key == todayKey {
                habits[index].currentReps = rec.reps
                habits[index].isCompleted = isNowCompleted
            }
            
            saveHabits()
            if isNowCompleted {
                triggerHaptic(.success)
            } else {
                triggerHaptic(.light)
            }
        }
    }
    
    public func addHabit(
        name: String,
        icon: String,
        colorHex: String,
        timeOfDay: TimeOfDay,
        trackingType: HabitTrackingType = .binary,
        targetAmount: Double = 2000,
        unit: String = "ml",
        stepAmount: Double = 250,
        targetReps: Int = 3,
        targetDurationMinutes: Int = 15,
        frequency: HabitFrequency = .daily,
        strictness: HabitStrictness = .strict,
        repeatSchedule: String = "Every day"
    ) {
        let habit = Habit(
            name: name,
            icon: icon,
            colorHex: colorHex,
            timeOfDay: timeOfDay,
            trackingType: trackingType,
            targetAmount: targetAmount,
            currentAmount: 0,
            unit: unit,
            stepAmount: stepAmount,
            targetReps: targetReps,
            currentReps: 0,
            targetDurationMinutes: targetDurationMinutes,
            frequency: frequency,
            strictness: strictness,
            repeatSchedule: repeatSchedule,
            history: [:]
        )
        habits.insert(habit, at: 0)
        saveHabits()
        triggerHaptic(.medium)
    }
    
    public func deleteHabit(id: UUID) {
        habits.removeAll { $0.id == id }
        saveHabits()
        triggerHaptic(.medium)
    }
    
    public func triggerHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        #if os(iOS)
        guard soundHapticsEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
        #endif
    }
    
    public func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        #if os(iOS)
        guard soundHapticsEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
        #endif
    }
}
