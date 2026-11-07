//
//  TodayView.swift
//  Productive - Pinned-Header Cupertino Today Screen
//  Zero wasted space: Pinned Header, Horizontal-Only Date Ribbon, Compact Daily Focus Card,
//  Sliding Filter Bar, and Dedicated Vertically-Scrolling Habit List with 120Hz Tactile Response
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
    
    @Namespace private var filterNamespace
    @FocusState private var isSearchFieldFocused: Bool
    
    @State private var selectedDateKey: String? = nil
    @State private var isShowingSearchBar: Bool = false
    @State private var searchText: String = ""
    @State private var filterOption: TodayFilterOption = .dueOnly
    @State private var showingCalendarPopover: Bool = false
    @State private var calendarPickerDate: Date = Date()
    @State private var listEditMode: EditMode = .inactive
    
    // Navigation & Sheet Presentation States
    @State private var selectedDetailHabitId: UUID? = nil
    @State private var timerSheetHabit: Habit? = nil
    @State private var journalSheetTarget: Habit? = nil
    @State private var editingHabitTarget: Habit? = nil
    @State private var activeRoutineBucket: TimeOfDay? = nil
    
    private var timelineDays: [DayModel] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        
        return (-21...14).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: todayStart) else { return nil }
            let isToday = (offset == 0)
            return DayModel(
                id: offset,
                date: date,
                dayLetter: isToday ? "TODAY" : HabitStore.dayLetterFormatter.string(from: date).uppercased(),
                dayNumber: HabitStore.dayNumberFormatter.string(from: date),
                dateKey: HabitStore.dateFormatter.string(from: date),
                fullDateName: HabitStore.fullDateFormatter.string(from: date),
                isToday: isToday
            )
        }
    }
    
    private var activeDateKey: String {
        selectedDateKey ?? habitStore.todayKey
    }
    
    private var activeDate: Date {
        habitStore.date(from: activeDateKey)
    }
    
    private var isViewingToday: Bool {
        activeDateKey == habitStore.todayKey
    }
    
    private var dueCountOnActiveDate: Int {
        habitStore.habitsDue(on: activeDate).count
    }
    
    private var visibleHabits: [Habit] {
        var base = habitStore.activeHabits
        switch filterOption {
        case .dueOnly:
            base = base.filter { $0.isDue(on: activeDate) }
        case .allActive:
            break
        case .quitAndLimit:
            base = base.filter { $0.polarity != .build }
        }
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            let q = trimmed.lowercased()
            base = base.filter {
                $0.name.lowercased().contains(q) ||
                $0.note(on: activeDateKey).lowercased().contains(q)
            }
        }
        return base
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Pinned Non-Scrolling Control Deck (Never scrolls up/down!)
                pinnedTopDeck
                
                Divider()
                    .opacity(0.45)
                
                // MARK: - Dedicated Habit Scroll Region (Only this area scrolls vertically!)
                habitsScrollRegion
            }
            .background(Color(.systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $selectedDetailHabitId) { habitId in
                HabitDetailView(habitId: habitId)
            }
            // Floating Active Focus Timer Mini-Player
            .safeAreaInset(edge: .bottom) {
                if let activeId = habitStore.activeTimerHabitId,
                   let runningHabit = habitStore.habits.first(where: { $0.id == activeId }) {
                    activeTimerMiniPlayer(for: runningHabit)
                }
            }
            // Graphical DatePicker Sheet
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
    
    // MARK: - Pinned Top Control Deck
    
    private var pinnedTopDeck: some View {
        VStack(spacing: 8) {
            // 1. Sleek Compact Header Row
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(alignment: .firstTextBaseline, spacing: 7) {
                        Text(isViewingToday ? "Today" : "Timeline")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundStyle(.primary)
                        
                        if !isViewingToday {
                            Button {
                                withAnimation(.snappy(duration: 0.22)) {
                                    selectedDateKey = habitStore.todayKey
                                }
                                habitStore.triggerHaptic(.light)
                            } label: {
                                Text("↩ Today")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(.orange.opacity(0.15), in: Capsule())
                            }
                            .buttonStyle(TactileScaleButtonStyle())
                        }
                    }
                    
                    Button {
                        calendarPickerDate = activeDate
                        showingCalendarPopover = true
                        habitStore.triggerHaptic(.light)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11, weight: .semibold))
                            Text(HabitStore.shortHeaderDateFormatter.string(from: activeDate))
                                .font(.caption.weight(.semibold))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer(minLength: 4)
                
                // Trailing Compact Action Pills
                HStack(spacing: 7) {
                    // Shield Counter Pill
                    HStack(spacing: 3) {
                        Image(systemName: "snowflake")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.cyan)
                        Text("\(habitStore.streakFreezeShields)")
                            .font(.caption.weight(.heavy))
                            .contentTransition(.numericText())
                    }
                    .padding(.horizontal, 8)
                    .frame(height: 32)
                    .background(Color.cyan.opacity(0.14), in: Capsule())
                    
                    // Collapsible Search Toggle
                    Button {
                        withAnimation(.snappy(duration: 0.22)) {
                            isShowingSearchBar.toggle()
                            if !isShowingSearchBar {
                                searchText = ""
                                isSearchFieldFocused = false
                            } else {
                                isSearchFieldFocused = true
                            }
                        }
                        habitStore.triggerHaptic(.light)
                    } label: {
                        Image(systemName: isShowingSearchBar ? "xmark" : "magnifyingglass")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(isShowingSearchBar ? Color.accentColor : .primary)
                            .frame(width: 32, height: 32)
                            .background(Color(.secondarySystemGroupedBackground), in: Circle())
                    }
                    .buttonStyle(TactileScaleButtonStyle())
                    .accessibilityLabel("Search Habits")
                    
                    // Quick Menu
                    Menu {
                        Button {
                            withAnimation(.snappy) {
                                listEditMode = (listEditMode == .active) ? .inactive : .active
                            }
                        } label: {
                            Label(
                                listEditMode == .active ? "Done Reordering" : "Reorder Habits",
                                systemImage: listEditMode == .active ? "checkmark.circle" : "arrow.up.arrow.down"
                            )
                        }
                        
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
                        Image(systemName: "ellipsis")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(width: 32, height: 32)
                            .background(Color(.secondarySystemGroupedBackground), in: Circle())
                    }
                    
                    // Primary Add Habit Button
                    Button {
                        showingAddSheet = true
                        habitStore.triggerHaptic(.medium)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#007AFF"), Color(hex: "#5856D6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: Circle()
                            )
                            .shadow(color: Color.accentColor.opacity(0.32), radius: 6, y: 3)
                    }
                    .buttonStyle(TactileScaleButtonStyle())
                    .accessibilityLabel("Add Habit")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            
            // 2. On-Demand Compact Search Field
            if isShowingSearchBar {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    TextField("Search habits or notes...", text: $searchText)
                        .font(.subheadline)
                        .focused($isSearchFieldFocused)
                        .submitLabel(.search)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Vacation Mode Slim Banner (if active)
            if habitStore.vacationModeEnabled {
                HStack(spacing: 6) {
                    Image(systemName: "beach.umbrella.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("Vacation Mode — Streaks Protected")
                        .font(.caption.weight(.bold))
                    Spacer()
                    Button("Resume") {
                        habitStore.vacationModeEnabled = false
                    }
                    .font(.caption2.weight(.bold))
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(.horizontal, 16)
            }
            
            // 3. Horizontal-Only Date Ribbon (Moves strictly Left/Right!)
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(timelineDays) { day in
                            let isSelected = (day.dateKey == activeDateKey)
                            let dayPct = habitStore.completionPercentage(on: day.date, dateKey: day.dateKey)
                            Button {
                                withAnimation(.snappy(duration: 0.22)) {
                                    selectedDateKey = day.dateKey
                                }
                                habitStore.triggerHaptic(.light)
                            } label: {
                                VStack(spacing: 3) {
                                    Text(day.dayLetter)
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .foregroundStyle(isSelected ? .white.opacity(0.92) : (day.isToday ? Color.accentColor : .secondary))
                                    
                                    Text(day.dayNumber)
                                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                                        .foregroundStyle(isSelected ? .white : .primary)
                                    
                                    Circle()
                                        .fill(dayPct == 100 ? Color.green : (dayPct > 0 ? Color.orange : Color.clear))
                                        .frame(width: 4.5, height: 4.5)
                                }
                                .frame(width: 44, height: 50)
                                .background(
                                    isSelected
                                        ? AnyShapeStyle(
                                            LinearGradient(
                                                colors: [Color(hex: "#007AFF"), Color(hex: "#3867FF")],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        : AnyShapeStyle(Color(.secondarySystemGroupedBackground)),
                                    in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                                        .stroke(
                                            isSelected ? Color.white.opacity(0.22) : Color.primary.opacity(0.06),
                                            lineWidth: 0.8
                                        )
                                )
                            }
                            .buttonStyle(TactileScaleButtonStyle(pressedScale: 0.94))
                            .id(day.dateKey)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                .onAppear {
                    DispatchQueue.main.async {
                        proxy.scrollTo(habitStore.todayKey, anchor: .center)
                    }
                }
            }
            
            // 4. Compact, Jewel-Like Daily Focus Card (Zero unused vertical space!)
            dailyProgressCard
                .padding(.horizontal, 16)
            
            // 5. Sleek Sliding Filter Pills (Tightly integrated right under Daily Focus!)
            if !habitStore.activeHabits.isEmpty {
                slidingFilterBar
                    .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 8)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Sliding Filter Bar
    
    private var slidingFilterBar: some View {
        HStack(spacing: 4) {
            ForEach(TodayFilterOption.allCases) { opt in
                let isSelected = (filterOption == opt)
                Button {
                    withAnimation(.snappy(duration: 0.22)) {
                        filterOption = opt
                    }
                    habitStore.triggerHaptic(.light)
                } label: {
                    HStack(spacing: 4) {
                        Text(opt.rawValue)
                            .font(.system(size: 12.5, weight: isSelected ? .bold : .semibold, design: .rounded))
                        if opt == .dueOnly && dueCountOnActiveDate > 0 {
                            Text("\(dueCountOnActiveDate)")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(
                                    isSelected ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.16),
                                    in: Capsule()
                                )
                                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                        }
                    }
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Color(.tertiarySystemGroupedBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .stroke(Color.primary.opacity(0.08), lineWidth: 0.6)
                                )
                                .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                                .matchedGeometryEffect(id: "todayFilterIndicator", in: filterNamespace)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
    
    // MARK: - Dedicated Habits Scroll Region
    
    @ViewBuilder
    private var habitsScrollRegion: some View {
        if habitStore.activeHabits.isEmpty {
            VStack(spacing: 14) {
                Spacer(minLength: 20)
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.14))
                        .frame(width: 72, height: 72)
                    Image(systemName: "checklist.checked")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
                
                Text("Build Your Daily Routine")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                
                Text("Pick from 83 curated habits or craft custom timers, water goals, sub-checklists, and quit-streaks.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Button {
                    showingAddSheet = true
                    habitStore.triggerHaptic(.medium)
                } label: {
                    Label("Add First Habit", systemImage: "plus")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 11)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if visibleHabits.isEmpty {
            ContentUnavailableView(
                "No Matching Habits",
                systemImage: "calendar.badge.checkmark",
                description: Text("Nothing scheduled for this filter or search query.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(TimeOfDay.allCases) { bucket in
                    let bucketHabits = visibleHabits.filter { $0.timeOfDay == bucket }
                    if !bucketHabits.isEmpty {
                        Section {
                            ForEach(bucketHabits) { habit in
                                HabitCardView(
                                    habit: habit,
                                    dateKey: activeDateKey,
                                    onOpenDetail: { selectedDetailHabitId = habit.id },
                                    onOpenTimer: { timerSheetHabit = habit }
                                )
                                .listRowInsets(EdgeInsets(top: 9, leading: 14, bottom: 9, trailing: 14))
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
                                        selectedDetailHabitId = habit.id
                                    } label: {
                                        Label("Habit Overview & Heatmap", systemImage: "chart.bar.xaxis")
                                    }
                                    
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
                            HStack(spacing: 6) {
                                Image(systemName: bucket.icon)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(bucket.tintColor)
                                
                                Text(bucket.rawValue)
                                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                                
                                let doneCount = bucketHabits.filter { $0.isCompleted(on: activeDateKey) }.count
                                Text("\(doneCount)/\(bucketHabits.count)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.12), in: Capsule())
                                    .textCase(nil)
                                
                                Spacer()
                                
                                Button {
                                    activeRoutineBucket = bucket
                                    habitStore.triggerHaptic(.light)
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 8.5, weight: .bold))
                                        Text("Routine")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                    }
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.15), in: Capsule())
                                    .foregroundStyle(Color.accentColor)
                                }
                                .buttonStyle(TactileScaleButtonStyle())
                                .textCase(nil)
                            }
                            .padding(.bottom, 2)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(10)
            .contentMargins(.top, 6, for: .scrollContent)
            .scrollContentBackground(.hidden)
            .environment(\.editMode, $listEditMode)
        }
    }
    
    // MARK: - Compact, Elegant Daily Focus Card
    
    private var dailyProgressCard: some View {
        let due = habitStore.habitsDue(on: activeDate)
        let doneCount = due.filter { $0.isCompleted(on: activeDateKey) || $0.isSkipped(on: activeDateKey) }.count
        let pct = habitStore.completionPercentage(on: activeDate, dateKey: activeDateKey)
        let bestActiveStreak = habitStore.activeHabits.map(\.streak).max() ?? 0
        
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(
                        due.isEmpty ? "Ready to Plan" :
                        pct == 100 ? "All Goals Complete! 🎉" :
                        pct >= 60 ? "Strong Momentum 🔥" : "Daily Focus"
                    )
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
                    
                    Label("\(bestActiveStreak)d", systemImage: "flame.fill")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(.orange.opacity(0.15), in: Capsule())
                }
                
                Text(due.isEmpty ? "Tap + to schedule your first habit" : "\(doneCount) of \(due.count) scheduled habits done")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 4)
            
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.09), lineWidth: 5.5)
                    .frame(width: 48, height: 48)
                
                Circle()
                    .trim(from: 0, to: CGFloat(pct) / 100.0)
                    .stroke(
                        LinearGradient(
                            colors: pct == 100 ? [.green, .mint] : [Color(hex: "#007AFF"), Color(hex: "#5856D6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 5.5, lineCap: .round)
                    )
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
                    .animation(.snappy(duration: 0.28), value: pct)
                
                Text("\(pct)%")
                    .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                    .contentTransition(.numericText())
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 0.8)
        )
    }
    
    // MARK: - Floating Active Timer Mini-Player
    
    private func activeTimerMiniPlayer(for habit: Habit) -> some View {
        let secs = habitStore.timerMode == .stopwatch ? habitStore.timerElapsedSeconds : habitStore.timerRemainingSeconds
        let timeStr = String(format: "%02d:%02d", secs / 60, secs % 60)
        
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: habit.colorHex))
                    .frame(width: 34, height: 34)
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
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            
            Button {
                habitStore.completeTimerSession()
            } label: {
                Image(systemName: "checkmark")
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .buttonBorderShape(.circle)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 10, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .onTapGesture {
            timerSheetHabit = habit
        }
    }
}
