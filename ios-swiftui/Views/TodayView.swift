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

private struct TodayPillMinXPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 16
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

public struct TodayView: View {
    @EnvironmentObject var habitStore: HabitStore
    @Binding var showingAddSheet: Bool
    
    @Namespace private var filterNamespace
    @Namespace private var dayRibbonNamespace
    @FocusState private var isSearchFieldFocused: Bool
    
    @State private var selectedDateKey: String? = nil
    @State private var isShowingSearchBar: Bool = false
    @State private var searchText: String = ""
    @State private var filterOption: TodayFilterOption = .dueOnly
    @State private var showingCalendarPopover: Bool = false
    @State private var calendarPickerDate: Date = Date()
    @State private var listEditMode: EditMode = .inactive
    
    // Date Ribbon Refocus & Reorder Animation States
    @State private var refocusTodayToken: Int = 0
    @State private var refocusWaveActive: Bool = false
    @State private var isRibbonScrolledFromToday: Bool = false
    @State private var calendarScrollTargetKey: String? = nil
    
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
                                showingCalendarPopover = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                    refocusToToday()
                                }
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                let pickedKey = HabitStore.dateFormatter.string(from: calendarPickerDate)
                                showingCalendarPopover = false
                                if pickedKey == habitStore.todayKey {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                        refocusToToday()
                                    }
                                } else {
                                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                                        selectedDateKey = pickedKey
                                        calendarScrollTargetKey = pickedKey
                                    }
                                }
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
            .onChange(of: habitStore.refocusTodayRequestCount) { _, _ in
                refocusToToday()
            }
        }
    }
    
    // MARK: - Animated Return-to-Today Refocus & Leading Reorder
    
    private func refocusToToday() {
        habitStore.triggerHaptic(.medium)
        withAnimation(.spring(response: 0.46, dampingFraction: 0.78)) {
            selectedDateKey = habitStore.todayKey
            isRibbonScrolledFromToday = false
            refocusWaveActive = true
            refocusTodayToken += 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.46) {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.84)) {
                refocusWaveActive = false
            }
        }
    }
    
    // MARK: - Pinned Top Control Deck (Balanced Cupertino Breathing Room)
    
    private var pinnedTopDeck: some View {
        VStack(spacing: 13) {
            // 1. Sleek Header Row with Return-to-Today Refocus Action
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .center, spacing: 8) {
                        Button {
                            refocusToToday()
                        } label: {
                            Text(isViewingToday ? "Today" : "Timeline")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(.primary)
                                .contentTransition(.interpolate)
                        }
                        .buttonStyle(.plain)
                        
                        if !isViewingToday || isRibbonScrolledFromToday {
                            Button {
                                refocusToToday()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.uturn.backward")
                                        .font(.system(size: 10.5, weight: .heavy))
                                    Text("Today")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.orange.opacity(0.16), in: Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.orange.opacity(0.28), lineWidth: 0.7)
                                )
                            }
                            .buttonStyle(TactileScaleButtonStyle(pressedScale: 0.92))
                            .transition(.scale(scale: 0.86).combined(with: .opacity))
                        }
                    }
                    
                    Button {
                        calendarPickerDate = activeDate
                        showingCalendarPopover = true
                        habitStore.triggerHaptic(.light)
                    } label: {
                        HStack(spacing: 4.5) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11.5, weight: .semibold))
                            Text(HabitStore.shortHeaderDateFormatter.string(from: activeDate))
                                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9.5, weight: .bold))
                        }
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer(minLength: 4)
                
                // Trailing Action Pills
                HStack(spacing: 8) {
                    // Shield Counter Pill
                    HStack(spacing: 3.5) {
                        Image(systemName: "snowflake")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundStyle(.cyan)
                        Text("\(habitStore.streakFreezeShields)")
                            .font(.caption.weight(.heavy))
                            .contentTransition(.numericText())
                    }
                    .padding(.horizontal, 9)
                    .frame(height: 34)
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
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundStyle(isShowingSearchBar ? Color.accentColor : .primary)
                            .frame(width: 34, height: 34)
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
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(width: 34, height: 34)
                            .background(Color(.secondarySystemGroupedBackground), in: Circle())
                    }
                    
                    // Primary Add Habit Button
                    Button {
                        showingAddSheet = true
                        habitStore.triggerHaptic(.medium)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15.5, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
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
            .padding(.top, 10)
            
            // 2. On-Demand Search Field
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
                .padding(.vertical, 9)
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
                .padding(.vertical, 7)
                .background(.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                .padding(.horizontal, 16)
            }
            
            // 3. Horizontal-Only Date Ribbon — TODAY Anchored First on Leading Edge
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8.5) {
                        ForEach(timelineDays) { day in
                            dayRibbonPill(for: day)
                        }
                    }
                    .padding(.vertical, 3)
                }
                .contentMargins(.horizontal, 16, for: .scrollContent)
                .coordinateSpace(name: "todayRibbonViewport")
                .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                .onPreferenceChange(TodayPillMinXPreferenceKey.self) { minX in
                    let movedAway = !(minX >= -6 && minX <= 36)
                    if movedAway != isRibbonScrolledFromToday && !refocusWaveActive {
                        withAnimation(.snappy(duration: 0.2)) {
                            isRibbonScrolledFromToday = movedAway
                        }
                    }
                }
                .onAppear {
                    DispatchQueue.main.async {
                        proxy.scrollTo(habitStore.todayKey, anchor: .leading)
                    }
                }
                .onChange(of: refocusTodayToken) { _, _ in
                    withAnimation(.spring(response: 0.46, dampingFraction: 0.78)) {
                        proxy.scrollTo(habitStore.todayKey, anchor: .leading)
                    }
                }
                .onChange(of: calendarScrollTargetKey) { _, targetKey in
                    guard let key = targetKey else { return }
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                        proxy.scrollTo(key, anchor: key == habitStore.todayKey ? .leading : .center)
                    }
                    calendarScrollTargetKey = nil
                }
            }
            
            // 4. Balanced Jewel-Like Daily Focus Card
            dailyProgressCard
                .padding(.horizontal, 16)
            
            // 5. Sleek Sliding Filter Pills
            if !habitStore.activeHabits.isEmpty {
                slidingFilterBar
                    .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 13)
        .background(Color(.systemGroupedBackground))
    }
    
    private func dayRibbonPill(for day: DayModel) -> some View {
        let isSelected = (day.dateKey == activeDateKey)
        let dayPct = habitStore.completionPercentage(on: day.date, dateKey: day.dateKey)
        let waveScale: CGFloat = {
            guard refocusWaveActive else { return 1.0 }
            if day.isToday { return 1.07 }
            if day.id < 0 { return 0.90 }
            if day.id <= 7 { return 0.94 }
            return 1.0
        }()
        let waveOffsetX: CGFloat = {
            guard refocusWaveActive else { return 0 }
            if day.id >= 1 && day.id <= 7 { return CGFloat(day.id) * 5.0 }
            if day.id < 0 { return -6.0 }
            return 0
        }()
        let waveDelay: Double = (day.id >= 1 && day.id <= 7) ? Double(day.id) * 0.022 : 0.0
        
        return Button {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                selectedDateKey = day.dateKey
            }
            habitStore.triggerHaptic(.light)
        } label: {
            VStack(spacing: 4) {
                Text(day.dayLetter)
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.94) : (day.isToday ? Color.accentColor : Color.secondary))
                
                Text(day.dayNumber)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(isSelected ? Color.white : Color.primary)
                
                Circle()
                    .fill(dayPct == 100 ? Color.green : (dayPct > 0 ? Color.orange : Color.clear))
                    .frame(width: 4.5, height: 4.5)
            }
            .frame(width: 49, height: 58)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14.5, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#007AFF"), Color(hex: "#3867FF")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(
                            color: Color(hex: "#007AFF").opacity(refocusWaveActive && day.isToday ? 0.45 : 0.24),
                            radius: refocusWaveActive && day.isToday ? 9 : 5,
                            y: 2
                        )
                        .matchedGeometryEffect(id: "selectedDayPillBG", in: dayRibbonNamespace)
                } else {
                    RoundedRectangle(cornerRadius: 14.5, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14.5, style: .continuous)
                    .stroke(
                        isSelected ? Color.white.opacity(0.24) : (day.isToday ? Color.accentColor.opacity(0.32) : Color.primary.opacity(0.06)),
                        lineWidth: day.isToday && !isSelected ? 1.1 : 0.8
                    )
            )
        }
        .buttonStyle(TactileScaleButtonStyle(pressedScale: 0.94))
        .scaleEffect(waveScale)
        .offset(x: waveOffsetX)
        .opacity(refocusWaveActive && day.id < 0 ? 0.45 : 1.0)
        .animation(.spring(response: 0.44, dampingFraction: 0.76).delay(waveDelay), value: refocusWaveActive)
        .background {
            if day.isToday {
                GeometryReader { geo in
                    Color.clear.preference(
                        key: TodayPillMinXPreferenceKey.self,
                        value: geo.frame(in: .named("todayRibbonViewport")).minX
                    )
                }
            }
        }
        .id(day.dateKey)
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
                    HStack(spacing: 4.5) {
                        Text(opt.rawValue)
                            .font(.system(size: 13, weight: isSelected ? .bold : .semibold, design: .rounded))
                        if opt == .dueOnly && dueCountOnActiveDate > 0 {
                            Text("\(dueCountOnActiveDate)")
                                .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                                .padding(.horizontal, 5.5)
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
                    .padding(.vertical, 8)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 9.5, style: .continuous)
                                .fill(Color(.tertiarySystemGroupedBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 9.5, style: .continuous)
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
        .padding(3.5)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                                .listRowInsets(EdgeInsets(top: 11, leading: 15, bottom: 11, trailing: 15))
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
                            .padding(.bottom, 4)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(16)
            .contentMargins(.top, 12, for: .scrollContent)
            .scrollContentBackground(.hidden)
            .environment(\.editMode, $listEditMode)
        }
    }
    
    // MARK: - Balanced, Elegant Daily Focus Card
    
    private var dailyProgressCard: some View {
        let due = habitStore.habitsDue(on: activeDate)
        let doneCount = due.filter { $0.isCompleted(on: activeDateKey) || $0.isSkipped(on: activeDateKey) }.count
        let pct = habitStore.completionPercentage(on: activeDate, dateKey: activeDateKey)
        let bestActiveStreak = habitStore.activeHabits.map(\.streak).max() ?? 0
        
        return HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 5.5) {
                HStack(spacing: 7) {
                    Text(
                        due.isEmpty ? "Ready to Plan" :
                        pct == 100 ? "All Goals Complete! 🎉" :
                        pct >= 60 ? "Strong Momentum 🔥" : "Daily Focus"
                    )
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
                    
                    Label("\(bestActiveStreak)d", systemImage: "flame.fill")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 7.5)
                        .padding(.vertical, 3)
                        .background(.orange.opacity(0.15), in: Capsule())
                }
                
                Text(due.isEmpty ? "Tap + to schedule your first habit" : "\(doneCount) of \(due.count) scheduled habits done")
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 4)
            
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.09), lineWidth: 6)
                    .frame(width: 54, height: 54)
                
                Circle()
                    .trim(from: 0, to: CGFloat(pct) / 100.0)
                    .stroke(
                        LinearGradient(
                            colors: pct == 100 ? [.green, .mint] : [Color(hex: "#007AFF"), Color(hex: "#5856D6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 54, height: 54)
                    .rotationEffect(.degrees(-90))
                    .animation(.snappy(duration: 0.28), value: pct)
                
                Text("\(pct)%")
                    .font(.system(size: 12.5, weight: .heavy, design: .rounded))
                    .contentTransition(.numericText())
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
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
