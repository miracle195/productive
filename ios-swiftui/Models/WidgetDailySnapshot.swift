//
//  WidgetDailySnapshot.swift
//  Productive - Shared Snapshot for Lock Screen & Home Screen System Widgets
//  Synchronized in real-time with HabitStore
//

import Foundation
import SwiftUI

// MARK: - Color Hex Extension (Shared across App & Widgets)

extension Color {
    public init(hex: String) {
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

public struct WidgetDailySnapshot: Codable, Equatable {
    public var dateKey: String
    public var totalDueCount: Int
    public var completedCount: Int
    public var completionPercentage: Int
    public var streakDays: Int
    public var topStreakDays: Int
    public var morningTotal: Int
    public var morningDone: Int
    public var afternoonTotal: Int
    public var afternoonDone: Int
    public var eveningTotal: Int
    public var eveningDone: Int
    public var anytimeTotal: Int
    public var anytimeDone: Int
    public var nextDueHabitName: String?
    public var nextDueHabitIcon: String?
    public var nextDueHabitColorHex: String?
    public var nextDueHabitTimeOfDay: String?
    public var lastUpdated: Date
    
    public init(
        dateKey: String = "",
        totalDueCount: Int = 0,
        completedCount: Int = 0,
        completionPercentage: Int = 0,
        streakDays: Int = 0,
        topStreakDays: Int = 0,
        morningTotal: Int = 0,
        morningDone: Int = 0,
        afternoonTotal: Int = 0,
        afternoonDone: Int = 0,
        eveningTotal: Int = 0,
        eveningDone: Int = 0,
        anytimeTotal: Int = 0,
        anytimeDone: Int = 0,
        nextDueHabitName: String? = nil,
        nextDueHabitIcon: String? = nil,
        nextDueHabitColorHex: String? = nil,
        nextDueHabitTimeOfDay: String? = nil,
        lastUpdated: Date = Date()
    ) {
        self.dateKey = dateKey
        self.totalDueCount = totalDueCount
        self.completedCount = completedCount
        self.completionPercentage = completionPercentage
        self.streakDays = streakDays
        self.topStreakDays = topStreakDays
        self.morningTotal = morningTotal
        self.morningDone = morningDone
        self.afternoonTotal = afternoonTotal
        self.afternoonDone = afternoonDone
        self.eveningTotal = eveningTotal
        self.eveningDone = eveningDone
        self.anytimeTotal = anytimeTotal
        self.anytimeDone = anytimeDone
        self.nextDueHabitName = nextDueHabitName
        self.nextDueHabitIcon = nextDueHabitIcon
        self.nextDueHabitColorHex = nextDueHabitColorHex
        self.nextDueHabitTimeOfDay = nextDueHabitTimeOfDay
        self.lastUpdated = lastUpdated
    }
    
    public static var preview: WidgetDailySnapshot {
        WidgetDailySnapshot(
            dateKey: "2026-11-09",
            totalDueCount: 3,
            completedCount: 2,
            completionPercentage: 67,
            streakDays: 4,
            topStreakDays: 12,
            morningTotal: 1,
            morningDone: 1,
            afternoonTotal: 1,
            afternoonDone: 1,
            eveningTotal: 0,
            eveningDone: 0,
            anytimeTotal: 1,
            anytimeDone: 0,
            nextDueHabitName: "Drink water (2L)",
            nextDueHabitIcon: "drop.fill",
            nextDueHabitColorHex: "#007AFF",
            nextDueHabitTimeOfDay: "Anytime",
            lastUpdated: Date()
        )
    }
}

public enum WidgetSnapshotStore {
    public static let appGroupId = "group.com.apalon.productive.tracker"
    public static let snapshotKey = "productive_widget_snapshot_v1"
    
    public static func load() -> WidgetDailySnapshot {
        // 1. Try AppGroup UserDefaults
        if let userDefaults = UserDefaults(suiteName: appGroupId),
           let data = userDefaults.data(forKey: snapshotKey),
           let snapshot = try? JSONDecoder().decode(WidgetDailySnapshot.self, from: data) {
            return snapshot
        }
        // 2. Try standard UserDefaults
        if let data = UserDefaults.standard.data(forKey: snapshotKey),
           let snapshot = try? JSONDecoder().decode(WidgetDailySnapshot.self, from: data) {
            return snapshot
        }
        // 3. Fallback preview
        return .preview
    }
    
    public static func save(_ snapshot: WidgetDailySnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        if let userDefaults = UserDefaults(suiteName: appGroupId) {
            userDefaults.set(data, forKey: snapshotKey)
        }
        UserDefaults.standard.set(data, forKey: snapshotKey)
    }
}

