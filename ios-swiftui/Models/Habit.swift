//
//  Habit.swift
//  Productive - Native SwiftUI Habit Tracker Models
//  Supports Build/Quit/Limit Polarity, Multi-Mode Tracking, Custom Schedules,
//  Rollover Quotas, Streak Freeze Shields, Sub-Checklists, Moods, Notes & Challenges
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Polarity (Good Habit vs Quit vs Daily Limit)

public enum HabitPolarity: String, Codable, CaseIterable, Identifiable {
    case build = "Build Habit"
    case quit = "Quit / Abstain"
    case limit = "Daily Limit"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .build: return "plus.circle.fill"
        case .quit: return "hand.raised.fill"
        case .limit: return "gauge.with.dots.needle.33percent"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .build: return "Reach your daily goal"
        case .quit: return "Stay clean & track abstinence"
        case .limit: return "Stay at or under a daily cap"
        }
    }
}

// MARK: - Tracking Mode

public enum HabitTrackingType: String, Codable, CaseIterable, Identifiable {
    case binary = "Simple Check"
    case amount = "Amount & Unit"
    case reps = "Multiple Reps"
    case timer = "Duration Timer"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .binary: return "checkmark.circle.fill"
        case .amount: return "drop.fill"
        case .reps: return "repeat.circle.fill"
        case .timer: return "timer"
        }
    }
}

// MARK: - Strictness & Rollover

public enum HabitStrictness: String, Codable, CaseIterable, Identifiable {
    case strict = "Strict (Fatal Streak Break)"
    case flexible = "Flexible (Allow Backfill)"
    case rollover = "Rollover (Catch-up)"
    
    public var id: String { rawValue }
    
    public var badgeText: String {
        switch self {
        case .strict: return "Strict"
        case .flexible: return "Flexible"
        case .rollover: return "Rollover"
        }
    }
    
    public var symbolName: String {
        switch self {
        case .strict: return "bolt.fill"
        case .flexible: return "shield.fill"
        case .rollover: return "arrow.triangle.2.circlepath"
        }
    }
}

// MARK: - Recurrence / Schedule

public enum HabitFrequency: String, Codable, CaseIterable, Identifiable {
    case daily = "Every day"
    case weekdays = "Weekdays only"
    case weekends = "Weekends only"
    case every2Days = "Every 2 days"
    case every3Days = "Every 3 days"
    case threePerWeek = "3 days / week"
    case customDays = "Specific weekdays"
    
    public var id: String { rawValue }
}

// MARK: - Time of Day

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
    
    public var tintColor: Color {
        switch self {
        case .morning: return .orange
        case .afternoon: return .yellow
        case .evening: return .indigo
        case .anytime: return .blue
        }
    }
}

// MARK: - Mood / Effort Reflection

public enum HabitMood: String, Codable, CaseIterable, Identifiable {
    case great = "Energized"
    case good = "Smooth"
    case neutral = "Okay"
    case tough = "Tough"
    
    public var id: String { rawValue }
    
    public var emoji: String {
        switch self {
        case .great: return "😄"
        case .good: return "🙂"
        case .neutral: return "😐"
        case .tough: return "😓"
        }
    }
}

// MARK: - Subtask Checklist Item

public struct HabitSubtask: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var title: String
    
    public init(id: UUID = UUID(), title: String) {
        self.id = id
        self.title = title
    }
}

// MARK: - Category

public struct HabitCategory: Identifiable, Codable {
    public let id: Int
    public let name: String
    public let icon: String
    public let colorHex: String
}

// MARK: - Per-Date Log Record

public struct HabitDayRecord: Codable, Equatable {
    public var isCompleted: Bool
    public var amount: Double
    public var reps: Int
    public var durationSeconds: Int
    public var isSkipped: Bool
    public var skipReason: String?
    public var usedFreezeShield: Bool
    public var slipCount: Int
    public var note: String
    public var mood: HabitMood?
    public var completedSubtaskIds: [UUID]
    public var loggedAt: Date?
    
