//
//  Habit.swift
//  Productive Models - Converted from Android Room Database
//  Updated with Multi-Mode Tracking, Units, Recurrence & Strictness
//

import SwiftUI

public enum HabitTrackingType: String, Codable, CaseIterable, Identifiable {
    case binary = "Simple Check"
    case amount = "Amount & Unit"
    case reps = "Multiple Reps"
    case timer = "Duration Timer"
    
    public var id: String { rawValue }
}

public enum HabitStrictness: String, Codable, CaseIterable, Identifiable {
    case strict = "Strict (Fatal Streak Break)"
    case flexible = "Flexible (Allow Backfill)"
    case rollover = "Rollover (Catch-up)"
    
    public var id: String { rawValue }
    
    public var badgeText: String {
        switch self {
        case .strict: return "⚡ Fatal Strict"
        case .flexible: return "🛡️ Flexible"
        case .rollover: return "🔄 Rollover"
        }
    }
}

public enum HabitFrequency: String, Codable, CaseIterable, Identifiable {
    case daily = "Every day"
    case every2Days = "Every 2 days"
    case every3Days = "Every 3 days"
    case weekdays = "Weekdays only"
    case weekends = "Weekends only"
    case threePerWeek = "3 days / week"
    
    public var id: String { rawValue }
}

public enum TimeOfDay: String, Codable, CaseIterable, Identifiable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case anytime = "Anytime"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        case .anytime: return "clock.fill"
        }
    }
}

public struct HabitCategory: Identifiable, Codable {
    public let id: Int
    public let name: String
    public let icon: String
    public let colorHex: String
}

public struct HabitDayRecord: Codable, Equatable {
    public var isCompleted: Bool
    public var amount: Double
    public var reps: Int
    
    public init(isCompleted: Bool = false, amount: Double = 0, reps: Int = 0) {
        self.isCompleted = isCompleted
        self.amount = amount
        self.reps = reps
    }
}

public struct Habit: Identifiable, Codable {
    public var id: UUID
    public var name: String
    public var icon: String
    public var colorHex: String
    public var timeOfDay: TimeOfDay
    
    // Multi-Mode Properties
    public var trackingType: HabitTrackingType
    public var targetAmount: Double
    public var currentAmount: Double
    public var unit: String
    public var stepAmount: Double
    public var targetReps: Int
    public var currentReps: Int
    public var targetDurationMinutes: Int
    
    // Recurrence & Strictness
    public var frequency: HabitFrequency
    public var strictness: HabitStrictness
    public var repeatSchedule: String
    
    public var isCompleted: Bool
    public var streak: Int
    public var bestStreak: Int
    public var totalLogs: Int
    public var goalText: String
    public var completedDates: [Date]
    
    // Per-Date History Storage
    public var history: [String: HabitDayRecord]
    
    public init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        timeOfDay: TimeOfDay,
        trackingType: HabitTrackingType = .binary,
        targetAmount: Double = 2000,
        currentAmount: Double = 0,
        unit: String = "ml",
        stepAmount: Double = 250,
        targetReps: Int = 3,
        currentReps: Int = 0,
        targetDurationMinutes: Int = 15,
        frequency: HabitFrequency = .daily,
        strictness: HabitStrictness = .strict,
        repeatSchedule: String = "Every day",
        isCompleted: Bool = false,
        streak: Int = 0,
        bestStreak: Int = 0,
        totalLogs: Int = 0,
        goalText: String = "1 time",
        completedDates: [Date] = [],
        history: [String: HabitDayRecord] = [:]
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.timeOfDay = timeOfDay
        self.trackingType = trackingType
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.unit = unit
        self.stepAmount = stepAmount
        self.targetReps = targetReps
        self.currentReps = currentReps
        self.targetDurationMinutes = targetDurationMinutes
        self.frequency = frequency
        self.strictness = strictness
        self.repeatSchedule = repeatSchedule
        self.isCompleted = isCompleted
        self.streak = streak
        self.bestStreak = bestStreak
        self.totalLogs = totalLogs
        self.goalText = goalText
        self.completedDates = completedDates
        self.history = history
    }
    
    public func isCompleted(on dateKey: String) -> Bool {
        return history[dateKey]?.isCompleted ?? false
    }
    
    public func amount(on dateKey: String) -> Double {
        return history[dateKey]?.amount ?? 0
    }
    
    public func reps(on dateKey: String) -> Int {
        return history[dateKey]?.reps ?? 0
    }
}

// Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
