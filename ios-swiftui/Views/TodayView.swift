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
    @Namespace private var dayRibbonNamespace
    @FocusState private var isSearchFieldFocused: Bool
    
    @State private var selectedDateKey: String? = nil
    @State private var searchText: String = ""
    @State private var isSearchVisible: Bool = false
    @State private var filterOption: TodayFilterOption = .dueOnly
    @State private var showingCalendarPopover: Bool = false
    @State private var calendarPickerDate: Date = Date()
    @State private var listEditMode: EditMode = .inactive
    
    // Date Ribbon Refocus State
    @State private var refocusTodayToken: Int = 0
    @State private var calendarScrollTargetKey: String? = nil
    
    // Navigation & Sheet Presentation States
    @State private var selectedDetailHabitId: UUID? = nil
    @State private var timerSheetHabit: Habit? = nil
    @State private var journalSheetTarget: Habit? = nil
    @State private var editingHabitTarget: Habit? = nil
    @State private var activeRoutineBucket: TimeOfDay? = nil
    @State private var dueTasksPopupTarget: DueTasksPopupFilter? = nil
    
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
    
    private var headerDateSubtitle: String {
        let df = DateFormatter()
        df.dateFormat = "EEEE, MMM d"
        return df.string(from: activeDate).uppercased()
    }
    
    private var headerDateTitle: String {
        if isViewingToday {
            return "Today"
        }
        let df = DateFormatter()
        df.dateFormat = "E d"
        return df.string(from: activeDate)
    }
    
    private var activeDateContextName: String {
        let df = DateFormatter()
        df.dateFormat = "EEEE, MMM d"
        return df.string(from: activeDate)
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
            // Due Tasks Interactive Screen Widget Popup Sheet
            .sheet(item: $dueTasksPopupTarget) { target in
                DueTasksPopupSheet(filter: target, dateKey: activeDateKey)
                    .environmentObject(habitStore)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(24)
            }
            .onChange(of: habitStore.requestedRoutineBucket) { _, newBucket in
                if let bucket = newBucket {
                    activeRoutineBucket = bucket
                    habitStore.requestedRoutineBucket = nil
                }
            }
            .onChange(of: habitStore.requestedDueTasksPopupFilter) { _, newFilter in
                if let filter = newFilter {
                    dueTasksPopupTarget = filter
                    habitStore.requestedDueTasksPopupFilter = nil
                }
            }
            .onChange(of: habitStore.refocusTodayRequestCount) { _, _ in
                refocusToToday()
            }
            .onAppear {
                habitStore.activeViewingDateKey = activeDateKey
                habitStore.syncWidgetSnapshot(for: activeDateKey)
            }
            .onChange(of: selectedDateKey) { _, newKey in
                if let key = newKey {
                    habitStore.activeViewingDateKey = key
                    habitStore.syncWidgetSnapshot(for: key)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                refocusToToday()
                habitStore.syncWidgetSnapshot()
            }
        }
    }
    
    // MARK: - Return-to-Today Refocus Action
    
    private func refocusToToday() {
        habitStore.triggerHaptic(.medium)
        withAnimation(.spring(response: 0.40, dampingFraction: 0.82)) {
            selectedDateKey = habitStore.todayKey
            refocusTodayToken += 1
        }
    }
    
    // MARK: - Pinned Top Control Deck (Image 0 Clean Visual Parity & Zero Layout Shift)
    
    private var pinnedTopDeck: some View {
        VStack(spacing: 10) {
            // 1. Unified Navigation & Actions Header (Image 2 HTML Parity)
            HStack(alignment: .center, spacing: 8) {
                // Leading: Subtitle & Large Date Title with inline [↩ Today]
                VStack(alignment: .leading, spacing: 2) {
                    Text(headerDateSubtitle)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .tracking(0.6)
                        .lineLimit(1)
                    
                    HStack(alignment: .center, spacing: 8) {
                        Button {
                            refocusToToday()
                        } label: {
                            Text(headerDateTitle)
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.70)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .buttonStyle(.plain)
                        .layoutPriority(2)
                        
                        if !isViewingToday {
                            Button {
                                refocusToToday()
                            } label: {
                                HStack(spacing: 3.5) {
                                    Image(systemName: "arrow.uturn.backward")
                                        .font(.system(size: 10, weight: .heavy))
                                    Text("Today")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .lineLimit(1)
                                }
                                .foregroundStyle(Color(hex: "#FF7450"))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Color(hex: "#FF7450").opacity(0.14), in: Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color(hex: "#FF7450").opacity(0.35), lineWidth: 0.8)
                                )
                                .fixedSize(horizontal: true, vertical: false)
                            }
                            .buttonStyle(TactileScaleButtonStyle(pressedScale: 0.92))
                            .layoutPriority(1)
                            .transition(.scale(scale: 0.86).combined(with: .opacity))
                        }
                    }
                }
                .layoutPriority(1)
                
                Spacer(minLength: 8)
                
                // Trailing: Search Toggle + Calendar Jump + Add Habit (Snow & Three-Dots removed!)
                HStack(spacing: 8) {
                    // Search Button [🔍]
                    Button {
                        withAnimation(.snappy(duration: 0.22)) {
                            isSearchVisible.toggle()
                        }
                        habitStore.triggerHaptic(.light)
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(isSearchVisible ? Color.accentColor : Color.primary)
                            .frame(width: 36, height: 36)
                            .background(Color(.secondarySystemGroupedBackground), in: Circle())
                            .overlay(
                                Circle()
                                    .stroke(isSearchVisible ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(TactileScaleButtonStyle())
                    .accessibilityLabel("Search Habits")
                    
                    // Calendar Button [📅]
                    Button {
                        calendarPickerDate = activeDate
                        showingCalendarPopover = true
                        habitStore.triggerHaptic(.light)
                    } label: {
                        Image(systemName: "calendar")
                            .font(.system(size: 14.5, weight: .bold))
                            .foregroundStyle(Color.primary)
                            .frame(width: 36, height: 36)
                            .background(Color(.secondarySystemGroupedBackground), in: Circle())
                    }
                    .buttonStyle(TactileScaleButtonStyle())
                    .accessibilityLabel("Jump to Date")
                    
                    // Primary Add Habit Button [+]
                    Button {
                        habitStore.activeCreationStartDate = activeDate
                        showingAddSheet = true
                        habitStore.triggerHaptic(.medium)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#007AFF"), Color(hex: "#5856D6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: Circle()
                            )
                            .shadow(color: Color.accentColor.opacity(0.30), radius: 5, y: 2)
                    }
                    .buttonStyle(TactileScaleButtonStyle())
                    .accessibilityLabel("Add Habit")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            
            // 2. Contextual Yellow Alert Banner (Exact Match to Image 2 HTML)
            if !isViewingToday {
                let todayStart = Calendar.current.startOfDay(for: Date())
                let activeStart = Calendar.current.startOfDay(for: activeDate)
                let isUpcoming = activeStart > todayStart
                let statusText = isUpcoming ? "Upcoming" : "Past"
                
                HStack(alignment: .center) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.orange)
                        
                        Text("Viewing \(activeDateContextName) (\(statusText))")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#B45309"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                    
                    Spacer(minLength: 6)
                    
                    Button {
                        refocusToToday()
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 10, weight: .heavy))
                            Text("Today")
                                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                .lineLimit(1)
                        }
                        .foregroundStyle(Color(hex: "#9A3412"))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.18), in: Capsule())
                        .overlay(
                            Capsule().stroke(Color.orange.opacity(0.35), lineWidth: 0.8)
                        )
                        .fixedSize(horizontal: true, vertical: false)
                    }
                    .buttonStyle(TactileScaleButtonStyle(pressedScale: 0.92))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(hex: "#FEF3C7"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(hex: "#F59E0B").opacity(0.35), lineWidth: 0.8)
                )
                .padding(.horizontal, 16)
                .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
            }
            
            // 3. Expandable Search Bar (Revealed by [🔍] Button or Active Query)
            if isSearchVisible || !searchText.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(.secondary)
                    
                    TextField("Search habits or notes", text: $searchText)
                        .font(.system(size: 14.5, weight: .medium, design: .rounded))
                        .focused($isSearchFieldFocused)
                        .submitLabel(.search)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 13.5))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button("Done") {
                        withAnimation(.snappy) {
                            isSearchVisible = false
                            isSearchFieldFocused = false
                        }
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.accentColor)
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
                .padding(.vertical, 7)
                .background(.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                .padding(.horizontal, 16)
            }
            
            // 4. Horizontal-Only Date Ribbon inside Groupbox (Clean Days, No Empty Circles!)
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(timelineDays) { day in
                            dayRibbonPill(for: day)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                .background(
                    Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 0.8)
                )
                .padding(.horizontal, 16)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        proxy.scrollTo(habitStore.todayKey, anchor: .leading)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        proxy.scrollTo(habitStore.todayKey, anchor: .leading)
                    }
                }
                .onChange(of: refocusTodayToken) { _, _ in
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.80)) {
                        proxy.scrollTo(habitStore.todayKey, anchor: .leading)
                    }
                }
                .onChange(of: calendarScrollTargetKey) { _, targetKey in
                    guard let key = targetKey else { return }
                    withAnimation(.spring(response: 0.40, dampingFraction: 0.82)) {
                        proxy.scrollTo(key, anchor: key == habitStore.todayKey ? .leading : .center)
                    }
                    calendarScrollTargetKey = nil
                }
            }
            
            // 5. Balanced Jewel-Like Daily Focus Card
            dailyProgressCard
                .padding(.horizontal, 16)
            
            // 6. Sleek Sliding Filter Pills
            if !habitStore.activeHabits.isEmpty {
                slidingFilterBar
                    .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 10)
        .background(Color(.systemGroupedBackground))
    }
    
    private func dayRibbonPill(for day: DayModel) -> some View {
        let isSelected = (day.dateKey == activeDateKey)
        let dayPct = habitStore.completionPercentage(on: day.date, dateKey: day.dateKey)
        
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                selectedDateKey = day.dateKey
            }
            habitStore.activeViewingDateKey = day.dateKey
            habitStore.syncWidgetSnapshot(for: day.dateKey)
            habitStore.triggerHaptic(.light)
        } label: {
            VStack(spacing: 3) {
                Text(day.dayLetter)
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        isSelected ? Color.white.opacity(0.95) :
                        day.isToday ? Color.accentColor :
                        Color.secondary
                    )
                
                Text(day.dayNumber)
                    .font(.system(size: 15.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        isSelected ? Color.white :
                        day.isToday ? Color.accentColor :
                        Color.primary
                    )
                
                // Solid dot indicator only when completed habits exist (Zero empty rings!)
                ZStack {
                    if dayPct > 0 {
                        Circle()
                            .fill(isSelected ? (dayPct == 100 ? Color.green : Color.white) : (dayPct == 100 ? Color.green : Color.accentColor))
                            .frame(width: 4.5, height: 4.5)
                    } else {
                        Color.clear
                            .frame(width: 4.5, height: 4.5)
                    }
                }
                .frame(height: 5)
            }
            .frame(width: 48, height: 57)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#3D38D0"), Color(hex: "#5856D6")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(hex: "#5856D6").opacity(0.42), radius: 6, y: 3)
                        .matchedGeometryEffect(id: "selectedDayPillBG", in: dayRibbonNamespace)
                }
            }
            .overlay {
                if day.isToday && !isSelected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.accentColor.opacity(0.60), lineWidth: 1.4)
                }
            }
        }
        .buttonStyle(TactileScaleButtonStyle(pressedScale: 0.94))
        .id(day.dateKey)
    }
    
    // MARK: - Sliding Filter Bar (Clean Cupertino Segmented Design)
    
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
                    Text(opt.rawValue)
                        .font(.system(size: 13, weight: isSelected ? .bold : .semibold, design: .rounded))
                        .foregroundStyle(isSelected ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7.5)
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
                
                HStack(spacing: 10) {
                    Button {
                        habitStore.activeCreationStartDate = activeDate
                        showingAddSheet = true
                        habitStore.triggerHaptic(.medium)
                    } label: {
                        Label("Add Habit", systemImage: "plus")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            habitStore.seedRichDemoData()
                        }
                    } label: {
                        Label("Load Demo", systemImage: "sparkles")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                }
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
                                    onOpenTimer: { timerSheetHabit = habit },
                                    onEditHabit: { editingHabitTarget = habit },
                                    onLogNote: { journalSheetTarget = habit }
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
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2.5)
                                    .background(Color.secondary.opacity(0.12), in: Capsule())
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
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
    
    // MARK: - Creative Responsive Daily Progress Screen Widget
    
    private var dailyProgressCard: some View {
        let due = habitStore.habitsDue(on: activeDate)
        let doneCount = due.filter { $0.isCompleted(on: activeDateKey) || $0.isSkipped(on: activeDateKey) }.count
        let pct = habitStore.completionPercentage(on: activeDate, dateKey: activeDateKey)
        let bestActiveStreak = habitStore.activeHabits.map(\.streak).max() ?? 0
        
        return VStack(spacing: 11) {
            // 1. Top Hero Progress Row (Tapping anywhere opens full due tasks popup)
            Button {
                habitStore.triggerHaptic(.light)
                dueTasksPopupTarget = .all
            } label: {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4.5) {
                        HStack(spacing: 5) {
                            Text(
                                due.isEmpty ? "Ready to Plan" :
                                pct == 100 ? "All Goals Complete! 🎉" :
                                pct >= 60 ? "Strong Momentum 🔥" : "Daily Focus"
                            )
                            .font(.system(size: 16.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(.primary)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.accentColor.opacity(0.8))
                        }
                        
                        Text(
                            due.isEmpty ? "Tap + to schedule your first habit" :
                            doneCount == due.count ? "All \(due.count) scheduled habits done" :
                            "\(doneCount) of \(due.count) scheduled habits done"
                        )
                        .font(.system(size: 12.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        
                        // Bottom Top Streak Badge
                        HStack(spacing: 4.5) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 11, weight: .heavy))
                            Text("\(bestActiveStreak)d Top Streak")
                                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                .contentTransition(.numericText())
                        }
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3.5)
                        .background(.orange.opacity(0.15), in: Capsule())
                        .padding(.top, 2)
                    }
                    
                    Spacer(minLength: 4)
                    
                    // Main Glowing Double-Ring Progress Circle
                    ZStack {
                        Circle()
                            .stroke(Color.primary.opacity(0.08), lineWidth: 6)
                            .frame(width: 56, height: 56)
                        
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
                            .frame(width: 56, height: 56)
                            .rotationEffect(.degrees(-90))
                            .animation(.snappy(duration: 0.28), value: pct)
                            .shadow(color: (pct == 100 ? Color.green : Color.accentColor).opacity(0.35), radius: 5, y: 1.5)
                        
                        VStack(spacing: 0) {
                            Text("\(pct)%")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .contentTransition(.numericText())
                                .foregroundStyle(.primary)
                        }
                    }
                    .frame(width: 58, height: 58)
                }
            }
            .buttonStyle(TactileScaleButtonStyle(pressedScale: 0.98))
            
            // 2. Responsive Interactive Circles Orbit Strip
            if !due.isEmpty {
                Divider()
                    .opacity(0.35)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // A. Routine Bucket Circles (Morning, Afternoon, Evening, Anytime)
                        ForEach(TimeOfDay.allCases) { bucket in
                            let bucketHabits = due.filter { $0.timeOfDay == bucket }
                            if !bucketHabits.isEmpty {
                                routineCircleButton(bucket: bucket, habits: bucketHabits)
                            }
                        }
                        
                        // Subtle Vertical Divider
                        Rectangle()
                            .fill(Color.primary.opacity(0.12))
                            .frame(width: 1, height: 34)
                            .padding(.horizontal, 2)
                        
                        // B. Individual Due Habit Circle Avatars
                        ForEach(due) { habit in
                            habitCircleButton(habit: habit)
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 3)
                }
                .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 0.8)
        )
    }
    
    // MARK: - Interactive Routine Circle Button
    
    private func routineCircleButton(bucket: TimeOfDay, habits: [Habit]) -> some View {
        let doneCount = habits.filter { $0.isCompleted(on: activeDateKey) || $0.isSkipped(on: activeDateKey) }.count
        let fraction = habits.isEmpty ? 0.0 : Double(doneCount) / Double(habits.count)
        let isAllDone = doneCount == habits.count && !habits.isEmpty
        
        return Button {
            habitStore.triggerHaptic(.light)
            dueTasksPopupTarget = .routine(bucket)
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(bucket.tintColor.opacity(0.18), lineWidth: 3.5)
                        .frame(width: 42, height: 42)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(fraction))
                        .stroke(
                            isAllDone ? Color.green : bucket.tintColor,
                            style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                        )
                        .frame(width: 42, height: 42)
                        .rotationEffect(.degrees(-90))
                        .animation(.snappy, value: fraction)
                    
                    Image(systemName: isAllDone ? "checkmark" : bucket.icon)
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundStyle(isAllDone ? Color.green : bucket.tintColor)
                }
                
                Text(bucket.rawValue)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text("\(doneCount)/\(habits.count)")
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(isAllDone ? Color.green : .secondary)
            }
            .frame(width: 56)
        }
        .buttonStyle(TactileScaleButtonStyle(pressedScale: 0.90))
        .accessibilityLabel("\(bucket.rawValue) routine: \(doneCount) of \(habits.count) done")
    }
    
    // MARK: - Interactive Habit Circle Button
    
    private func habitCircleButton(habit: Habit) -> some View {
        let isDone = habit.isCompleted(on: activeDateKey)
        let isSkipped = habit.isSkipped(on: activeDateKey)
        let habitColor = Color(hex: habit.colorHex)
        let progress = habitProgressFraction(for: habit)
        
        return Button {
            habitStore.triggerHaptic(.light)
            dueTasksPopupTarget = .singleHabit(habit.id)
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(habitColor.opacity(0.18), lineWidth: 3.5)
                        .frame(width: 42, height: 42)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            isDone ? Color.green : habitColor,
                            style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                        )
                        .frame(width: 42, height: 42)
                        .rotationEffect(.degrees(-90))
                        .animation(.snappy, value: progress)
                    
                    Image(systemName: isDone ? "checkmark" : habit.icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isDone ? Color.green : habitColor)
                }
                
                Text(habit.name)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(width: 54)
                
                Text(isDone ? "Done" : isSkipped ? "Skip" : habit.repeatLabel)
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(isDone ? Color.green : isSkipped ? Color.cyan : .secondary)
                    .lineLimit(1)
            }
            .frame(width: 54)
        }
        .buttonStyle(TactileScaleButtonStyle(pressedScale: 0.90))
        .accessibilityLabel("\(habit.name): \(isDone ? "completed" : "pending")")
    }
    
    private func habitProgressFraction(for habit: Habit) -> Double {
        if habit.isCompleted(on: activeDateKey) { return 1.0 }
        if habit.isSkipped(on: activeDateKey) { return 1.0 }
        if habit.polarity == .quit { return 1.0 }
        if habit.trackingType == .amount {
            let target = habitStore.effectiveTargetAmount(for: habit, on: activeDateKey)
            guard target > 0 else { return 0.0 }
            return min(1.0, habit.amount(on: activeDateKey) / target)
        }
        if habit.trackingType == .reps {
            guard habit.targetReps > 0 else { return 0.0 }
            return min(1.0, Double(habit.reps(on: activeDateKey)) / Double(habit.targetReps))
        }
        if !habit.subtasks.isEmpty {
            let done = habit.history[activeDateKey]?.completedSubtaskIds.count ?? 0
            return Double(done) / Double(habit.subtasks.count)
        }
        return 0.0
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