    public init(
        isCompleted: Bool = false,
        amount: Double = 0,
        reps: Int = 0,
        durationSeconds: Int = 0,
        isSkipped: Bool = false,
        skipReason: String? = nil,
        usedFreezeShield: Bool = false,
        slipCount: Int = 0,
        note: String = "",
        mood: HabitMood? = nil,
        completedSubtaskIds: [UUID] = [],
        loggedAt: Date? = nil
    ) {
        self.isCompleted = isCompleted
        self.amount = amount
        self.reps = reps
        self.durationSeconds = durationSeconds
        self.isSkipped = isSkipped
        self.skipReason = skipReason
        self.usedFreezeShield = usedFreezeShield
        self.slipCount = slipCount
        self.note = note
        self.mood = mood
        self.completedSubtaskIds = completedSubtaskIds
        self.loggedAt = loggedAt
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.isCompleted = try c.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        self.amount = try c.decodeIfPresent(Double.self, forKey: .amount) ?? 0
        self.reps = try c.decodeIfPresent(Int.self, forKey: .reps) ?? 0
        self.durationSeconds = try c.decodeIfPresent(Int.self, forKey: .durationSeconds) ?? 0
        self.isSkipped = try c.decodeIfPresent(Bool.self, forKey: .isSkipped) ?? false
        self.skipReason = try c.decodeIfPresent(String.self, forKey: .skipReason)
        self.usedFreezeShield = try c.decodeIfPresent(Bool.self, forKey: .usedFreezeShield) ?? false
        self.slipCount = try c.decodeIfPresent(Int.self, forKey: .slipCount) ?? 0
        self.note = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
        self.mood = try c.decodeIfPresent(HabitMood.self, forKey: .mood)
        self.completedSubtaskIds = try c.decodeIfPresent([UUID].self, forKey: .completedSubtaskIds) ?? []
        self.loggedAt = try c.decodeIfPresent(Date.self, forKey: .loggedAt)
    }
}

// MARK: - Core Habit Model

