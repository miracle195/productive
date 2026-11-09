//
//  AddHabitSheet.swift
//  Productive - Native Habit Creator & Editor Sheet
//  Supports Searchable 83 Presets, Full Edit Mode, Build/Quit/Limit Polarity,
//  Custom Weekdays, Subtask Checklists, Reminders & SF Symbol Picker
//

import SwiftUI

public struct AddHabitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var habitStore: HabitStore
    
    public var editingHabit: Habit? = nil
    public var initialStartDate: Date? = nil
    
    @State private var selectedTab = 0 // 0: Presets, 1: Builder
    @State private var selectedCategoryId: Int? = nil
    @State private var presetSearchText: String = ""
    @State private var startDate: Date = Date()
    
    // Builder Form States
    @State private var habitName: String = ""
    @State private var polarity: HabitPolarity = .build
    @State private var trackingType: HabitTrackingType = .binary
    @State private var targetAmount: Double = 2000
    @State private var unit: String = "ml"
    @State private var stepAmount: Double = 250
    @State private var targetReps: Int = 3
    @State private var targetDurationMinutes: Int = 15
    @State private var frequency: HabitFrequency = .daily
    @State private var frequencyTargetTimes: Int = 1
    @State private var customWeekdays: Set<Int> = [2, 3, 4, 5, 6]
    @State private var strictness: HabitStrictness = .strict
    @State private var selectedTimeOfDay: TimeOfDay = .morning
    @State private var selectedColorHex: String = "#007AFF"
    @State private var selectedIcon: String = "sparkles"
    
    // Subtasks & Reminders
    @State private var subtasks: [HabitSubtask] = []
    @State private var newSubtaskTitle: String = ""
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    
    let colorPalette = ["#007AFF", "#5700CB", "#0FC580", "#FF7450", "#F8BD32", "#F63566", "#923DFF", "#00B4DB"]
    let availableUnits = ["ml", "L", "glasses", "cups", "pages", "mins", "km", "steps", "times"]
    let availableIcons = [
        "sparkles", "drop.fill", "figure.run", "figure.walk",
        "figure.strengthtraining.traditional", "book.closed.fill", "moon.stars.fill", "pills.fill",
        "heart.fill", "sun.max.fill", "fork.knife", "cup.and.saucer.fill",
        "dollarsign.circle.fill", "house.fill", "hand.raised.fill", "brain.head.profile"
    ]
    let weekdayOptions: [(id: Int, label: String)] = [
        (2, "Mon"), (3, "Tue"), (4, "Wed"), (5, "Thu"), (6, "Fri"), (7, "Sat"), (1, "Sun")
    ]
    
    public init(editingHabit: Habit? = nil, initialStartDate: Date? = nil) {
        self.editingHabit = editingHabit
        self.initialStartDate = initialStartDate
    }
    
    var isEditing: Bool { editingHabit != nil }
    
    var filteredPresets: [PresetModel] {
        var list = PresetsData.presets
        if let catId = selectedCategoryId {
            list = list.filter { $0.categoryIds.contains(catId) }
        }
        if !presetSearchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = presetSearchText.lowercased()
            list = list.filter { $0.name.lowercased().contains(q) }
        }
        return list
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !isEditing {
                    Picker("Mode", selection: $selectedTab) {
                        Text("Presets (\(PresetsData.presets.count))").tag(0)
                        Text("Custom Builder").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                if selectedTab == 0 && !isEditing {
                    presetsBrowserView
                } else {
                    customBuilderForm
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(isEditing ? "Edit Habit" : "New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if selectedTab == 1 || isEditing {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(isEditing ? "Save" : "Create") {
                            saveHabitFromForm()
                        }
                        .fontWeight(.bold)
                        .disabled(habitName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .onAppear {
                if let h = editingHabit {
                    selectedTab = 1
                    habitName = h.name
                    polarity = h.polarity
                    trackingType = h.trackingType
                    targetAmount = h.targetAmount
                    unit = h.unit
                    stepAmount = h.stepAmount
                    targetReps = h.targetReps
                    targetDurationMinutes = h.targetDurationMinutes
                    frequency = h.frequency
                    frequencyTargetTimes = h.periodicTargetCount
                    customWeekdays = Set(h.customWeekdays)
                    strictness = h.strictness
                    selectedTimeOfDay = h.timeOfDay
                    selectedColorHex = h.colorHex
                    selectedIcon = h.icon
                    subtasks = h.subtasks
                    reminderEnabled = h.reminderEnabled
                    reminderTime = Calendar.current.date(bySettingHour: h.reminderHour, minute: h.reminderMinute, second: 0, of: Date()) ?? Date()
                    startDate = h.createdAt
                } else {
                    strictness = HabitStrictness(rawValue: habitStore.defaultStrictnessRaw) ?? .strict
                    startDate = initialStartDate ?? habitStore.activeCreationStartDate ?? Date()
                }
            }
        }
    }
    
    // MARK: - Tab 1: Curated Presets Browser
    
    private var presetsBrowserView: some View {
        VStack(spacing: 0) {
            // Pinned Search & Horizontal-Only Category Strip
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextField("Search 83 curated habits...", text: $presetSearchText)
                    .font(.subheadline)
                if !presetSearchText.isEmpty {
                    Button {
                        presetSearchText = ""
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
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.top, 2)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categoryChip(id: nil, title: "All", icon: "sparkles")
                    ForEach(PresetsData.categories) { cat in
                        categoryChip(id: cat.id, title: cat.name, icon: cat.icon)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            
            Divider()
                .opacity(0.45)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    HStack {
                        Text("TAP A HABIT TO CUSTOMIZE, OR TAP + ADD")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 2)
                    
                    ForEach(filteredPresets) { preset in
                        HStack(spacing: 12) {
                            Button {
                                prefillFromPreset(preset)
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                                            .fill(Color(hex: preset.colorHex))
                                            .frame(width: 38, height: 38)
                                        Image(systemName: preset.icon)
                                            .foregroundStyle(.white)
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(preset.name)
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundStyle(.primary)
                                            .multilineTextAlignment(.leading)
                                        Text("\(preset.timeOfDay.rawValue) • \(preset.trackingType.rawValue)")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            
                            Spacer(minLength: 8)
                            
                            Button {
                                let defaultStrict = HabitStrictness(rawValue: habitStore.defaultStrictnessRaw) ?? .strict
                                habitStore.addHabit(
                                    name: preset.name,
                                    icon: preset.icon,
                                    colorHex: preset.colorHex,
                                    timeOfDay: preset.timeOfDay,
                                    trackingType: preset.trackingType,
                                    targetAmount: preset.targetAmount,
                                    unit: preset.unit,
                                    stepAmount: preset.stepAmount,
                                    targetReps: preset.targetReps,
                                    targetDurationMinutes: preset.targetDurationMinutes,
                                    strictness: defaultStrict,
                                    createdAt: Calendar.current.startOfDay(for: startDate)
                                )
                                dismiss()
                            } label: {
                                Text("+ Add")
                                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Color.accentColor)
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 6.5)
                                    .background(Color.accentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 9.5, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 9.5, style: .continuous)
                                            .stroke(Color.accentColor.opacity(0.25), lineWidth: 0.8)
                                    )
                            }
                            .buttonStyle(TactileScaleButtonStyle(pressedScale: 0.92))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Color(.secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.primary.opacity(0.05), lineWidth: 0.8)
                        )
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }
    
    private func categoryChip(id: Int?, title: String, icon: String) -> some View {
        let isSelected = (selectedCategoryId == id)
        return Button {
            selectedCategoryId = id
            habitStore.triggerHaptic(.light)
        } label: {
            Label(title, systemImage: icon)
                .font(.caption.weight(.bold))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color(.secondarySystemGroupedBackground)),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Tab 2: Native Form Builder
    
    private var customBuilderForm: some View {
        Form {
            Section(header: Text("Goal Type & Name")) {
                TextField("Habit Name (e.g. Drink 2L Water, Zero Sugar)", text: $habitName)
                    .font(.body.weight(.medium))
                
                Picker("Habit Polarity", selection: $polarity) {
                    ForEach(HabitPolarity.allCases) { pol in
                        Label(pol.rawValue, systemImage: pol.icon).tag(pol)
                    }
                }
                
                if polarity == .build {
                    Picker("Tracking Mode", selection: $trackingType) {
                        ForEach(HabitTrackingType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                }
            }
            
            // Target Configuration
            if polarity == .limit || (polarity == .build && trackingType == .amount) {
                Section(header: Text(polarity == .limit ? "Daily Maximum Cap" : "Daily Target & Unit")) {
                    HStack {
                        Text(polarity == .limit ? "Stay At or Under" : "Daily Target")
                        Spacer()
                        TextField("Target", value: $targetAmount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("Unit", selection: $unit) {
                        ForEach(availableUnits, id: \.self) { u in
                            Text(u).tag(u)
                        }
                    }
                    
                    HStack {
                        Text("Quick Increment Step")
                        Spacer()
                        TextField("Step", value: $stepAmount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            } else if polarity == .build && trackingType == .reps {
                Section(header: Text("Repetitions")) {
                    Stepper("Target: \(targetReps) reps / day", value: $targetReps, in: 1...50)
                }
            } else if polarity == .build && trackingType == .timer {
                Section(header: Text("Focus Timer Duration")) {
                    Stepper("Duration: \(targetDurationMinutes) mins", value: $targetDurationMinutes, in: 1...180, step: 5)
                }
            }
            
            // Schedule, Custom Days & Strictness
            Section(header: Text("Schedule & Streak Rules")) {
                DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])
                
                Picker("Frequency", selection: $frequency) {
                    Section("Daily & Standard") {
                        Text(HabitFrequency.daily.rawValue).tag(HabitFrequency.daily)
                        Text(HabitFrequency.weekdays.rawValue).tag(HabitFrequency.weekdays)
                        Text(HabitFrequency.weekends.rawValue).tag(HabitFrequency.weekends)
                        Text(HabitFrequency.every2Days.rawValue).tag(HabitFrequency.every2Days)
                        Text(HabitFrequency.every3Days.rawValue).tag(HabitFrequency.every3Days)
                        Text(HabitFrequency.customDays.rawValue).tag(HabitFrequency.customDays)
                    }
                    
                    Section("Weekly (Spread across week)") {
                        Text(HabitFrequency.oncePerWeek.rawValue).tag(HabitFrequency.oncePerWeek)
                        Text(HabitFrequency.twicePerWeek.rawValue).tag(HabitFrequency.twicePerWeek)
                        Text(HabitFrequency.threePerWeek.rawValue).tag(HabitFrequency.threePerWeek)
                        Text(HabitFrequency.fourPerWeek.rawValue).tag(HabitFrequency.fourPerWeek)
                        Text(HabitFrequency.fivePerWeek.rawValue).tag(HabitFrequency.fivePerWeek)
                        Text(HabitFrequency.customTimesPerWeek.rawValue).tag(HabitFrequency.customTimesPerWeek)
                    }
                    
                    Section("Monthly (Spread across month)") {
                        Text(HabitFrequency.oncePerMonth.rawValue).tag(HabitFrequency.oncePerMonth)
                        Text(HabitFrequency.twicePerMonth.rawValue).tag(HabitFrequency.twicePerMonth)
                        Text(HabitFrequency.thricePerMonth.rawValue).tag(HabitFrequency.thricePerMonth)
                        Text(HabitFrequency.fourPerMonth.rawValue).tag(HabitFrequency.fourPerMonth)
                        Text(HabitFrequency.customTimesPerMonth.rawValue).tag(HabitFrequency.customTimesPerMonth)
                    }
                }
                
                if frequency == .customTimesPerWeek {
                    Stepper("Target: \(frequencyTargetTimes) times / week", value: $frequencyTargetTimes, in: 1...6)
                } else if frequency == .customTimesPerMonth {
                    Stepper("Target: \(frequencyTargetTimes) times / month", value: $frequencyTargetTimes, in: 1...28)
                }
                
                if frequency.isPeriodic {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundStyle(.tint)
                        Text("Flexible schedule: complete on any day(s) during the \(frequency.isWeeklyPeriodic ? "week" : "month") to reach your goal.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if frequency == .customDays {
                    HStack(spacing: 6) {
                        ForEach(weekdayOptions, id: \.id) { day in
                            let on = customWeekdays.contains(day.id)
                            Button {
                                if on && customWeekdays.count > 1 {
                                    customWeekdays.remove(day.id)
                                } else {
                                    customWeekdays.insert(day.id)
                                }
                            } label: {
                                Text(String(day.label.prefix(1)))
                                    .font(.caption.weight(.bold))
                                    .frame(maxWidth: .infinity, minHeight: 32)
                                    .background(on ? Color.accentColor : Color(.tertiarySystemGroupedBackground), in: Circle())
                                    .foregroundStyle(on ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Picker("Time of Day", selection: $selectedTimeOfDay) {
                    ForEach(TimeOfDay.allCases) { t in
                        Label(t.rawValue, systemImage: t.icon).tag(t)
                    }
                }
                
                Picker("Strictness", selection: $strictness) {
                    ForEach(HabitStrictness.allCases) { st in
                        Label(st.badgeText, systemImage: st.symbolName).tag(st)
                    }
                }
            }
            
            // Sub-Checklist Builder
            Section(
                header: Text("Sub-Checklist Steps (Optional)"),
                footer: Text("Checking off all sub-steps automatically marks the habit complete.")
            ) {
                ForEach(subtasks) { step in
                    HStack {
                        Image(systemName: "checkmark.square")
                            .foregroundStyle(.secondary)
                        Text(step.title)
                        Spacer()
                        Button(role: .destructive) {
                            subtasks.removeAll { $0.id == step.id }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                
                HStack {
                    TextField("Add step (e.g. Cleanser, Floss...)", text: $newSubtaskTitle)
                    Button("Add") {
                        let clean = newSubtaskTitle.trimmingCharacters(in: .whitespaces)
                        guard !clean.isEmpty else { return }
                        subtasks.append(HabitSubtask(title: clean))
                        newSubtaskTitle = ""
                    }
                    .disabled(newSubtaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            
            // Smart Reminder Notification
            Section(header: Text("Local Notification Reminder")) {
                Toggle("Daily Reminder", isOn: $reminderEnabled)
                if reminderEnabled {
                    DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }
            }
            
            // Color & Icon Appearance
            Section(header: Text("Icon & Accent Color")) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(colorPalette, id: \.self) { hex in
                            Button {
                                selectedColorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.white)
                                            .opacity(selectedColorHex == hex ? 1 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                    ForEach(availableIcons, id: \.self) { icon in
                        let chosen = (selectedIcon == icon)
                        Button {
                            selectedIcon = icon
                        } label: {
                            Image(systemName: icon)
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 34, height: 34)
                                .background(
                                    chosen ? Color(hex: selectedColorHex) : Color(.tertiarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                                )
                                .foregroundStyle(chosen ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listSectionSpacing(12)
        .contentMargins(.top, 6, for: .scrollContent)
    }
    
    // MARK: - Helpers
    
    private func prefillFromPreset(_ preset: PresetModel) {
        habitName = preset.name
        selectedIcon = preset.icon
        selectedColorHex = preset.colorHex
        selectedTimeOfDay = preset.timeOfDay
        trackingType = preset.trackingType
        targetAmount = preset.targetAmount
        unit = preset.unit
        stepAmount = preset.stepAmount
        targetReps = preset.targetReps
        targetDurationMinutes = preset.targetDurationMinutes
        if preset.name.lowercased().contains("zero ") || preset.name.lowercased().contains("avoid ") || preset.name.lowercased().contains("no ") {
            polarity = .quit
        } else if preset.name.lowercased().contains("limit ") {
            polarity = .limit
        } else {
            polarity = .build
        }
        selectedTab = 1
        habitStore.triggerHaptic(.light)
    }
    
    private func saveHabitFromForm() {
        let cleanName = habitName.trimmingCharacters(in: .whitespaces)
        guard !cleanName.isEmpty else { return }
        
        let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let rHour = comps.hour ?? 9
        let rMin = comps.minute ?? 0
        let effectiveType: HabitTrackingType = polarity == .limit ? .amount : (polarity == .quit ? .binary : trackingType)
        let effectiveTargetTimes = frequency.isPeriodic ? (frequency == .customTimesPerWeek || frequency == .customTimesPerMonth ? frequencyTargetTimes : frequency.defaultTargetCount) : 1
        
        if var existing = editingHabit {
            existing.name = cleanName
            existing.polarity = polarity
            existing.trackingType = effectiveType
            existing.targetAmount = targetAmount
            existing.unit = unit
            existing.stepAmount = stepAmount
            existing.targetReps = targetReps
            existing.targetDurationMinutes = targetDurationMinutes
            existing.frequency = frequency
            existing.frequencyTargetTimes = effectiveTargetTimes
            existing.customWeekdays = Array(customWeekdays).sorted()
            existing.repeatSchedule = existing.repeatLabel
            existing.strictness = strictness
            existing.timeOfDay = selectedTimeOfDay
            existing.colorHex = selectedColorHex
            existing.icon = selectedIcon
            existing.subtasks = subtasks
            existing.reminderEnabled = reminderEnabled
            existing.reminderHour = rHour
            existing.reminderMinute = rMin
            habitStore.updateHabit(existing)
        } else {
            habitStore.addHabit(
                name: cleanName,
                icon: selectedIcon,
                colorHex: selectedColorHex,
                timeOfDay: selectedTimeOfDay,
                polarity: polarity,
                trackingType: effectiveType,
                targetAmount: targetAmount,
                unit: unit,
                stepAmount: stepAmount,
                targetReps: targetReps,
                targetDurationMinutes: targetDurationMinutes,
                frequency: frequency,
                frequencyTargetTimes: effectiveTargetTimes,
                customWeekdays: Array(customWeekdays).sorted(),
                strictness: strictness,
                repeatSchedule: frequency.rawValue,
                subtasks: subtasks,
                reminderEnabled: reminderEnabled,
                reminderHour: rHour,
                reminderMinute: rMin,
                createdAt: Calendar.current.startOfDay(for: startDate)
            )
        }
        dismiss()
    }
}
