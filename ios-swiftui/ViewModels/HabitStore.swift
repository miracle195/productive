//
//  HabitStore.swift
//  Productive State Management & Persistence
//  Updated with Multi-Mode Amount, Reps, Recurrence & Strictness
//

import SwiftUI

public class HabitStore: ObservableObject {
    @Published public var habits: [Habit] = []
    @Published public var selectedDate: Date = Date()
    @AppStorage("productive_week_start") public var weekStartDay: String = "Monday"
    @AppStorage("productive_app_theme") public var appTheme: String = "Dark"
    @AppStorage("productive_default_strictness") public var defaultStrictnessRaw: String = HabitStrictness.strict.rawValue
    @AppStorage("productive_haptics_enabled") public var soundHapticsEnabled: Bool = true
    
    public init() {
        loadDefaultHabits()
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
            triggerHaptic(.success)
            return true
        }
        return false
    }
    
    public func resetDefaults() {
        loadDefaultHabits()
        weekStartDay = "Monday"
        appTheme = "Dark"
        defaultStrictnessRaw = HabitStrictness.strict.rawValue
        soundHapticsEnabled = true
        triggerHaptic(.medium)
    }
    
    public var completionPercentage: Int {
        guard !habits.isEmpty else { return 0 }
        let completed = habits.filter { $0.isCompleted }.count
        return Int((Double(completed) / Double(habits.count)) * 100)
    }
    
    public func toggleHabit(id: UUID) {
        if let index = habits.firstIndex(where: { $0.id == id }) {
            habits[index].isCompleted.toggle()
            if habits[index].isCompleted {
                habits[index].streak += 1
                habits[index].totalLogs += 1
                if habits[index].streak > habits[index].bestStreak {
                    habits[index].bestStreak = habits[index].streak
                }
                habits[index].completedDates.append(Date())
                triggerHaptic(.success)
            } else {
                habits[index].streak = max(0, habits[index].streak - 1)
                habits[index].totalLogs = max(0, habits[index].totalLogs - 1)
                triggerHaptic(.light)
            }
        }
    }
    
    public func incrementAmount(id: UUID, step: Double) {
        if let index = habits.firstIndex(where: { $0.id == id }) {
            let wasCompleted = habits[index].isCompleted
            habits[index].currentAmount = min(habits[index].targetAmount * 2, habits[index].currentAmount + step)
            let isNowCompleted = habits[index].currentAmount >= habits[index].targetAmount
            habits[index].isCompleted = isNowCompleted
            
            if isNowCompleted && !wasCompleted {
                habits[index].streak += 1
                habits[index].totalLogs += 1
                if habits[index].streak > habits[index].bestStreak {
                    habits[index].bestStreak = habits[index].streak
                }
                habits[index].completedDates.append(Date())
                triggerHaptic(.success)
            } else {
                triggerHaptic(.light)
            }
        }
    }
    
    public func stepReps(id: UUID, delta: Int) {
        if let index = habits.firstIndex(where: { $0.id == id }) {
            let wasCompleted = habits[index].isCompleted
            habits[index].currentReps = max(0, min(habits[index].targetReps, habits[index].currentReps + delta))
            let isNowCompleted = habits[index].currentReps >= habits[index].targetReps
            habits[index].isCompleted = isNowCompleted
            
            if isNowCompleted && !wasCompleted {
                habits[index].streak += 1
                habits[index].totalLogs += 1
                if habits[index].streak > habits[index].bestStreak {
                    habits[index].bestStreak = habits[index].streak
                }
                habits[index].completedDates.append(Date())
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
            frequency: frequency,
            strictness: strictness,
            repeatSchedule: repeatSchedule
        )
        habits.insert(habit, at: 0)
        triggerHaptic(.medium)
    }
    
    public func triggerHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
        #endif
    }
    
    public func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
        #endif
    }
    
    private func loadDefaultHabits() {
        self.habits = [
            Habit(
                name: "Drink water (2L)",
                icon: "drop.fill",
                colorHex: "#1B8FFF",
                timeOfDay: .morning,
                trackingType: .amount,
                targetAmount: 2000,
                currentAmount: 1500,
                unit: "ml",
                stepAmount: 250,
                frequency: .daily,
                strictness: .strict,
                repeatSchedule: "Every day",
                isCompleted: false,
                streak: 14,
                bestStreak: 28,
                totalLogs: 92,
                goalText: "2000 ml"
            ),
            Habit(
                name: "Morning stretch & yoga",
                icon: "figure.mind.and.body",
                colorHex: "#0FC580",
                timeOfDay: .morning,
                trackingType: .binary,
                frequency: .daily,
                strictness: .flexible,
                repeatSchedule: "Every day",
                isCompleted: true,
                streak: 8,
                bestStreak: 19,
                totalLogs: 45,
                goalText: "15 mins"
            ),
            Habit(
                name: "Take daily vitamins",
                icon: "pill.fill",
                colorHex: "#F8BD32",
                timeOfDay: .morning,
                trackingType: .reps,
                targetReps: 2,
                currentReps: 1,
                frequency: .daily,
                strictness: .strict,
                repeatSchedule: "2x a day",
                isCompleted: false,
                streak: 30,
                bestStreak: 45,
                totalLogs: 140,
                goalText: "2 doses"
            ),
            Habit(
                name: "Go for a brisk walk",
                icon: "figure.walk",
                colorHex: "#0FC580",
                timeOfDay: .afternoon,
                trackingType: .amount,
                targetAmount: 30,
                currentAmount: 15,
                unit: "mins",
                stepAmount: 10,
                frequency: .every2Days,
                strictness: .flexible,
                repeatSchedule: "Every 2 days",
                isCompleted: false,
                streak: 6,
                bestStreak: 14,
                totalLogs: 38,
                goalText: "30 mins"
            ),
            Habit(
                name: "Eat fruits & veggies",
                icon: "leaf.fill",
                colorHex: "#0FC580",
                timeOfDay: .afternoon,
                trackingType: .reps,
                targetReps: 3,
                currentReps: 3,
                frequency: .daily,
                strictness: .rollover,
                repeatSchedule: "3x a day",
                isCompleted: true,
                streak: 12,
                bestStreak: 21,
                totalLogs: 64,
                goalText: "3 servings"
            ),
            Habit(
                name: "Read a book (20m)",
                icon: "book.fill",
                colorHex: "#FF7450",
                timeOfDay: .evening,
                trackingType: .amount,
                targetAmount: 20,
                currentAmount: 0,
                unit: "pages",
                stepAmount: 5,
                frequency: .daily,
                strictness: .strict,
                repeatSchedule: "Every day",
                isCompleted: false,
                streak: 21,
                bestStreak: 35,
                totalLogs: 110,
                goalText: "20 pages"
            ),
            Habit(
                name: "Meditate & relax",
                icon: "sparkles",
                colorHex: "#FF7450",
                timeOfDay: .evening,
                trackingType: .binary,
                frequency: .weekdays,
                strictness: .flexible,
                repeatSchedule: "Weekdays (Mon-Fri)",
                isCompleted: false,
                streak: 5,
                bestStreak: 12,
                totalLogs: 29,
                goalText: "10 mins"
            )
        ]
    }
}