public struct Habit: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var icon: String
    public var colorHex: String
    public var timeOfDay: TimeOfDay
    public var polarity: HabitPolarity
    
    // Multi-Mode Properties
    public var trackingType: HabitTrackingType
    public var targetAmount: Double
    public var currentAmount: Double
    public var unit: String
    public var stepAmount: Double
    public var targetReps: Int
    public var currentReps: Int
    public var targetDurationMinutes: Int
    
    // Recurrence, Custom Days & Strictness
    public var frequency: HabitFrequency
    public var customWeekdays: [Int] // 1 = Sun, 2 = Mon ... 7 = Sat (Calendar.current)
    public var strictness: HabitStrictness
    public var repeatSchedule: String
    public var createdAt: Date
    
    // Subtasks & Reminders
    public var subtasks: [HabitSubtask]
    public var reminderEnabled: Bool
    public var reminderHour: Int
    public var reminderMinute: Int
    
    // Organization & Lifecycle
    public var isArchived: Bool
    public var sortOrder: Int
    public var abstainedSince: Date?
    public var linkedHealthMetric: String?
    
    // Cached Summary Stats
    public var isCompleted: Bool
    public var streak: Int
    public var bestStreak: Int
    public var totalLogs: Int
    public var goalText: String
    public var completedDates: [Date]
    
    // Per-Date History Storage (YYYY-MM-DD -> HabitDayRecord)
    public var history: [String: HabitDayRecord]
    
    public init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        timeOfDay: TimeOfDay,
        polarity: HabitPolarity = .build,
        trackingType: HabitTrackingType = .binary,
        targetAmount: Double = 2000,
        currentAmount: Double = 0,
        unit: String = "ml",
        stepAmount: Double = 250,
        targetReps: Int = 3,
        currentReps: Int = 0,
        targetDurationMinutes: Int = 15,
        frequency: HabitFrequency = .daily,
        customWeekdays: [Int] = [2, 3, 4, 5, 6],
        strictness: HabitStrictness = .strict,
        repeatSchedule: String = "Every day",
        createdAt: Date = Date(),
        subtasks: [HabitSubtask] = [],
        reminderEnabled: Bool = false,
        reminderHour: Int = 9,
        reminderMinute: Int = 0,
        isArchived: Bool = false,
        sortOrder: Int = 0,
        abstainedSince: Date? = nil,
        linkedHealthMetric: String? = nil,
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
        self.polarity = polarity
        self.trackingType = trackingType
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.unit = unit
        self.stepAmount = stepAmount
        self.targetReps = targetReps
        self.currentReps = currentReps
        self.targetDurationMinutes = targetDurationMinutes
        self.frequency = frequency
        self.customWeekdays = customWeekdays
        self.strictness = strictness
        self.repeatSchedule = repeatSchedule
        self.createdAt = createdAt
        self.subtasks = subtasks
        self.reminderEnabled = reminderEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.isArchived = isArchived
        self.sortOrder = sortOrder
        self.abstainedSince = abstainedSince ?? (polarity == .quit ? createdAt : nil)
        self.linkedHealthMetric = linkedHealthMetric
        self.isCompleted = isCompleted
        self.streak = streak
        self.bestStreak = bestStreak
        self.totalLogs = totalLogs
        self.goalText = goalText
        self.completedDates = completedDates
        self.history = history
    }
    
    // Backward-compatible Codable decoding for v2 backups
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try c.decode(String.self, forKey: .name)
        self.icon = try c.decodeIfPresent(String.self, forKey: .icon) ?? "sparkles"
        self.colorHex = try c.decodeIfPresent(String.self, forKey: .colorHex) ?? "#007AFF"
        self.timeOfDay = try c.decodeIfPresent(TimeOfDay.self, forKey: .timeOfDay) ?? .morning
        self.polarity = try c.decodeIfPresent(HabitPolarity.self, forKey: .polarity) ?? .build
        self.trackingType = try c.decodeIfPresent(HabitTrackingType.self, forKey: .trackingType) ?? .binary
        self.targetAmount = try c.decodeIfPresent(Double.self, forKey: .targetAmount) ?? 2000
        self.currentAmount = try c.decodeIfPresent(Double.self, forKey: .currentAmount) ?? 0
        self.unit = try c.decodeIfPresent(String.self, forKey: .unit) ?? "ml"
        self.stepAmount = try c.decodeIfPresent(Double.self, forKey: .stepAmount) ?? 250
        self.targetReps = try c.decodeIfPresent(Int.self, forKey: .targetReps) ?? 3
        self.currentReps = try c.decodeIfPresent(Int.self, forKey: .currentReps) ?? 0
        self.targetDurationMinutes = try c.decodeIfPresent(Int.self, forKey: .targetDurationMinutes) ?? 15
        self.frequency = try c.decodeIfPresent(HabitFrequency.self, forKey: .frequency) ?? .daily
        self.customWeekdays = try c.decodeIfPresent([Int].self, forKey: .customWeekdays) ?? [2, 3, 4, 5, 6]
        self.strictness = try c.decodeIfPresent(HabitStrictness.self, forKey: .strictness) ?? .strict
        self.repeatSchedule = try c.decodeIfPresent(String.self, forKey: .repeatSchedule) ?? "Every day"
        self.createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.subtasks = try c.decodeIfPresent([HabitSubtask].self, forKey: .subtasks) ?? []
        self.reminderEnabled = try c.decodeIfPresent(Bool.self, forKey: .reminderEnabled) ?? false
        self.reminderHour = try c.decodeIfPresent(Int.self, forKey: .reminderHour) ?? 9
        self.reminderMinute = try c.decodeIfPresent(Int.self, forKey: .reminderMinute) ?? 0
        self.isArchived = try c.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        self.sortOrder = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        self.abstainedSince = try c.decodeIfPresent(Date.self, forKey: .abstainedSince)
        self.linkedHealthMetric = try c.decodeIfPresent(String.self, forKey: .linkedHealthMetric)
        self.isCompleted = try c.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        self.streak = try c.decodeIfPresent(Int.self, forKey: .streak) ?? 0
        self.bestStreak = try c.decodeIfPresent(Int.self, forKey: .bestStreak) ?? 0
        self.totalLogs = try c.decodeIfPresent(Int.self, forKey: .totalLogs) ?? 0
        self.goalText = try c.decodeIfPresent(String.self, forKey: .goalText) ?? "1 time"
        self.completedDates = try c.decodeIfPresent([Date].self, forKey: .completedDates) ?? []
        self.history = try c.decodeIfPresent([String: HabitDayRecord].self, forKey: .history) ?? [:]
    }
    
    // MARK: - Per-Date Helpers
    
    public func isCompleted(on dateKey: String) -> Bool {
        history[dateKey]?.isCompleted ?? false
    }
    
    public func isSkipped(on dateKey: String) -> Bool {
        let rec = history[dateKey]
        return (rec?.isSkipped ?? false) || (rec?.usedFreezeShield ?? false)
    }
    
    public func amount(on dateKey: String) -> Double {
        history[dateKey]?.amount ?? 0
    }
    
    public func reps(on dateKey: String) -> Int {
        history[dateKey]?.reps ?? 0
    }
    
    public func durationSeconds(on dateKey: String) -> Int {
        history[dateKey]?.durationSeconds ?? 0
    }
    
    public func note(on dateKey: String) -> String {
        history[dateKey]?.note ?? ""
    }
    
    public func mood(on dateKey: String) -> HabitMood? {
        history[dateKey]?.mood
    }
    
    public func isDue(on date: Date, calendar: Calendar = .current) -> Bool {
        if isArchived { return false }
        let weekday = calendar.component(.weekday, from: date) // 1 = Sun ... 7 = Sat
        switch frequency {
        case .daily:
            return true
        case .weekdays:
            return (2...6).contains(weekday)
        case .weekends:
            return weekday == 1 || weekday == 7
        case .threePerWeek:
            return [2, 4, 6].contains(weekday) // Mon, Wed, Fri
        case .customDays:
            return customWeekdays.isEmpty ? true : customWeekdays.contains(weekday)
        case .every2Days:
            let anchor = calendar.startOfDay(for: createdAt)
            let target = calendar.startOfDay(for: date)
            let diff = abs(calendar.dateComponents([.day], from: anchor, to: target).day ?? 0)
            return diff % 2 == 0
        case .every3Days:
            let anchor = calendar.startOfDay(for: createdAt)
            let target = calendar.startOfDay(for: date)
            let diff = abs(calendar.dateComponents([.day], from: anchor, to: target).day ?? 0)
            return diff % 3 == 0
        }
    }
    
    public var summaryGoalLabel: String {
        switch polarity {
        case .quit:
            return "Quit • Stay Clean"
        case .limit:
            return "Max \(Int(targetAmount)) \(unit)"
        case .build:
            switch trackingType {
            case .binary: return "Daily check-in"
            case .amount: return "\(Int(targetAmount)) \(unit)"
            case .reps: return "\(targetReps)x reps"
            case .timer: return "\(targetDurationMinutes) min session"
            }
        }
    }
}

