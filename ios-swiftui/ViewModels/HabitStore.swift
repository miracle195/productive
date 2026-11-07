//
//  HabitStore.swift
//  Productive - Native Habit Tracker Engine & Structured Persistence
//  Powers Smart Schedules, True Streaks, Quota Rollover, Skip/Freeze Protection,
//  Real Focus Timers, Sub-Checklists, Quit/Limit Modes, Journaling & Challenges
//

import SwiftUI
import Combine

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
    @Published public var requestedRoutineBucket: TimeOfDay? = nil
    
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
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
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
        NotificationManager.shared.onMarkHabitDone = { [weak self] habitId in
            self?.toggleHabit(id: habitId)
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
    }
    
    public func saveHabits() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let encoded = try? encoder.encode(habits) {
            try? encoded.write(to: storeFileURL, options: [.atomic])
        }
        if let cEncoded = try? encoder.encode(challenges) {
            try? cEncoded.write(to: challengesFileURL, options: [.atomic])
        }
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
            saveHabits()
            triggerHaptic(.success)
            return true
        } else if let legacyArray = try? decoder.decode([Habit].self, from: data) {
            self.habits = legacyArray
            recalculateAllStreaks()
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
    
    public func completionPercentage(on dateKey: String) -> Int {
        let d = date(from: dateKey)
        let due = habitsDue(on: d)
        guard !due.isEmpty else { return 0 }
        let satisfied = due.filter { $0.isCompleted(on: dateKey) || $0.isSkipped(on: dateKey) }.count
        return Int((Double(satisfied) / Double(due.count)) * 100)
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
        
        // Compute current streak walking backwards up to 365 days
        var currentStreak = 0
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
        }
        
        habits[index].history[key] = rec
        recalculateStats(for: index)
        saveHabits()
        syncLiveActivitySummary()
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
        recalculateStats(for: index)
        saveHabits()
        syncLiveActivitySummary()
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
        recalculateStats(for: index)
        saveHabits()
        syncLiveActivitySummary()
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
        recalculateStats(for: index)
        saveHabits()
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
    }
    
    public func adjustTimer(bySeconds delta: Int) {
        timerTotalSeconds = max(60, timerTotalSeconds + delta)
        timerRemainingSeconds = max(10, timerRemainingSeconds + delta)
        if isTimerRunning, let id = activeTimerHabitId, let habit = habits.first(where: { $0.id == id }) {
            let newEnd = Date().addingTimeInterval(TimeInterval(timerRemainingSeconds))
            timerTargetEndDate = newEnd
            NotificationManager.shared.scheduleTimerCompletionAlert(habitName: habit.name, seconds: TimeInterval(timerRemainingSeconds))
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
        syncLiveActivitySummary()
        triggerHaptic(.success)
    }
    
    public func stopTimer() {
        pauseTimer()
        activeTimerHabitId = nil
        timerElapsedSeconds = 0
    }
    
    private func syncLiveActivitySummary() {
        let due = habitsDue(on: Date())
        guard !due.isEmpty else { return }
        let doneCount = due.filter { $0.isCompleted(on: todayKey) }.count
        let pct = Double(doneCount) / Double(due.count)
        let nextHabit = due.first(where: { !$0.isCompleted(on: todayKey) }) ?? due[0]
        Task { @MainActor in
            LiveActivityManager.shared.startOrUpdate(
                habitName: nextHabit.name,
                iconName: nextHabit.icon,
                colorHex: nextHabit.colorHex,
                category: "Daily Routine",
                progressText: "\(doneCount)/\(due.count) done",
                percentComplete: pct,
                timerEndDate: nil
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
        customWeekdays: [Int] = [2, 3, 4, 5, 6],
        strictness: HabitStrictness = .strict,
        repeatSchedule: String = "Every day",
        subtasks: [HabitSubtask] = [],
        reminderEnabled: Bool = false,
        reminderHour: Int = 9,
        reminderMinute: Int = 0
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
            customWeekdays: customWeekdays,
            strictness: strictness,
            repeatSchedule: repeatSchedule,
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
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
        #endif
    }
}
