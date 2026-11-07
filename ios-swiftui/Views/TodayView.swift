//
//  TodayView.swift
//  Productive - Native Cupertino Today Screen
//  Uses InsetGrouped List, Swipe Actions, Context Menus, Drag Reordering,
//  Pull-Down Search, Graphical Calendar Popover, Guided Routine Launcher & Floating Timer Bar
//

import SwiftUI

public struct DayModel: Identifiable, Equatable {
    public let id: Int
    public let date: Date
    public let dayLetter: String
    public let dayNumber: String
    public let dateKey: String
    public let fullDateName: String
    public let isToday: Bool
}

public struct TodayView: View {
    @EnvironmentObject var habitStore: HabitStore
    @Binding var showingAddSheet: Bool
    
    @State private var selectedDateKey: String? = nil
    @State private var searchText: String = ""
    @State private var filterOption: TodayFilterOption = .dueOnly
    @State private var showingCalendarPopover: Bool = false
    @State private var calendarPickerDate: Date = Date()
    
    // Sheet Presentation States
    @State private var timerSheetHabit: Habit? = nil
    @State private var journalSheetTarget: Habit? = nil
    @State private var editingHabitTarget: Habit? = nil
    @State private var activeRoutineBucket: TimeOfDay? = nil
    
    var timelineDays: [DayModel] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        
        let dayLetterFormatter = DateFormatter()
        dayLetterFormatter.dateFormat = "EEE"
        dayLetterFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let dayNumberFormatter = DateFormatter()
        dayNumberFormatter.dateFormat = "d"
        dayNumberFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let fullFormatter = DateFormatter()
        fullFormatter.dateFormat = "EEEE, MMM d"
        fullFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        return (-21...14).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: todayStart) else { return nil }
            let isToday = (offset == 0)
            return DayModel(
                id: offset,
                date: date,
                dayLetter: isToday ? "TODAY" : dayLetterFormatter.string(from: date).uppercased(),
                dayNumber: dayNumberFormatter.string(from: date),
                dateKey: HabitStore.dateFormatter.string(from: date),
                fullDateName: fullFormatter.string(from: date),
                isToday: isToday
            )
        }
    }
    
    var activeDateKey: String {
        selectedDateKey ?? habitStore.todayKey
    }
    
    var activeDate: Date {
        habitStore.date(from: activeDateKey)
    }
    
    var isViewingToday: Bool {
        activeDateKey == habitStore.todayKey
    }
    
    var visibleHabits: [Habit] {
        var base = habitStore.activeHabits
        switch filterOption {
        case .dueOnly:
            base = base.filter { $0.isDue(on: activeDate) }
        case .allActive:
            break
        case .quitAndLimit:
            base = base.filter { $0.polarity != .build }
        }
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = searchText.lowercased()
            base = base.filter {
                $0.name.lowercased().contains(q) ||
                $0.note(on: activeDateKey).lowercased().contains(q)
            }
        }
        return base
    }
    
    public var body: some View {
        NavigationStack {
            List {
                // MARK: Top Timeline Ribbon & Progress Summary Header
                Section {
                    VStack(spacing: 14) {
                        // Vacation Banner if active
                        if habitStore.vacationModeEnabled {
                            HStack(spacing: 8) {
                                Image(systemName: "beach.umbrella.fill")
                                    .foregroundStyle(.orange)
                                Text("Vacation Mode Active — Streaks Protected")
                                    .font(.caption.weight(.bold))
                                Spacer()
                                Button("Resume") {
                                    habitStore.vacationModeEnabled = false
                                }
                                .font(.caption.weight(.bold))
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }
                            .padding(10)
                            .background(.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        
                        // Past / Upcoming Date Banner
                        if !isViewingToday {
                            HStack {
                                Label(
                                    "Viewing \(HabitStore.dateFormatter.string(from: activeDate))",
                                    systemImage: activeDate < Date() ? "clock.arrow.circlepath" : "calendar.badge.clock"
                                )
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.orange)
                                
                                Spacer()
                                
                                Button("Today") {
                                    withAnimation(.snappy) {
                                        selectedDateKey = habitStore.todayKey
                                    }
                                    habitStore.triggerHaptic(.light)
                                }
                                .font(.caption.weight(.bold))
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)
                                .controlSize(.mini)
                            }
                            .padding(10)
                            .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        
                        // Horizontal Scrollable Date Ribbon
                        ScrollViewReader { proxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(timelineDays) { day in
                                        let isSelected = (day.dateKey == activeDateKey)
                                        let dayPct = habitStore.completionPercentage(on: day.dateKey)
                                        Button {
                                            withAnimation(.snappy) {
                                                selectedDateKey = day.dateKey
                                            }
                                            habitStore.triggerHaptic(.light)
                                        } label: {
                                            VStack(spacing: 5) {
                                                Text(day.dayLetter)
                                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                                    .foregroundStyle(isSelected ? .white.opacity(0.9) : (day.isToday ? Color.accentColor : .secondary))
                                                
                                                Text(day.dayNumber)
                                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                                                    .foregroundStyle(isSelected ? .white : .primary)
                                                
                                                Circle()
                                                    .fill(dayPct == 100 ? Color.green : (dayPct > 0 ? Color.orange : Color.clear))
                                                    .frame(width: 5, height: 5)
                                            }
                                            .frame(width: 46, height: 58)
                                            .background(
                                                isSelected ? AnyShapeStyle(Color.accentColor.gradient) : AnyShapeStyle(Color(.tertiarySystemGroupedBackground)),
                                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                        .id(day.dateKey)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                            .onAppear {
                                DispatchQueue.main.async {
                                    proxy.scrollTo(habitStore.todayKey, anchor: .center)
                                }
                            }
                        }
                        
                        // Apple Fitness-Style Daily Ring Card
                        dailyProgressCard
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                
                // MARK: Filter Segmented Bar
                if !habitStore.activeHabits.isEmpty {
                    Section {
                        Picker("Filter", selection: $filterOption) {
                            ForEach(TodayFilterOption.allCases) { opt in
                                Text(opt.rawValue).tag(opt)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                        .listRowBackground(Color.clear)
                    }
                }
                
                // MARK: Empty State or Grouped Habit Sections
                if habitStore.activeHabits.isEmpty {
                    Section {
                        VStack(spacing: 14) {
                            Image(systemName: "checklist.checked")
                                .font(.system(size: 44))
                                .foregroundStyle(Color.accentColor)
                                .padding(.top, 12)
                            
                            Text("Build Your Daily Routine")
                                .font(.system(.title3, design: .rounded).weight(.bold))
                            
                            Text("Pick from 83 curated habits or create custom timers, water goals, sub-checklists, and quit-streaks.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button {
                                showingAddSheet = true
                                habitStore.triggerHaptic(.medium)
                            } label: {
                                Label("Add First Habit", systemImage: "plus")
                                    .font(.system(.headline, design: .rounded).weight(.bold))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                            .padding(.bottom, 12)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                } else if visibleHabits.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "No Matching Habits",
                            systemImage: "calendar.badge.checkmark",
                            description: Text("Nothing scheduled for this filter or search query.")
                        )
                    }
                } else {
                    ForEach(TimeOfDay.allCases) { bucket in
                        let bucketHabits = visibleHabits.filter { $0.timeOfDay == bucket }
                        if !bucketHabits.isEmpty {
                            Section {
                                ForEach(bucketHabits) { habit in
                                    NavigationLink {
                                        HabitDetailView(habitId: habit.id)
                                    } label: {
                                        HabitCardView(
                                            habit: habit,
                                            dateKey: activeDateKey,
                                            onOpenTimer: { timerSheetHabit = habit }
                                        )
                                    }
                                    // Leading Swipe: Quick Complete or +Step
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button {
                                            habitStore.toggleHabit(id: habit.id, on: activeDateKey)
                                        } label: {
                                            Label(
                                                habit.isCompleted(on: activeDateKey) ? "Undo" : "Done",
                                                systemImage: habit.isCompleted(on: activeDateKey) ? "arrow.uturn.backward" : "checkmark.circle.fill"
                                            )
                                        }
                                        .tint(.green)
                                        
                                        if habit.trackingType == .amount && habit.polarity == .build {
                                            Button {
                                                habitStore.incrementAmount(id: habit.id, step: habit.stepAmount, on: activeDateKey)
                                            } label: {
                                                Label("+\(Int(habit.stepAmount))", systemImage: "plus.circle.fill")
                                            }
                                            .tint(.blue)
                                        }
                                    }
                                    // Trailing Swipe: Delete, Edit, Skip/Rest
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            habitStore.deleteHabit(id: habit.id)
                                        } label: {
                                            Label("Delete", systemImage: "trash.fill")
                                        }
                                        
                                        Button {
                                            editingHabitTarget = habit
                                        } label: {
                                            Label("Edit", systemImage: "slider.horizontal.3")
                                        }
                                        .tint(.indigo)
                                        
                                        Button {
                                            habitStore.toggleSkipHabit(id: habit.id, on: activeDateKey)
                                        } label: {
                                            Label(habit.isSkipped(on: activeDateKey) ? "Unskip" : "Skip", systemImage: "forward.end.fill")
                                        }
                                        .tint(.orange)
                                    }
                                    // Native Long-Press Context Menu
                                    .contextMenu {
                                        Button {
                                            habitStore.toggleHabit(id: habit.id, on: activeDateKey)
                                        } label: {
                                            Label(habit.isCompleted(on: activeDateKey) ? "Mark Incomplete" : "Mark Completed", systemImage: "checkmark.circle")
                                        }
                                        
                                        if habit.trackingType == .timer {
                                            Button {
                                                timerSheetHabit = habit
                                            } label: {
                                                Label("Open Focus Timer", systemImage: "timer")
                                            }
                                        }
                                        
                                        Button {
                                            journalSheetTarget = habit
                                        } label: {
                                            Label("Add Mood & Reflection Note", systemImage: "square.and.pencil")
                                        }
                                        
                                        Button {
                                            habitStore.toggleSkipHabit(id: habit.id, on: activeDateKey)
                                        } label: {
                                            Label(habit.isSkipped(on: activeDateKey) ? "Remove Skip" : "Skip / Rest Day", systemImage: "forward.end")
                                        }
                                        
                                        if habitStore.isLockedByStrictMode(habit, on: activeDateKey) && habitStore.streakFreezeShields > 0 {
                                            Button {
                                                _ = habitStore.useFreezeShield(for: habit.id, on: activeDateKey)
                                            } label: {
                                                Label("Use Streak Freeze Shield (\(habitStore.streakFreezeShields) left)", systemImage: "snowflake")
                                            }
                                        }
                                        
                                        Divider()
                                        
                                        Button {
                                            editingHabitTarget = habit
                                        } label: {
                                            Label("Edit Habit", systemImage: "pencil")
                                        }
                                        
                                        Button {
                                            habitStore.duplicateHabit(id: habit.id)
                                        } label: {
                                            Label("Duplicate", systemImage: "plus.square.on.square")
                                        }
                                        
                                        Button {
                                            habitStore.toggleArchiveHabit(id: habit.id)
                                        } label: {
                                            Label("Archive Habit", systemImage: "archivebox")
                                        }
                                        
                                        Divider()
                                        
                                        Button(role: .destructive) {
                                            habitStore.deleteHabit(id: habit.id)
                                        } label: {
                                            Label("Delete Habit", systemImage: "trash")
                                        }
                                    }
                                }
                                .onMove { from, to in
                                    habitStore.moveHabits(in: bucket, fromOffsets: from, toOffset: to)
                                }
                            } header: {
                                HStack {
                                    Label(bucket.rawValue, systemImage: bucket.icon)
                                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                                        .foregroundStyle(.primary)
                                        .textCase(nil)
                                    
                                    Spacer()
                                    
                                    let doneCount = bucketHabits.filter { $0.isCompleted(on: activeDateKey) }.count
                                    Text("\(doneCount)/\(bucketHabits.count)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    
                                    Button {
                                        activeRoutineBucket = bucket
                                    } label: {
                                        HStack(spacing: 3) {
                                            Image(systemName: "play.fill")
                                                .font(.system(size: 9))
                                            Text("Routine")
                                                .font(.caption2.weight(.bold))
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.accentColor.opacity(0.14), in: Capsule())
                                        .foregroundStyle(Color.accentColor)
                                    }
                                    .buttonStyle(.plain)
                                    .textCase(nil)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(isViewingToday ? "Today" : "Timeline")
            .searchable(text: $searchText, prompt: "Search habits or notes")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 10) {
                        Button {
                            calendarPickerDate = activeDate
                            showingCalendarPopover = true
                        } label: {
                            Image(systemName: "calendar")
                        }
                        .accessibilityLabel("Jump to Date")
                        
                        HStack(spacing: 3) {
                            Image(systemName: "snowflake")
                                .font(.caption)
                                .foregroundStyle(.cyan)
                            Text("\(habitStore.streakFreezeShields)")
                                .font(.caption.weight(.bold))
                                .contentTransition(.numericText())
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.cyan.opacity(0.14), in: Capsule())
                    }
                }
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        EditButton()
                        
                        Button {
                            habitStore.vacationModeEnabled.toggle()
                        } label: {
                            Label(
                                habitStore.vacationModeEnabled ? "Disable Vacation Mode" : "Enable Vacation Mode",
                                systemImage: "beach.umbrella"
                            )
                        }
                        
                        Button {
                            _ = habitStore.quickLogNextDueHabit()
                        } label: {
                            Label("Quick Log Next Habit", systemImage: "bolt.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.title3)
                    }
                    .accessibilityLabel("Add Habit")
                }
            }
            // Floating Active Focus Timer Mini-Player
            .safeAreaInset(edge: .bottom) {
                if let activeId = habitStore.activeTimerHabitId,
                   let runningHabit = habitStore.habits.first(where: { $0.id == activeId }) {
                    activeTimerMiniPlayer(for: runningHabit)
                }
            }
            // Graphical DatePicker Popover / Sheet
            .sheet(isPresented: $showingCalendarPopover) {
                NavigationStack {
                    VStack {
                        DatePicker(
                            "Select Date",
                            selection: $calendarPickerDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .padding()
                        Spacer()
                    }
                    .navigationTitle("Jump to Date")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Today") {
                                selectedDateKey = habitStore.todayKey
                                showingCalendarPopover = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                selectedDateKey = HabitStore.dateFormatter.string(from: calendarPickerDate)
                                showingCalendarPopover = false
                            }
                            .fontWeight(.bold)
                        }
                    }
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            // Focus Timer Sheet
            .sheet(item: $timerSheetHabit) { habit in
                FocusTimerSheet(habit: habit)
                    .environmentObject(habitStore)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            // Reflection Journal Sheet
            .sheet(item: $journalSheetTarget) { habit in
                JournalEntrySheet(habit: habit, dateKey: activeDateKey)
                    .environmentObject(habitStore)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            // Edit Habit Sheet
            .sheet(item: $editingHabitTarget) { habit in
                AddHabitSheet(editingHabit: habit)
                    .environmentObject(habitStore)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            // Guided Routine Player Sheet
            .sheet(item: $activeRoutineBucket) { bucket in
                RoutinePlayerSheet(bucket: bucket, dateKey: activeDateKey)
                    .environmentObject(habitStore)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .onChange(of: habitStore.requestedRoutineBucket) { _, newBucket in
                if let bucket = newBucket {
                    activeRoutineBucket = bucket
                    habitStore.requestedRoutineBucket = nil
                }
            }
        }
    }
    
    // MARK: - Daily Progress Card
    
    private var dailyProgressCard: some View {
        let due = habitStore.habitsDue(on: activeDate)
        let doneCount = due.filter { $0.isCompleted(on: activeDateKey) || $0.isSkipped(on: activeDateKey) }.count
        let pct = habitStore.completionPercentage(on: activeDateKey)
        let bestActiveStreak = habitStore.activeHabits.map(\.streak).max() ?? 0
        
        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(
                    due.isEmpty ? "Ready to Plan" :
                    pct == 100 ? "All Goals Complete! 🎉" :
                    pct >= 60 ? "Strong Momentum 🔥" : "Daily Focus"
                )
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(.primary)
                
                Text(due.isEmpty ? "Tap + to schedule habits" : "\(doneCount) of \(due.count) scheduled habits done")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    Label("\(bestActiveStreak)d Top Streak", systemImage: "flame.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.orange.opacity(0.14), in: Capsule())
                }
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 8)
                    .frame(width: 68, height: 68)
                
                Circle()
                    .trim(from: 0, to: CGFloat(pct) / 100.0)
                    .stroke(
                        Color.accentColor.gradient,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 68, height: 68)
                    .rotationEffect(.degrees(-90))
                    .animation(.snappy, value: pct)
                
                Text("\(pct)%")
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .contentTransition(.numericText())
                    .foregroundStyle(.primary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
    // MARK: - Floating Active Timer Mini-Player
    
    private func activeTimerMiniPlayer(for habit: Habit) -> some View {
        let secs = habitStore.timerMode == .stopwatch ? habitStore.timerElapsedSeconds : habitStore.timerRemainingSeconds
        let timeStr = String(format: "%02d:%02d", secs / 60, secs % 60)
        
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: habit.colorHex))
                    .frame(width: 36, height: 36)
                Image(systemName: habit.icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(habit.name)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)
                Text("\(habitStore.timerMode.rawValue) • \(timeStr)")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            
            Spacer()
            
            Button {
                if habitStore.isTimerRunning {
                    habitStore.pauseTimer()
                } else {
                    habitStore.startOrResumeTimer(for: habit)
                }
            } label: {
                Image(systemName: habitStore.isTimerRunning ? "pause.fill" : "play.fill")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            
            Button {
                habitStore.completeTimerSession()
            } label: {
                Image(systemName: "checkmark")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .buttonBorderShape(.circle)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .onTapGesture {
            timerSheetHabit = habit
        }
    }
}
