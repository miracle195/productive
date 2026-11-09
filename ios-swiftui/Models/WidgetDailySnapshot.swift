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
    
    public static var empty: WidgetDailySnapshot {
        WidgetDailySnapshot(
            dateKey: "",
            totalDueCount: 0,
            completedCount: 0,
            completionPercentage: 0,
            streakDays: 0,
            topStreakDays: 0,
            morningTotal: 0,
            morningDone: 0,
            afternoonTotal: 0,
            afternoonDone: 0,
            eveningTotal: 0,
            eveningDone: 0,
            anytimeTotal: 0,
            anytimeDone: 0,
            nextDueHabitName: nil,
            nextDueHabitIcon: nil,
            nextDueHabitColorHex: nil,
            nextDueHabitTimeOfDay: nil,
            lastUpdated: Date()
        )
    }
    
    public static var fallback: WidgetDailySnapshot {
        WidgetDailySnapshot(
            dateKey: "2026-11-09",
            totalDueCount: 4,
            completedCount: 0,
            completionPercentage: 0,
            streakDays: 0,
            topStreakDays: 0,
            morningTotal: 2,
            morningDone: 0,
            afternoonTotal: 0,
            afternoonDone: 0,
            eveningTotal: 2,
            eveningDone: 0,
            anytimeTotal: 0,
            anytimeDone: 0,
            nextDueHabitName: "Brush & floss teeth",
            nextDueHabitIcon: "sparkles",
            nextDueHabitColorHex: "#FF9500",
            nextDueHabitTimeOfDay: "Morning",
            lastUpdated: Date()
        )
    }
    
    public static var preview: WidgetDailySnapshot {
        WidgetDailySnapshot(
            dateKey: "2026-11-09",
            totalDueCount: 4,
            completedCount: 1,
            completionPercentage: 25,
            streakDays: 4,
            topStreakDays: 12,
            morningTotal: 2,
            morningDone: 1,
            afternoonTotal: 0,
            afternoonDone: 0,
            eveningTotal: 2,
            eveningDone: 0,
            anytimeTotal: 0,
            anytimeDone: 0,
            nextDueHabitName: "Brush & floss teeth",
            nextDueHabitIcon: "sparkles",
            nextDueHabitColorHex: "#FF9500",
            nextDueHabitTimeOfDay: "Morning",
            lastUpdated: Date()
        )
    }
}

public enum WidgetSnapshotStore {
    public static let primaryAppGroupId = "group.com.apalon.productive.tracker"
    public static let snapshotKey = "productive_widget_snapshot_v1"
    public static let snapshotFileName = "productive_widget_snapshot_v1.json"
    
    /// Parses provisioned AppGroup identifiers directly from embedded.mobileprovision if signed by AltStore/Sideloadly
    private static func appGroupsFromProvisioningProfile() -> [String] {
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url),
              let string = String(data: data, encoding: .isoLatin1) else {
            return []
        }
        var groups: [String] = []
        if let range = string.range(of: "<key>com.apple.security.application-groups</key>") {
            let remainder = string[range.upperBound...]
            if let arrayStart = remainder.range(of: "<array>"),
               let arrayEnd = remainder.range(of: "</array>") {
                let arrayContent = String(remainder[arrayStart.upperBound..<arrayEnd.lowerBound])
                let pattern = "<string>([^<]+)</string>"
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let matches = regex.matches(in: arrayContent, range: NSRange(location: 0, length: arrayContent.utf16.count))
                    for match in matches {
                        if let stringRange = Range(match.range(at: 1), in: arrayContent) {
                            groups.append(String(arrayContent[stringRange]))
                        }
                    }
                }
            }
        }
        return groups
    }
    
    /// Candidate AppGroup IDs (primary identifier + embedded provisioning profile groups + dynamic match based on app bundle ID)
    private static var candidateGroupIds: [String] {
        var ids: [String] = []
        // 1. Groups extracted dynamically from provisioning profile
        for g in appGroupsFromProvisioningProfile() {
            if !ids.contains(g) { ids.append(g) }
        }
        // 2. Primary configured group
        if !ids.contains(primaryAppGroupId) { ids.append(primaryAppGroupId) }
        // 3. Derived bundle groups (both app and extension)
        if let baseId = Bundle.main.bundleIdentifier {
            let cleanBase = baseId.replacingOccurrences(of: ".widgets", with: "").replacingOccurrences(of: ".Widgets", with: "")
            let dynamicGroup = "group.\(cleanBase)"
            if !ids.contains(dynamicGroup) { ids.append(dynamicGroup) }
        }
        // 4. Common AltStore/SideStore AppGroup aliases
        let commonGroups = ["group.com.rileytestut.AltStore", "group.sideloadly"]
        for cg in commonGroups {
            if !ids.contains(cg) { ids.append(cg) }
        }
        return ids
    }
    
    public static func load() -> WidgetDailySnapshot {
        var candidates: [WidgetDailySnapshot] = []
        
        // 1. Try AppGroup UserDefaults across candidate identifiers
        for groupId in candidateGroupIds {
            if let userDefaults = UserDefaults(suiteName: groupId),
               let data = userDefaults.data(forKey: snapshotKey),
               let snapshot = try? JSONDecoder().decode(WidgetDailySnapshot.self, from: data) {
                candidates.append(snapshot)
            }
        }
        
        // 2. Try AppGroup Shared File Container across candidate identifiers
        for groupId in candidateGroupIds {
            if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId) {
                let fileURL = containerURL.appendingPathComponent(snapshotFileName)
                if let data = try? Data(contentsOf: fileURL),
                   let snapshot = try? JSONDecoder().decode(WidgetDailySnapshot.self, from: data) {
                    candidates.append(snapshot)
                }
            }
        }
        
        // 3. Try standard UserDefaults
        if let data = UserDefaults.standard.data(forKey: snapshotKey),
           let snapshot = try? JSONDecoder().decode(WidgetDailySnapshot.self, from: data) {
            candidates.append(snapshot)
        }
        
        // Pick the freshest available snapshot
        if let freshest = candidates.max(by: { $0.lastUpdated < $1.lastUpdated }) {
            return freshest
        }
        
        // 4. Fallback: resilient fallback with Morning (2) and Evening (2), ZERO afternoon
        return .fallback
    }
    
    public static func save(_ snapshot: WidgetDailySnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        
        // 1. Save to candidate AppGroup UserDefaults and force flush
        for groupId in candidateGroupIds {
            if let userDefaults = UserDefaults(suiteName: groupId) {
                userDefaults.set(data, forKey: snapshotKey)
                userDefaults.synchronize()
            }
        }
        
        // 2. Save to candidate AppGroup Shared File Containers
        for groupId in candidateGroupIds {
            if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupId) {
                let fileURL = containerURL.appendingPathComponent(snapshotFileName)
                try? FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true)
                try? data.write(to: fileURL, options: .atomic)
            }
        }
        
        // 3. Save to standard UserDefaults and flush
        UserDefaults.standard.set(data, forKey: snapshotKey)
        UserDefaults.standard.synchronize()
    }
}