// MARK: - Challenges & Milestone Achievements

public struct HabitChallenge: Identifiable, Codable, Equatable {
    public var id: String
    public var title: String
    public var subtitle: String
    public var durationDays: Int
    public var icon: String
    public var colorHex: String
    public var isJoined: Bool
    public var joinedDateKey: String?
    public var templateHabitName: String
    public var templateTrackingType: HabitTrackingType
    public var templateTargetAmount: Double
    public var templateUnit: String
    public var templateDurationMinutes: Int
    public var templatePolarity: HabitPolarity
    public var linkedHabitId: UUID?
    
    public init(
        id: String,
        title: String,
        subtitle: String,
        durationDays: Int,
        icon: String,
        colorHex: String,
        isJoined: Bool = false,
        joinedDateKey: String? = nil,
        templateHabitName: String,
        templateTrackingType: HabitTrackingType = .binary,
        templateTargetAmount: Double = 2000,
        templateUnit: String = "ml",
        templateDurationMinutes: Int = 15,
        templatePolarity: HabitPolarity = .build,
        linkedHabitId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.durationDays = durationDays
        self.icon = icon
        self.colorHex = colorHex
        self.isJoined = isJoined
        self.joinedDateKey = joinedDateKey
        self.templateHabitName = templateHabitName
        self.templateTrackingType = templateTrackingType
        self.templateTargetAmount = templateTargetAmount
        self.templateUnit = templateUnit
        self.templateDurationMinutes = templateDurationMinutes
        self.templatePolarity = templatePolarity
        self.linkedHabitId = linkedHabitId
    }
}

public struct AchievementBadge: Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let icon: String
    public let colorHex: String
    public let isUnlocked: Bool
}

// MARK: - Native Export Document (Files / ShareLink)

public struct ProductiveBackupPayload: Codable {
    public let app: String
    public let version: String
    public let exportedAt: Date
    public let weekStartDay: String
    public let appTheme: String
    public let defaultStrictness: String
    public let streakFreezeShields: Int
    public let habits: [Habit]
    public let challenges: [HabitChallenge]
}

public struct JSONBackupDocument: FileDocument {
    public static var readableContentTypes: [UTType] { [.json] }
    public var text: String
    
    public init(text: String = "") {
        self.text = text
    }
    
    public init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let str = String(data: data, encoding: .utf8) {
            self.text = str
        } else {
            self.text = ""
        }
    }
    
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Color Hex Extension

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
            (a, r, g, b) = (255, 0, 122, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
