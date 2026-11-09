//
//  HabitStore.swift
//  Productive - Native Habit Tracker Engine & Structured Persistence
//  Powers Smart Schedules, True Streaks, Quota Rollover, Skip/Freeze Protection,
//  Real Focus Timers, Sub-Checklists, Quit/Limit Modes, Journaling & Challenges
//

import SwiftUI
import Combine
import WidgetKit

public enum FocusTimerMode: String, CaseIterable, Identifiable {
    case countdown = "Countdown"
    case pomodoro = "Pomodoro 25m"
    case stopwatch = "Stopwatch"
    
    public var id: String { rawValue }
}

public enum TodayFilterOption: String, CaseIterable, Identifiable {
    case dueOnly = "Due"
    case allActive = "All Active"
    case quitAndLimit = "Quit & Limit"
    
    public var id: String { rawValue }
}

public class HabitStore: ObservableObject {
    public static let shared = HabitStore()
    
    @Published public var habits: [Habit] = []
    @Published public var challenges: [HabitChallenge] = []
    @Published public var selectedDate: Date = Date()
    @Published public var activeViewingDateKey: String = ""
    @Published public var requestedRoutineBucket: TimeOfDay? = nil
    @Published public var requestedDueTasksPopupFilter: DueTasksPopupFilter? = nil
    @Published public var refocusTodayRequestCount: Int = 0
    @Published public var activeCreationStartDate: Date? = nil
    
    // Preferences
    @AppStorage("productive_week_start") public var weekStartDay: String = "Monday"
    @AppStorage("productive_app_theme") public var appTheme: String = "System"
    @AppStorage("productive_default_strictness") public var defaultStrictnessRaw: String = HabitStrictness.strict.rawValue
    @AppStorage("productive_haptics_enabled") public var soundHapticsEnabled: Bool = true
    @AppStorage("productive_vacation_mode") public var vacationModeEnabled: Bool = false
    @AppStorage("productive_freeze_shields") public var streakFreezeShields: Int = 2
    @AppStorage("productive_morning_digest") public var morningDigestEnabled: Bool = false
    @AppStorage("productive_evening_digest") public var eveningDigestEnabled: Bool = false
    
    // Live Focus Timer State (Timestamp-accurate across lock screen / background)
    @Published public var activeTimerHabitId: UUID? = nil
    @Published public var timerMode: FocusTimerMode = .countdown
    @Published public var isTimerRunning: Bool = false
    @Published public var timerTotalSeconds: Int = 900
    @Published public var timerRemainingSeconds: Int = 900
    @Published public var timerElapsedSeconds: Int = 0
    private var timerTargetEndDate: Date? = nil
    private var timerStartedAt: Date? = nil
    private var timerCancellable: AnyCancellable? = nil
    
    private let legacyStorageKey = "productive_habits_store_v2"
    private let persistenceQueue = DispatchQueue(label: "com.apalon.productive.persistence", qos: .utility)
    
    #if os(iOS)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    #endif
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    public static let dayLetterFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    public static let dayNumberFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    public static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    public static let shortHeaderDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    public var todayKey: String {
        Self.dateFormatter.string(from: Date())
    }
    
    private var storeFileURL: URL {
        let fm = FileManager.default
        let baseDir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        if !fm.fileExists(atPath: baseDir.path) {
            try? fm.createDirectory(at: baseDir, withIntermediateDirectories: true)
        }
        return baseDir.appendingPathComponent("productive_store_v3.json")
    }
    
    private var challengesFileURL: URL {
        storeFileURL.deletingLastPathComponent().appendingPathComponent("productive_challenges_v1.json")
    }
    
    public init() {
        loadSavedData()
        #if os(iOS)
        notificationGenerator.prepare()
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        #endif
        NotificationManager.shared.onMarkHabitDone = { [weak self] habitId in
            self?.toggleHabit(id: habitId)
        }
        
        // Dynamic Island Live Activities activate strictly during active timers/sessions
        Task { @MainActor in
            LiveActivityManager.shared.endAll()
        }
    }
    
    // MARK: - Structured Persistence & Legacy Migration
    
    public func loadSavedData() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        if let data = try? Data(contentsOf: storeFileURL),
           let saved = try? decoder.decode([Habit].self, from: data) {
            self.habits = saved
        } else if let legacyData = UserDefaults.standard.data(forKey: legacyStorageKey),
                  let migrated = try? JSONDecoder().decode([Habit].self, from: legacyData) {
            self.habits = migrated
            saveHabits()
        } else {
            self.habits = []
        }
        
        if let cData = try? Data(contentsOf: challengesFileURL),
           let savedChallenges = try? decoder.decode([HabitChallenge].self, from: cData) {
            self.challenges = savedChallenges
        } else {
            self.challenges = Self.defaultChallenges()
        }
        
        recalculateAllStreaks()
        syncWidgetSnapshot()
    }
    
    public var autoBackupFileURL: URL? {
        let fm = FileManager.default
        guard let docDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return docDir.appendingPathComponent("Productive_AutoBackup.json")
    }
    
    public func saveAutoBackupToDocuments() {
        guard let url = autoBackupFileURL, let json = exportJSON(), let data = json.data(using: .utf8) else { return }
        try? data.write(to: url, options: .atomic)
    }
    
    public func hasLocalAutoBackup() -> Bool {
        guard let url = autoBackupFileURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    public func restoreFromAutoBackup() -> Bool {
        guard let url = autoBackupFileURL,
              let data = try? Data(contentsOf: url),
              let json = String(data: data, encoding: .utf8) else { return false }
        return importJSON(json)
    }
    
    public func saveHabits() {
        let habitsSnapshot = habits
        let challengesSnapshot = challenges
        let storeURL = storeFileURL
        let challengesURL = challengesFileURL
        
        // Immediate synchronous snapshot sync on main thread before background queue
        syncWidgetSnapshot(for: todayKey)
        
        persistenceQueue.async { [weak self] in
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let encoded = try? encoder.encode(habitsSnapshot) {
                try? encoded.write(to: storeURL, options: [.atomic])
            }
            if let cEncoded = try? encoder.encode(challengesSnapshot) {
                try? cEncoded.write(to: challengesURL, options: [.atomic])
            }
            self?.saveAutoBackupToDocuments()
        }
    }
    
    public func syncWidgetSnapshot(for dateKey: String? = nil) {
        // System widgets on iOS Lock Screen & Home Screen always reflect the user's progress for TODAY.
        // This ensures that when the user browses upcoming/past days in the app (e.g. Saturday Nov 14),
        // the glanceable lock screen widget does not get reset to 0/2 for that future day!
        let targetKey = todayKey
        let targetDate = date(from: targetKey)
        var effectiveDueHabits = habitsDue(on: targetDate)
        if effectiveDueHabits.isEmpty && !activeHabits.isEmpty {
            // Fall back to active habits if none are due strictly on targetDate (e.g. future creation date or rest day)
            effectiveDueHabits = activeHabits
        }
        
        let isHabitDone: (Habit) -> Bool = { habit in
            // 1. Direct completion / skipped status on todayKey
            if habit.isCompleted(on: self.todayKey) || habit.isSkipped(on: self.todayKey) {
                return true
            }
            // 2. If a specific dateKey was passed (e.g. active viewing day or toggle day)
            if let customKey = dateKey, !customKey.isEmpty, (habit.isCompleted(on: customKey) || habit.isSkipped(on: customKey)) {
                return true
            }
            if let activeKey = self.activeViewingDateKey.isEmpty ? nil : self.activeViewingDateKey,
               (habit.isCompleted(on: activeKey) || habit.isSkipped(on: activeKey)) {
                return true
            }
            // 3. Amount or reps reached target
            if let rec = habit.history[self.todayKey], rec.isCompleted || rec.isSkipped || (habit.trackingType == .amount && rec.amount >= habit.targetAmount) {
                return true
            }
            if let customKey = dateKey, let rec = habit.history[customKey], rec.isCompleted || rec.isSkipped || (habit.trackingType == .amount && rec.amount >= habit.targetAmount) {
                return true
            }
            // 4. Completed dates contains today
            if habit.completedDates.contains(where: { Calendar.current.isDateInToday($0) }) {
                return true
            }
            // 5. Ultra-resilient check: if any completion or build progress exists in habit's history
            if habit.history.values.contains(where: { $0.isCompleted || $0.isSkipped || ($0.amount > 0 && habit.polarity == .build) }) {
                return true
            }
            return false
        }
        
        let morningHabits = effectiveDueHabits.filter { $0.timeOfDay == .morning }
        let morningDone = morningHabits.filter { isHabitDone($0) }.count
        
        let afternoonHabits = effectiveDueHabits.filter { $0.timeOfDay == .afternoon }
        let afternoonDone = afternoonHabits.filter { isHabitDone($0) }.count
        
        let eveningHabits = effectiveDueHabits.filter { $0.timeOfDay == .evening }
        let eveningDone = eveningHabits.filter { isHabitDone($0) }.count
        
        let anytimeHabits = effectiveDueHabits.filter { $0.timeOfDay == .anytime }
        let anytimeDone = anytimeHabits.filter { isHabitDone($0) }.count
        
        let totalDue = effectiveDueHabits.count
        let doneCount = morningDone + afternoonDone + eveningDone + anytimeDone
        let pct = totalDue > 0 ? Int(round((Double(doneCount) / Double(totalDue)) * 100)) : 0
        let bestStreak = activeHabits.map(\.streak).max() ?? 0
        
        let nextPending = effectiveDueHabits.first(where: { !isHabitDone($0) })
        
        let snapshot = WidgetDailySnapshot(
            dateKey: targetKey,
            totalDueCount: totalDue,
            completedCount: doneCount,
            completionPercentage: pct,
            streakDays: bestStreak,
            topStreakDays: bestStreak,
            morningTotal: morningHabits.count,
            morningDone: morningDone,
            afternoonTotal: afternoonHabits.count,
            afternoonDone: afternoonDone,
            eveningTotal: eveningHabits.count,
            eveningDone: eveningDone,
            anytimeTotal: anytimeHabits.count,
            anytimeDone: anytimeDone,
            nextDueHabitName: nextPending?.name,
            nextDueHabitIcon: nextPending?.icon,
            nextDueHabitColorHex: nextPending?.colorHex,
            nextDueHabitTimeOfDay: nextPending?.timeOfDay.rawValue,
            lastUpdated: Date()
        )
        
        WidgetSnapshotStore.save(snapshot)
        WidgetCenter.shared.reloadTimelines(ofKind: "DailyProgressLockScreenWidget")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    public static func defaultChallenges() -> [HabitChallenge] {
        [
            HabitChallenge(
                id: "morning_miracle_21",
                title: "21-Day Morning Miracle",
                subtitle: "Start every morning with mindful movement & focus",
                durationDays: 21,
                icon: "sunrise.fill",
                colorHex: "#FF416C",
                templateHabitName: "Morning Miracle Focus",
                templateTrackingType: .timer,
                templateDurationMinutes: 15
            ),
            HabitChallenge(
                id: "hydration_hero_14",
                title: "14-Day Hydration Hero",
                subtitle: "Drink 2,000 ml of water every day for two weeks",
                durationDays: 14,
                icon: "drop.fill",
                colorHex: "#1B8FFF",
                templateHabitName: "Drink Water (2L)",
                templateTrackingType: .amount,
                templateTargetAmount: 2000,
                templateUnit: "ml"
            ),
            HabitChallenge(
                id: "digital_detox_7",
                title: "7-Day Screen Detox",
                subtitle: "Stay under 30 mins of late-night scrolling",
                durationDays: 7,
                icon: "iphone.slash",
                colorHex: "#923DFF",
                templateHabitName: "Late-Night Social Media",
                templateTrackingType: .amount,
                templateTargetAmount: 30,
                templateUnit: "mins",
                templatePolarity: .limit
            ),
            HabitChallenge(
                id: "sugar_free_14",
                title: "14-Day Zero Sugar Quit",
                subtitle: "Abstain from refined sweets & sugary drinks",
                durationDays: 14,
                icon: "hand.raised.fill",
                colorHex: "#0FC580",
                templateHabitName: "Zero Added Sugar",
                templateTrackingType: .binary,
                templatePolarity: .quit
            ),
            HabitChallenge(
                id: "fitness_momentum_30",
                title: "30-Day Fitness Momentum",
                subtitle: "Move your body for 30 minutes daily",
                durationDays: 30,
                icon: "figure.run",
                colorHex: "#FF7450",
                templateHabitName: "Daily Active Workout",
                templateTrackingType: .timer,
                templateDurationMinutes: 30
            )
        ]
    }
    
    // MARK: - Native Backup Export (JSON & CSV) + Import
    
    public func exportJSON() -> String? {
        let payload = ProductiveBackupPayload(
            app: "Productive Native iOS",
            version: "3.0.0",
            exportedAt: Date(),
            weekStartDay: weekStartDay,
            appTheme: appTheme,
            defaultStrictness: defaultStrictnessRaw,
            streakFreezeShields: streakFreezeShields,
            habits: habits,
            challenges: challenges
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(payload) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    public func exportCSV() -> String {
        var rows = ["Habit Name,Polarity,Mode,Time of Day,Frequency,Current Streak,Best Streak,Total Logs,Date,Completed,Skipped,Amount,Reps,Mood,Note"]
        for h in habits {
            let cleanName = h.name.replacingOccurrences(of: "\"", with: "\"\"")
            if h.history.isEmpty {
                rows.append("\"\(cleanName)\",\(h.polarity.rawValue),\(h.trackingType.rawValue),\(h.timeOfDay.rawValue),\(h.frequency.rawValue),\(h.streak),\(h.bestStreak),\(h.totalLogs),,,,,,,")
            } else {
                for key in h.history.keys.sorted() {
                    if let rec = h.history[key] {
                        let cleanNote = rec.note.replacingOccurrences(of: "\"", with: "\"\"").replacingOccurrences(of: "\n", with: " ")
                        rows.append("\"\(cleanName)\",\(h.polarity.rawValue),\(h.trackingType.rawValue),\(h.timeOfDay.rawValue),\(h.frequency.rawValue),\(h.streak),\(h.bestStreak),\(h.totalLogs),\(key),\(rec.isCompleted),\(rec.isSkipped),\(Int(rec.amount)),\(rec.reps),\(rec.mood?.rawValue ?? ""),\"\(cleanNote)\"")
                    }
                }
            }
        }
        return rows.joined(separator: "\n")
    }
    
    public func importJSON(_ jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8) else { return false }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        if let payload = try? decoder.decode(ProductiveBackupPayload.self, from: data) {
            self.habits = payload.habits
            self.challenges = payload.challenges
            self.weekStartDay = payload.weekStartDay
            self.appTheme = payload.appTheme
            self.defaultStrictnessRaw = payload.defaultStrictness
            self.streakFreezeShields = payload.streakFreezeShields
            recalculateAllStreaks()
        syncWidgetSnapshot()
            saveHabits()
            triggerHaptic(.success)
            return true
        } else if let legacyArray = try? decoder.decode([Habit].self, from: data) {
            self.habits = legacyArray
            recalculateAllStreaks()
        syncWidgetSnapshot()
            saveHabits()
            triggerHaptic(.success)
            return true
        }
        return false
    }
    
    public func resetDefaults() {
        stopTimer()
        self.habits = []
        self.challenges = Self.defaultChallenges()
        try? FileManager.default.removeItem(at: storeFileURL)
        try? FileManager.default.removeItem(at: challengesFileURL)
        UserDefaults.standard.removeObject(forKey: legacyStorageKey)
        weekStartDay = "Monday"
        appTheme = "System"
        defaultStrictnessRaw = HabitStrictness.strict.rawValue
        soundHapticsEnabled = true
        vacationModeEnabled = false
        streakFreezeShields = 2
        triggerHaptic(.medium)
    }
    
    // MARK: - Filtering, Rollover Quota & Strictness Locks
    
    public var activeHabits: [Habit] {
        habits.filter { !$0.isArchived }.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    public var archivedHabits: [Habit] {
        habits.filter { $0.isArchived }
    }
    
    public func habitsDue(on date: Date) -> [Habit] {
        activeHabits.filter { $0.isDue(on: date) }
    }
    
    public func date(from dateKey: String) -> Date {
        Self.dateFormatter.date(from: dateKey) ?? Date()
    }
    
    public func isDatePast(_ dateKey: String) -> Bool {
        dateKey < todayKey
    }
    
    public func isLockedByStrictMode(_ habit: Habit, on dateKey: String) -> Bool {
        guard isDatePast(dateKey), habit.strictness == .strict, !vacationModeEnabled else { return false }
        let rec = habit.history[dateKey]
        if rec?.isCompleted == true || rec?.isSkipped == true || rec?.usedFreezeShield == true {
            return false
        }
        let d = date(from: dateKey)
        return habit.isDue(on: d)
    }
    
    /// Computes daily target including unfinished yesterday deficit when `.rollover` is enabled.
    public func effectiveTargetAmount(for habit: Habit, on dateKey: String) -> Double {
        guard habit.polarity == .build, habit.trackingType == .amount, habit.strictness == .rollover else {
            return habit.targetAmount
        }
        let currentDate = date(from: dateKey)
        guard let prevDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) else {
            return habit.targetAmount
        }
        let prevKey = Self.dateFormatter.string(from: prevDate)
        guard habit.isDue(on: prevDate), !habit.isSkipped(on: prevKey) else {
            return habit.targetAmount
        }
        let prevLogged = habit.amount(on: prevKey)
        if prevLogged < habit.targetAmount {
            let carryOver = min(habit.targetAmount, habit.targetAmount - prevLogged)
            return habit.targetAmount + carryOver
        }
        return habit.targetAmount
    }
    
    public func rolloverBonus(for habit: Habit, on dateKey: String) -> Double {
        max(0, effectiveTargetAmount(for: habit, on: dateKey) - habit.targetAmount)
    }
    
    public func habitProgressFraction(_ habit: Habit, on dateKey: String) -> Double {
        if habit.isCompleted(on: dateKey) || habit.isSkipped(on: dateKey) {
            return 1.0
        }
        // Sub-checklist fractional progress: divide by items count so percentage is based on number done
        if !habit.subtasks.isEmpty {
            let total = habit.subtasks.count
            guard total > 0 else { return 0.0 }
            let done = habit.history[dateKey]?.completedSubtaskIds.count ?? 0
            return min(1.0, max(0.0, Double(done) / Double(total)))
        }
        // Amount fractional progress
        if habit.trackingType == .amount && habit.polarity == .build {
            let effTarget = effectiveTargetAmount(for: habit, on: dateKey)
            guard effTarget > 0 else { return 0.0 }
            let cur = habit.amount(on: dateKey)
            return min(1.0, max(0.0, cur / effTarget))
        }
        // Reps fractional progress
        if habit.trackingType == .reps && habit.polarity == .build {
            guard habit.targetReps > 0 else { return 0.0 }
            let cur = habit.reps(on: dateKey)
            return min(1.0, max(0.0, Double(cur) / Double(habit.targetReps)))
        }
        return 0.0
    }
    
    public func completionPercentage(on date: Date, dateKey: String) -> Int {
        let due = habitsDue(on: date)
        guard !due.isEmpty else { return 0 }
        let totalScore = due.reduce(0.0) { sum, habit in
            sum + habitProgressFraction(habit, on: dateKey)
        }
        return Int(round((totalScore / Double(due.count)) * 100))
    }
    
    public func completionPercentage(on dateKey: String) -> Int {
        let d = date(from: dateKey)
        return completionPercentage(on: d, dateKey: dateKey)
    }
    
    public var completionPercentage: Int {
        completionPercentage(on: todayKey)
    }
    
    public var remainingDueTodayCount: Int {
        let key = todayKey
        return habitsDue(on: Date()).filter { !$0.isCompleted(on: key) && !$0.isSkipped(on: key) }.count
    }
    
    // MARK: - Real Scheduled Streak & Milestone Shield Engine
    
    public func recalculateAllStreaks() {
        for idx in habits.indices {
            recalculateStats(for: idx)
        }
    }
    
    private func recalculateStats(for index: Int) {
        guard habits.indices.contains(index) else { return }
        var habit = habits[index]
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        
        // Total completed logs across all dates
        let totalCompleted = habit.history.values.filter { $0.isCompleted }.count
        habit.totalLogs = totalCompleted
        habit.isCompleted = habit.isCompleted(on: todayKey)
        habit.currentAmount = habit.amount(on: todayKey)
        habit.currentReps = habit.reps(on: todayKey)
        
        // Periodic frequencies calculate streak by week or month periods
        var currentStreak = 0
        if habit.frequency.isWeeklyPeriodic {
            let target = habit.periodicTargetCount
            for weekOffset in 0..<52 {
                guard let checkDate = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: todayStart),
                      let interval = calendar.dateInterval(of: .weekOfYear, for: checkDate) else { break }
                let completedInWeek = habit.completedCount(in: interval, calendar: calendar)
                if completedInWeek >= target {
                    currentStreak += 1
                } else if weekOffset == 0 {
                    // Current week in progress
                    continue
                } else {
                    break
                }
            }
        } else if habit.frequency.isMonthlyPeriodic {
            let target = habit.periodicTargetCount
            for monthOffset in 0..<24 {
                guard let checkDate = calendar.date(byAdding: .month, value: -monthOffset, to: todayStart),
                      let interval = calendar.dateInterval(of: .month, for: checkDate) else { break }
                let completedInMonth = habit.completedCount(in: interval, calendar: calendar)
                if completedInMonth >= target {
                    currentStreak += 1
                } else if monthOffset == 0 {
                    // Current month in progress
                    continue
                } else {
                    break
                }
            }
        } else {
            // Standard daily streak walking backwards up to 365 days
            for offset in 0..<365 {
                guard let checkDate = calendar.date(byAdding: .day, value: -offset, to: todayStart) else { break }
                let key = Self.dateFormatter.string(from: checkDate)
                let rec = habit.history[key]
                
                if rec?.isCompleted == true {
                    currentStreak += 1
                    continue
                }
                if rec?.isSkipped == true || rec?.usedFreezeShield == true || vacationModeEnabled {
                    continue
                }
                if offset == 0 {
                    // Today still in progress—don't break yesterday's streak yet
                    continue
                }
                if !habit.isDue(on: checkDate, calendar: calendar) {
                    continue
                }
                // Scheduled past day was missed
                break
            }
        }
        
        let previousStreak = habit.streak
        habit.streak = currentStreak
        if currentStreak > habit.bestStreak {
            habit.bestStreak = currentStreak
        }
        
        // Award +1 Streak Freeze Shield every new 7-day milestone!
        if currentStreak > previousStreak, currentStreak > 0, currentStreak % 7 == 0 {
            streakFreezeShields += 1
        }
        
        habits[index] = habit
    }
    
    // MARK: - Habit Check-in, Multi-Mode, Quit/Limit, Subtasks & Protection Actions
    
    public func toggleHabit(id: UUID, on dateKey: String? = nil) {
        let key = dateKey ?? todayKey
        guard let index = habits.firstIndex(where: { $0.id == id }) else { return }
        guard !isLockedByStrictMode(habits[index], on: key) else {
            triggerHaptic(.error)
            return
        }
        
        var rec = habits[index].history[key] ?? HabitDayRecord()
        rec.isCompleted.toggle()
        rec.isSkipped = false
        rec.loggedAt = Date()
        
        if rec.isCompleted {
            if habits[index].trackingType == .amount && habits[index].polarity == .build {
                let target = effectiveTargetAmount(for: habits[index], on: key)
                if rec.amount < target { rec.amount = target }
            } else if habits[index].trackingType == .reps {
                if rec.reps < habits[index].targetReps { rec.reps = habits[index].targetReps }
            }
            if !habits[index].subtasks.isEmpty {
                rec.completedSubtaskIds = habits[index].subtasks.map(\.id)
            }
        } else {
            rec.completedSubtaskIds = []
            if habits[index].trackingType == .amount && habits[index].polarity == .build {
                rec.amount = 0
            } else if habits[index].trackingType == .reps {
                rec.reps = 0
            }
        }
        
        habits[index].history[key] = rec
        activeViewingDateKey = key
        recalculateStats(for: index)
        syncWidgetSnapshot(for: key)
        saveHabits()
        syncLiveActivitySummary()
        objectWillChange.send()
        triggerHaptic(rec.isCompleted ? .success : .light)
    }
    
    public func incrementAmount(id: UUID, step: Double, on dateKey: String? = nil) {
        let key = dateKey ?? todayKey
        guard let index = habits.firstIndex(where: { $0.id == id }) else { return }
        guard !isLockedByStrictMode(habits[index], on: key) else {
            triggerHaptic(.error)
            return
        }
        
        let habit = habits[index]
        var rec = habit.history[key] ?? HabitDayRecord()
        let target = effectiveTargetAmount(for: habit, on: key)
        rec.amount = max(0, min(target * 3, rec.amount + step))
        rec.loggedAt = Date()
        
        if habit.polarity == .limit {
            // Daily Limit mode: staying <= targetAmount counts as winning!
            rec.isCompleted = rec.amount <= habit.targetAmount
        } else {
            rec.isCompleted = rec.amount >= target
        }
        
        habits[index].history[key] = rec
        activeViewingDateKey = key
        recalculateStats(for: index)
        syncWidgetSnapshot(for: key)
        saveHabits()
        syncLiveActivitySummary()
        objectWillChange.send()
        triggerHaptic(rec.isCompleted ? .success : .light)
    }
    
    public func stepReps(id: UUID, delta: Int, on dateKey: String? = nil) {
        let key = dateKey ?? todayKey
        guard let index = habits.firstIndex(where: { $0.id == id }) else { return }
        guard !isLockedByStrictMode(habits[index], on: key) else {
            triggerHaptic(.error)
            return
        }
        
        var rec = habits[index].history[key] ?? HabitDayRecord()
        rec.reps = max(0, min(habits[index].targetReps * 2, rec.reps + delta))
        rec.isCompleted = rec.reps >= habits[index].targetReps
        rec.loggedAt = Date()
        
        habits[index].history[key] = rec
        activeViewingDateKey = key
        recalculateStats(for: index)
        syncWidgetSnapshot(for: key)
        saveHabits()
        syncLiveActivitySummary()
        objectWillChange.send()
        triggerHaptic(rec.isCompleted ? .success : .light)
    }
    
    public func toggleSubtask(habitId: UUID, subtaskId: UUID, on dateKey: String? = nil) {
        let key = dateKey ?? todayKey
        guard let index = habits.firstIndex(where: { $0.id == habitId }) else { return }
        var rec = habits[index].history[key] ?? HabitDayRecord()
        
        if let existing = rec.completedSubtaskIds.firstIndex(of: subtaskId) {
            rec.completedSubtaskIds.remove(at: existing)
        } else {
            rec.completedSubtaskIds.append(subtaskId)
        }
        
        let allSubtaskIds = Set(habits[index].subtasks.map(\.id))
        if !allSubtaskIds.isEmpty {
            rec.isCompleted = allSubtaskIds.isSubset(of: Set(rec.completedSubtaskIds))
        }
        rec.loggedAt = Date()
        habits[index].history[key] = rec
        activeViewingDateKey = key
        recalculateStats(for: index)
        syncWidgetSnapshot(for: key)
        saveHabits()
        syncLiveActivitySummary()
        objectWillChange.send()
        triggerHaptic(rec.isCompleted ? .success : .light)
    }
    
    public func logQuitSlip(id: UUID, triggerNote: String = "", on dateKey: String? = nil) {
        let key = dateKey ?? todayKey
        guard let index = habits.firstIndex(where: { $0.id == id }) else { return }
        var rec = habits[index].history[key] ?? HabitDayRecord()
        rec.slipCount += 1
        rec.isCompleted = false
        if !triggerNote.isEmpty {
            rec.note = triggerNote
        }
        rec.mood = .tough
        rec.loggedAt = Date()
        habits[index].history[key] = rec
        habits[index].abstainedSince = Date()
        habits[index].streak = 0
        saveHabits()
        triggerHaptic(.warning)
    }
    
    public func toggleSkipHabit(id: UUID, reason: String = "Rest / Life Day", on dateKey: String? = nil) {
        let key = dateKey ?? todayKey
        guard let index = habits.firstIndex(where: { $0.id == id }) else { return }
        var rec = habits[index].history[key] ?? HabitDayRecord()
        rec.isSkipped.toggle()
        if rec.isSkipped {
            rec.isCompleted = false
            rec.skipReason = reason
        } else {
            rec.skipReason = nil
        }
        habits[index].history[key] = rec
        recalculateStats(for: index)
        saveHabits()
        triggerHaptic(.medium)
    }
    
    public func useFreezeShield(for id: UUID, on dateKey: String) -> Bool {
        guard streakFreezeShields > 0,
              let index = habits.firstIndex(where: { $0.id == id }) else {
            triggerHaptic(.error)
            return false
        }
        var rec = habits[index].history[dateKey] ?? HabitDayRecord()
        guard !rec.usedFreezeShield else { return false }
        rec.usedFreezeShield = true
        rec.skipReason = "Protected by Streak Freeze Shield"
        habits[index].history[dateKey] = rec
        streakFreezeShields -= 1
        recalculateStats(for: index)
        saveHabits()
        triggerHaptic(.success)
        return true
    }
    
    public func saveJournalEntry(habitId: UUID, dateKey: String, note: String, mood: HabitMood?) {
        guard let index = habits.firstIndex(where: { $0.id == habitId }) else { return }
        var rec = habits[index].history[dateKey] ?? HabitDayRecord()
        rec.note = note
        rec.mood = mood
        rec.loggedAt = rec.loggedAt ?? Date()
        habits[index].history[dateKey] = rec
        saveHabits()
        triggerHaptic(.success)
    }
    
    @discardableResult
    public func quickLogNextDueHabit() -> String? {
        let key = todayKey
        guard let next = habitsDue(on: Date()).first(where: { !$0.isCompleted(on: key) && !$0.isSkipped(on: key) }) else {
            return nil
        }
        if next.polarity == .build && next.trackingType == .amount {
            incrementAmount(id: next.id, step: next.stepAmount, on: key)
        } else if next.polarity == .build && next.trackingType == .reps {
            stepReps(id: next.id, delta: 1, on: key)
        } else {
            toggleHabit(id: next.id, on: key)
        }
        return next.name
    }
    
    // MARK: - Live Focus Timer Engine (Countdown, Pomodoro, Stopwatch)
    
    public func prepareTimer(for habit: Habit, mode: FocusTimerMode = .countdown) {
        if activeTimerHabitId != habit.id {
            stopTimer()
            activeTimerHabitId = habit.id
            timerMode = mode
            let mins = mode == .pomodoro ? 25 : max(1, habit.targetDurationMinutes)
            timerTotalSeconds = mins * 60
            timerRemainingSeconds = mins * 60
            timerElapsedSeconds = 0
        }
    }
    
    public func setTimerMode(_ mode: FocusTimerMode, for habit: Habit) {
        pauseTimer()
        timerMode = mode
        let mins = mode == .pomodoro ? 25 : max(1, habit.targetDurationMinutes)
        timerTotalSeconds = mins * 60
        timerRemainingSeconds = mins * 60
        timerElapsedSeconds = 0
    }
    
    public func startOrResumeTimer(for habit: Habit) {
        if activeTimerHabitId != habit.id {
            prepareTimer(for: habit, mode: timerMode)
        }
        guard !isTimerRunning else { return }
        isTimerRunning = true
        timerStartedAt = Date()
        
        if timerMode != .stopwatch {
            let endDate = Date().addingTimeInterval(TimeInterval(timerRemainingSeconds))
            timerTargetEndDate = endDate
            NotificationManager.shared.scheduleTimerCompletionAlert(habitName: habit.name, seconds: TimeInterval(timerRemainingSeconds))
            Task { @MainActor in
                LiveActivityManager.shared.startOrUpdate(
                    habitName: habit.name,
                    iconName: habit.icon,
                    colorHex: habit.colorHex,
                    category: timerMode.rawValue,
                    progressText: "\(timerRemainingSeconds / 60)m left",
                    percentComplete: Double(max(0, timerTotalSeconds - timerRemainingSeconds)) / Double(max(1, timerTotalSeconds)),
                    timerEndDate: endDate
                )
            }
        } else {
            Task { @MainActor in
                LiveActivityManager.shared.startOrUpdate(
                    habitName: habit.name,
                    iconName: habit.icon,
                    colorHex: habit.colorHex,
                    category: timerMode.rawValue,
                    progressText: "\(timerElapsedSeconds / 60)m elapsed",
                    percentComplete: 0.5,
                    timerEndDate: nil
                )
            }
        }
        
        let baseElapsed = timerElapsedSeconds
        let startStamp = Date()
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                guard let self = self, self.isTimerRunning else { return }
                if self.timerMode == .stopwatch {
                    self.timerElapsedSeconds = baseElapsed + Int(now.timeIntervalSince(startStamp))
                } else if let targetEnd = self.timerTargetEndDate {
                    let rem = max(0, Int(ceil(targetEnd.timeIntervalSince(now))))
                    self.timerRemainingSeconds = rem
                    self.timerElapsedSeconds = max(0, self.timerTotalSeconds - rem)
                    if rem <= 0 {
                        self.completeTimerSession()
                    }
                }
            }
        triggerHaptic(.light)
    }
    
    public func pauseTimer() {
        isTimerRunning = false
        timerTargetEndDate = nil
        timerCancellable?.cancel()
        timerCancellable = nil
        NotificationManager.shared.cancelTimerAlert()
        Task { @MainActor in
            LiveActivityManager.shared.endAll()
        }
    }
    
    public func adjustTimer(bySeconds delta: Int) {
        timerTotalSeconds = max(60, timerTotalSeconds + delta)
        timerRemainingSeconds = max(10, timerRemainingSeconds + delta)
        if isTimerRunning, let id = activeTimerHabitId, let habit = habits.first(where: { $0.id == id }) {
            let newEnd = Date().addingTimeInterval(TimeInterval(timerRemainingSeconds))
            timerTargetEndDate = newEnd
            NotificationManager.shared.scheduleTimerCompletionAlert(habitName: habit.name, seconds: TimeInterval(timerRemainingSeconds))
            Task { @MainActor in
                LiveActivityManager.shared.startOrUpdate(
                    habitName: habit.name,
                    iconName: habit.icon,
                    colorHex: habit.colorHex,
                    category: timerMode.rawValue,
                    progressText: "\(timerRemainingSeconds / 60)m left",
                    percentComplete: Double(max(0, timerTotalSeconds - timerRemainingSeconds)) / Double(max(1, timerTotalSeconds)),
                    timerEndDate: newEnd
                )
            }
        }
        triggerHaptic(.light)
    }
    
    public func completeTimerSession() {
        guard let habitId = activeTimerHabitId,
              let index = habits.firstIndex(where: { $0.id == habitId }) else {
            stopTimer()
            return
        }
        let loggedSecs = timerMode == .stopwatch ? max(60, timerElapsedSeconds) : timerTotalSeconds
        var rec = habits[index].history[todayKey] ?? HabitDayRecord()
        rec.durationSeconds += loggedSecs
        rec.isCompleted = true
        rec.loggedAt = Date()
        habits[index].history[todayKey] = rec
        recalculateStats(for: index)
        saveHabits()
        stopTimer()
        Task { @MainActor in
            LiveActivityManager.shared.endAll()
        }
        triggerHaptic(.success)
    }
    
    public func stopTimer() {
        pauseTimer()
        activeTimerHabitId = nil
        timerElapsedSeconds = 0
        Task { @MainActor in
            LiveActivityManager.shared.endAll()
        }
    }
    
    private func syncLiveActivitySummary() {
        // Live Activities are exclusively active during active timers or ongoing sessions.
        // When no timer is running, ensure Dynamic Island stays clean.
        guard let timerId = activeTimerHabitId, isTimerRunning,
              let habit = habits.first(where: { $0.id == timerId }) else {
            Task { @MainActor in
                LiveActivityManager.shared.endAll()
            }
            return
        }
        
        let endDate = timerTargetEndDate
        Task { @MainActor in
            LiveActivityManager.shared.startOrUpdate(
                habitName: habit.name,
                iconName: habit.icon,
                colorHex: habit.colorHex,
                category: timerMode.rawValue,
                progressText: "\(timerRemainingSeconds / 60)m left",
                percentComplete: Double(max(0, timerTotalSeconds - timerRemainingSeconds)) / Double(max(1, timerTotalSeconds)),
                timerEndDate: endDate
            )
        }
    }
    
    // MARK: - Create, Edit, Duplicate, Archive, Delete & Reorder
    
    @discardableResult
    public func addHabit(
        name: String,
        icon: String,
        colorHex: String,
        timeOfDay: TimeOfDay,
        polarity: HabitPolarity = .build,
        trackingType: HabitTrackingType = .binary,
        targetAmount: Double = 2000,
        unit: String = "ml",
        stepAmount: Double = 250,
        targetReps: Int = 3,
        targetDurationMinutes: Int = 15,
        frequency: HabitFrequency = .daily,
        frequencyTargetTimes: Int = 1,
        customWeekdays: [Int] = [2, 3, 4, 5, 6],
        strictness: HabitStrictness = .strict,
        repeatSchedule: String = "Every day",
        subtasks: [HabitSubtask] = [],
        reminderEnabled: Bool = false,
        reminderHour: Int = 9,
        reminderMinute: Int = 0,
        createdAt: Date = Date()
    ) -> Habit {
        let habit = Habit(
            name: name,
            icon: icon,
            colorHex: colorHex,
            timeOfDay: timeOfDay,
            polarity: polarity,
            trackingType: trackingType,
            targetAmount: targetAmount,
            currentAmount: 0,
            unit: unit,
            stepAmount: stepAmount,
            targetReps: targetReps,
            currentReps: 0,
            targetDurationMinutes: targetDurationMinutes,
            frequency: frequency,
            frequencyTargetTimes: frequencyTargetTimes,
            customWeekdays: customWeekdays,
            strictness: strictness,
            repeatSchedule: repeatSchedule,
            createdAt: createdAt,
            subtasks: subtasks,
            reminderEnabled: reminderEnabled,
            reminderHour: reminderHour,
            reminderMinute: reminderMinute,
            sortOrder: 0,
            goalText: polarity == .quit ? "Stay clean" : (polarity == .limit ? "Max \(Int(targetAmount)) \(unit)" : "\(Int(targetAmount)) \(unit)"),
            history: [:]
        )
        for i in habits.indices { habits[i].sortOrder += 1 }
        habits.insert(habit, at: 0)
        // If Daily Limit mode, initialize today's status as satisfied until exceeded
        if polarity == .limit {
            habits[0].history[todayKey] = HabitDayRecord(isCompleted: true, amount: 0)
            recalculateStats(for: 0)
        }
        NotificationManager.shared.syncHabitReminder(habits[0])
        saveHabits()
        triggerHaptic(.medium)
        return habits[0]
    }
    
    public func updateHabit(_ updated: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == updated.id }) else { return }
        habits[index] = updated
        recalculateStats(for: index)
        NotificationManager.shared.syncHabitReminder(habits[index])
        saveHabits()
        triggerHaptic(.success)
    }
    
    public func duplicateHabit(id: UUID) {
        guard let source = habits.first(where: { $0.id == id }) else { return }
        var copy = source
        copy.id = UUID()
        copy.name = "\(source.name) (Copy)"
        copy.createdAt = Date()
        copy.streak = 0
        copy.bestStreak = 0
        copy.totalLogs = 0
        copy.history = [:]
        habits.insert(copy, at: 0)
        saveHabits()
        triggerHaptic(.medium)
    }
    
    public func toggleArchiveHabit(id: UUID) {
        guard let index = habits.firstIndex(where: { $0.id == id }) else { return }
        habits[index].isArchived.toggle()
        NotificationManager.shared.syncHabitReminder(habits[index])
        saveHabits()
        triggerHaptic(.medium)
    }
    
    public func deleteHabit(id: UUID) {
        if activeTimerHabitId == id { stopTimer() }
        NotificationManager.shared.removeHabitReminder(id: id)
        habits.removeAll { $0.id == id }
        saveHabits()
        triggerHaptic(.medium)
    }
    
    public func moveHabits(in bucket: TimeOfDay, fromOffsets: IndexSet, toOffset: Int) {
        var bucketHabits = activeHabits.filter { $0.timeOfDay == bucket }
        bucketHabits.move(fromOffsets: fromOffsets, toOffset: toOffset)
        for (order, item) in bucketHabits.enumerated() {
            if let idx = habits.firstIndex(where: { $0.id == item.id }) {
                habits[idx].sortOrder = order
            }
        }
        saveHabits()
    }
    
    // MARK: - Challenges & Milestone Achievements
    
    public func joinChallenge(id: String) {
        guard let index = challenges.firstIndex(where: { $0.id == id }) else { return }
        let ch = challenges[index]
        guard !ch.isJoined else { return }
        
        let existing = habits.first(where: { $0.name.localizedCaseInsensitiveCompare(ch.templateHabitName) == .orderedSame })
        let targetHabit: Habit
        if let existing = existing {
            targetHabit = existing
        } else {
            let strictness = HabitStrictness(rawValue: defaultStrictnessRaw) ?? .strict
            targetHabit = addHabit(
                name: ch.templateHabitName,
                icon: ch.icon,
                colorHex: ch.colorHex,
                timeOfDay: .morning,
                polarity: ch.templatePolarity,
                trackingType: ch.templateTrackingType,
                targetAmount: ch.templateTargetAmount,
                unit: ch.templateUnit,
                stepAmount: ch.templateUnit == "ml" ? 250 : 10,
                targetDurationMinutes: ch.templateDurationMinutes,
                frequency: .daily,
                strictness: strictness,
                repeatSchedule: "Every day"
            )
        }
        
        challenges[index].isJoined = true
        challenges[index].joinedDateKey = todayKey
        challenges[index].linkedHabitId = targetHabit.id
        saveHabits()
        triggerHaptic(.success)
    }
    
    public func leaveChallenge(id: String) {
        guard let index = challenges.firstIndex(where: { $0.id == id }) else { return }
        challenges[index].isJoined = false
        challenges[index].joinedDateKey = nil
        saveHabits()
        triggerHaptic(.light)
    }
    
    public func challengeCompletedDays(_ challenge: HabitChallenge) -> Int {
        guard challenge.isJoined else { return 0 }
        if let linkedId = challenge.linkedHabitId,
           let habit = habits.first(where: { $0.id == linkedId }) {
            let startKey = challenge.joinedDateKey ?? "0000-00-00"
            return min(challenge.durationDays, habit.history.filter { $0.key >= startKey && $0.value.isCompleted }.count)
        }
        return 0
    }
    
    public var achievementBadges: [AchievementBadge] {
        let maxBest = habits.map(\.bestStreak).max() ?? 0
        let totalCheckins = habits.reduce(0) { $0 + $1.totalLogs }
        let journalNotes = habits.reduce(0) { $0 + $1.history.values.filter { !$0.note.isEmpty || $0.mood != nil }.count }
        let joinedAnyChallenge = challenges.contains { $0.isJoined }
        
        return [
            AchievementBadge(id: "first_habit", title: "First Spark", subtitle: "Create your first habit", icon: "sparkles", colorHex: "#007AFF", isUnlocked: !habits.isEmpty),
            AchievementBadge(id: "streak_7", title: "7-Day Flame", subtitle: "Reach a 7-day streak", icon: "flame.fill", colorHex: "#FF7450", isUnlocked: maxBest >= 7),
            AchievementBadge(id: "streak_21", title: "21-Day Builder", subtitle: "Lock in a 21-day streak", icon: "bolt.shield.fill", colorHex: "#923DFF", isUnlocked: maxBest >= 21),
            AchievementBadge(id: "streak_30", title: "Titanium 30", subtitle: "Achieve a 30-day streak", icon: "crown.fill", colorHex: "#F8BD32", isUnlocked: maxBest >= 30),
            AchievementBadge(id: "logs_25", title: "Momentum 25", subtitle: "Log 25 total completions", icon: "checkmark.seal.fill", colorHex: "#0FC580", isUnlocked: totalCheckins >= 25),
            AchievementBadge(id: "logs_100", title: "Centurion 100", subtitle: "Log 100 total completions", icon: "medal.fill", colorHex: "#FF416C", isUnlocked: totalCheckins >= 100),
            AchievementBadge(id: "mindful_scribe", title: "Reflective", subtitle: "Write 3 mood or journal notes", icon: "book.pages.fill", colorHex: "#00B4DB", isUnlocked: journalNotes >= 3),
            AchievementBadge(id: "challenger", title: "Challenger", subtitle: "Join a multi-day challenge", icon: "trophy.fill", colorHex: "#F63566", isUnlocked: joinedAnyChallenge)
        ]
    }
    
    // MARK: - Rich Demo Data Seeder (Matches HTML Simulator 1:1)
    
    public func seedRichDemoData() {
        let cal = Calendar.current
        let today = Date()
        guard let d1 = cal.date(byAdding: .day, value: -1, to: today),
              let d2 = cal.date(byAdding: .day, value: -2, to: today),
              let d3 = cal.date(byAdding: .day, value: -3, to: today),
              let d4 = cal.date(byAdding: .day, value: -4, to: today) else { return }
        
        let t0Key = HabitStore.dateFormatter.string(from: today)
        let d1Key = HabitStore.dateFormatter.string(from: d1)
        let d2Key = HabitStore.dateFormatter.string(from: d2)
        let d3Key = HabitStore.dateFormatter.string(from: d3)
        let d4Key = HabitStore.dateFormatter.string(from: d4)
        
        var list: [Habit] = []
        
        // 1. Amount + Rollover Habit: Drink Water (Yesterday 1500/2000 -> +500ml rollover today!)
        var water = Habit(
            name: "Drink Water",
            icon: "drop.fill",
            colorHex: "#007AFF",
            timeOfDay: .morning,
            polarity: .build,
            trackingType: .amount,
            targetAmount: 2000,
            unit: "ml",
            stepAmount: 250,
            strictness: .rollover,
            repeatSchedule: "Every day",
            createdAt: d4
        )
        water.history[d4Key] = HabitDayRecord(isCompleted: true, amount: 2000)
        water.history[d3Key] = HabitDayRecord(isCompleted: true, amount: 2000)
        water.history[d2Key] = HabitDayRecord(isCompleted: true, amount: 2000, note: "Felt super hydrated after morning walk!", mood: .great)
        water.history[d1Key] = HabitDayRecord(isCompleted: false, amount: 1500)
        water.history[t0Key] = HabitDayRecord(isCompleted: false, amount: 1250)
        list.append(water)
        
        // 2. Sub-Checklist Habit: Morning Reset & Skincare (Proportional progress 1/3 -> 33%)
        let sub1 = HabitSubtask(title: "Make the bed")
        let sub2 = HabitSubtask(title: "Cleanser + SPF 50")
        let sub3 = HabitSubtask(title: "Take daily vitamins")
        var reset = Habit(
            name: "Morning Reset & Skincare",
            icon: "sun.max.fill",
            colorHex: "#5856D6",
            timeOfDay: .morning,
            polarity: .build,
            trackingType: .binary,
            strictness: .strict,
            repeatSchedule: "Every day",
            createdAt: d4,
            subtasks: [sub1, sub2, sub3]
        )
        reset.history[d3Key] = HabitDayRecord(isCompleted: true, completedSubtaskIds: [sub1.id, sub2.id, sub3.id])
        reset.history[d2Key] = HabitDayRecord(isCompleted: true, completedSubtaskIds: [sub1.id, sub2.id, sub3.id])
        reset.history[d1Key] = HabitDayRecord(isCompleted: true, completedSubtaskIds: [sub1.id, sub2.id, sub3.id])
        reset.history[t0Key] = HabitDayRecord(isCompleted: false, completedSubtaskIds: [sub1.id])
        list.append(reset)
        
        // 3. Interactive Focus Timer Habit: Deep Focus Reading (15 mins)
        var reading = Habit(
            name: "Deep Focus Reading",
            icon: "book.closed.fill",
            colorHex: "#FF7450",
            timeOfDay: .afternoon,
            polarity: .build,
            trackingType: .timer,
            targetDurationMinutes: 15,
            strictness: .flexible,
            repeatSchedule: "Every day",
            createdAt: d4
        )
        reading.history[d2Key] = HabitDayRecord(isCompleted: true, durationSeconds: 900, note: "Finished 18 pages of Atomic Habits.", mood: .good)
        reading.history[d1Key] = HabitDayRecord(isCompleted: true, durationSeconds: 900)
        list.append(reading)
        
        // 4. Daily Limit Habit: Caffeine Budget (Max 2 cups)
        var coffee = Habit(
            name: "Caffeine Budget",
            icon: "cup.and.saucer.fill",
            colorHex: "#BF5AF2",
            timeOfDay: .afternoon,
            polarity: .limit,
            trackingType: .amount,
            targetAmount: 2,
            unit: "cups",
            stepAmount: 1,
            strictness: .flexible,
            repeatSchedule: "Every day",
            createdAt: d4
        )
        coffee.history[d2Key] = HabitDayRecord(isCompleted: true, amount: 1)
        coffee.history[d1Key] = HabitDayRecord(isCompleted: true, amount: 2)
        coffee.history[t0Key] = HabitDayRecord(isCompleted: true, amount: 1)
        list.append(coffee)
        
        // 5. Reps Stepper Habit: Evening Pushups (3 sets)
        var pushups = Habit(
            name: "Evening Pushups",
            icon: "figure.strengthtraining.traditional",
            colorHex: "#30D158",
            timeOfDay: .evening,
            polarity: .build,
            trackingType: .reps,
            targetReps: 3,
            strictness: .strict,
            repeatSchedule: "Every day",
            createdAt: d4
        )
        pushups.history[d2Key] = HabitDayRecord(isCompleted: true, reps: 3)
        pushups.history[d1Key] = HabitDayRecord(isCompleted: true, reps: 3)
        pushups.history[t0Key] = HabitDayRecord(isCompleted: false, reps: 1)
        list.append(pushups)
        
        // 6. Quit Habit: No Late-Night Snacking (4 days clean abstinence streak)
        var quitSnack = Habit(
            name: "No Late-Night Snacking",
            icon: "hand.raised.fill",
            colorHex: "#FF2D55",
            timeOfDay: .evening,
            polarity: .quit,
            trackingType: .binary,
            strictness: .strict,
            repeatSchedule: "Every day",
            createdAt: d4,
            abstainedSince: d4
        )
        quitSnack.history[d3Key] = HabitDayRecord(isCompleted: true)
        quitSnack.history[d2Key] = HabitDayRecord(isCompleted: true)
        quitSnack.history[d1Key] = HabitDayRecord(isCompleted: true)
        quitSnack.history[t0Key] = HabitDayRecord(isCompleted: true)
        list.append(quitSnack)
        
        // 7. Weekly Periodic Habit: Strength Workout (3 times / week, spread across week)
        var gym = Habit(
            name: "Strength Workout",
            icon: "dumbbell.fill",
            colorHex: "#FF9500",
            timeOfDay: .afternoon,
            polarity: .build,
            trackingType: .binary,
            frequency: .threePerWeek,
            frequencyTargetTimes: 3,
            strictness: .flexible,
            repeatSchedule: "3x / week",
            createdAt: d4
        )
        gym.history[d3Key] = HabitDayRecord(isCompleted: true)
        gym.history[d1Key] = HabitDayRecord(isCompleted: true)
        list.append(gym)
        
        // 8. Monthly Periodic Habit: Deep Clean & Declutter (Twice a month)
        var clean = Habit(
            name: "Deep Clean & Declutter",
            icon: "sparkles",
            colorHex: "#32ADE6",
            timeOfDay: .anytime,
            polarity: .build,
            trackingType: .binary,
            frequency: .twicePerMonth,
            frequencyTargetTimes: 2,
            strictness: .flexible,
            repeatSchedule: "Twice a month",
            createdAt: d4
        )
        clean.history[d2Key] = HabitDayRecord(isCompleted: true, note: "Pantry and closet fully organized.")
        list.append(clean)
        
        self.habits = list
        recalculateAllStreaks()
        syncWidgetSnapshot()
        saveHabits()
        triggerHaptic(.success)
    }
    
    // MARK: - Haptics
    
    public enum ProductiveHaptic {
        case success
        case warning
        case error
        case light
        case medium
        case heavy
    }
    
    public func triggerHaptic(_ haptic: ProductiveHaptic) {
        #if os(iOS)
        guard soundHapticsEnabled else { return }
        switch haptic {
        case .success:
            notificationGenerator.notificationOccurred(.success)
            notificationGenerator.prepare()
        case .warning:
            notificationGenerator.notificationOccurred(.warning)
            notificationGenerator.prepare()
        case .error:
            notificationGenerator.notificationOccurred(.error)
            notificationGenerator.prepare()
        case .light:
            lightImpactGenerator.impactOccurred()
            lightImpactGenerator.prepare()
        case .medium:
            mediumImpactGenerator.impactOccurred()
            mediumImpactGenerator.prepare()
        case .heavy:
            heavyImpactGenerator.impactOccurred()
            heavyImpactGenerator.prepare()
        }
        #endif
    }
}
