//
//  AddHabitSheet.swift
//  Cupertino Bottom Sheet for Presets and Custom Multi-Mode Habit Builder
//  Includes all 14 Curated Categories, 83 Native Presets, and Deep Customization
//

import SwiftUI

public struct AddHabitSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var habitStore: HabitStore
    
    @State private var selectedTab = 0 // 0: Presets, 1: Custom Builder
    @State private var selectedCategoryId: Int? = nil // nil = All Categories
    
    // Custom Builder States
    @State private var habitName: String = ""
    @State private var trackingType: HabitTrackingType = .binary
    @State private var targetAmount: Double = 2000
    @State private var unit: String = "ml"
    @State private var stepAmount: Double = 250
    @State private var targetReps: Int = 3
    @State private var targetDurationMinutes: Int = 15
    @State private var frequency: HabitFrequency = .daily
    @State private var strictness: HabitStrictness = .strict
    @State private var selectedTimeOfDay: TimeOfDay = .morning
    @State private var selectedColorHex: String = "#5700CB"
    @State private var selectedIcon: String = "sparkles"
    
    let colorPalette = ["#5700CB", "#0062E4", "#0FC580", "#FF7450", "#F8BD32", "#F63566", "#923DFF", "#234AD9"]
    let availableUnits = ["ml", "L", "glasses", "cups", "pages", "mins", "km", "steps"]
    let availableIcons = ["sparkles", "drop.fill", "figure.run", "figure.walk", "figure.strengthtraining.traditional", "book.closed.fill", "moon.fill", "pill.fill", "heart.fill", "sun.max.fill", "fork.knife", "cup.and.saucer.fill", "dollarsign.circle.fill", "house.fill"]
    
    var filteredPresets: [PresetModel] {
        if let catId = selectedCategoryId {
            return PresetsData.presets.filter { $0.categoryIds.contains(catId) }
        }
        return PresetsData.presets
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Switcher
                Picker("Creation Mode", selection: $selectedTab) {
                    Text("✨ Presets (\(PresetsData.presets.count))").tag(0)
                    Text("🛠️ Custom Builder").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                if selectedTab == 0 {
                    // TAB 1: PRESETS EXPLORER WITH CATEGORY FILTER
                    VStack(spacing: 0) {
                        // Category Selector Chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                // "All" Chip
                                Button {
                                    selectedCategoryId = nil
                                    habitStore.triggerHaptic(.light)
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 11))
                                        Text("All (\(PresetsData.presets.count))")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(selectedCategoryId == nil ?
                                                LinearGradient(colors: [Color(hex: "#5700CB"), Color(hex: "#0062E4")], startPoint: .leading, endPoint: .trailing) :
                                                LinearGradient(colors: [Color.white.opacity(0.08)], startPoint: .top, endPoint: .bottom))
                                    .foregroundColor(selectedCategoryId == nil ? .white : .secondary)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedCategoryId == nil ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
                                    )
                                }
                                
                                ForEach(PresetsData.categories) { cat in
                                    let isSelected = (selectedCategoryId == cat.id)
                                    let count = PresetsData.presets.filter { $0.categoryIds.contains(cat.id) }.count
                                    Button {
                                        selectedCategoryId = cat.id
                                        habitStore.triggerHaptic(.light)
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: cat.icon)
                                                .font(.system(size: 11))
                                            Text("\(cat.name) (\(count))")
                                                .font(.system(size: 12, weight: .bold))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(isSelected ?
                                                    LinearGradient(colors: [Color(hex: "#5700CB"), Color(hex: "#0062E4")], startPoint: .leading, endPoint: .trailing) :
                                                    LinearGradient(colors: [Color.white.opacity(0.08)], startPoint: .top, endPoint: .bottom))
                                        .foregroundColor(isSelected ? .white : .secondary)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                        }
                        .background(Color(.secondarySystemBackground).opacity(0.5))
                        
                        // Presets List
                        List {
                            Section(header: Text("TAP TO CUSTOMIZE • OR USE + ADD TO QUICK-LOG").font(.system(size: 11, weight: .bold))) {
                                ForEach(filteredPresets) { preset in
                                    HStack(spacing: 12) {
                                        // Card body: Tap to customize configuration
                                        HStack(spacing: 12) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color(hex: preset.colorHex))
                                                    .frame(width: 36, height: 36)
                                                Image(systemName: preset.icon)
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 16))
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(preset.name)
                                                    .font(.system(size: 15, weight: .bold))
                                                    .foregroundColor(.primary)
                                                
                                                HStack(spacing: 6) {
                                                    Text(preset.timeOfDay.rawValue)
                                                        .font(.system(size: 11))
                                                        .foregroundColor(.secondary)
                                                    Text("•")
                                                        .foregroundColor(.secondary)
                                                    Text(preset.trackingType.rawValue)
                                                        .font(.system(size: 11, weight: .semibold))
                                                        .foregroundColor(Color(hex: "#007AFF"))
                                                    
                                                    if preset.trackingType == .amount {
                                                        Text("(\(Int(preset.targetAmount)) \(preset.unit))")
                                                            .font(.system(size: 10))
                                                            .foregroundColor(.secondary)
                                                    } else if preset.trackingType == .reps {
                                                        Text("(\(preset.targetReps)x)")
                                                            .font(.system(size: 10))
                                                            .foregroundColor(.secondary)
                                                    } else if preset.trackingType == .timer {
                                                        Text("(\(preset.targetDurationMinutes)m)")
                                                            .font(.system(size: 10))
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                            }
                                        }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            // Pre-fill Custom Builder with preset configuration
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
                                            selectedTab = 1 // Switch to Custom Builder
                                            habitStore.triggerHaptic(.light)
                                        }
                                        
                                        Spacer()
                                        
                                        // Direct Add Button
                                        Button {
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
                                                targetDurationMinutes: preset.targetDurationMinutes
                                            )
                                            dismiss()
                                        } label: {
                                            Text("+ Add")
                                                .font(.system(size: 12, weight: .bold))
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(Color(hex: "#007AFF"))
                                                .foregroundColor(.white)
                                                .cornerRadius(10)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.vertical, 3)
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                } else {
                    // TAB 2: CUSTOM HABIT BUILDER
                    Form {
                        Section(header: Text("HABIT DETAILS")) {
                            TextField("Habit Name (e.g. Drink 2L Water)", text: $habitName)
                            
                            Picker("Tracking Type", selection: $trackingType) {
                                ForEach(HabitTrackingType.allCases) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                        }
                        
                        // Mode Specific Settings
                        if trackingType == .amount {
                            Section(header: Text("AMOUNT TARGET & UNIT")) {
                                HStack {
                                    Text("Daily Target")
                                    Spacer()
                                    TextField("Amount", value: $targetAmount, format: .number)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                }
                                
                                Picker("Unit", selection: $unit) {
                                    ForEach(availableUnits, id: \.self) { u in
                                        Text(u).tag(u)
                                    }
                                }
                                
                                HStack {
                                    Text("Quick Step Increment")
                                    Spacer()
                                    TextField("Step", value: $stepAmount, format: .number)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                        } else if trackingType == .reps {
                            Section(header: Text("REPETITIONS PER DAY")) {
                                HStack(spacing: 14) {
                                    Button(action: {
                                        if targetReps > 1 {
                                            targetReps -= 1
                                            habitStore.triggerHaptic(.light)
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(Color(hex: "#007AFF"))
                                    }
                                    .buttonStyle(.borderless)
                                    
                                    TextField("Reps", value: $targetReps, format: .number)
                                        .font(.system(size: 18, weight: .bold))
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 60)
                                        .padding(.vertical, 6)
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(8)
                                    
                                    Button(action: {
                                        if targetReps < 99 {
                                            targetReps += 1
                                            habitStore.triggerHaptic(.light)
                                        }
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(Color(hex: "#007AFF"))
                                    }
                                    .buttonStyle(.borderless)
                                    
                                    Spacer()
                                    
                                    Text("\(targetReps) times / day")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        } else if trackingType == .timer {
                            Section(header: Text("TIMER DURATION")) {
                                Picker("Target Duration", selection: $targetDurationMinutes) {
                                    Text("5 mins").tag(5)
                                    Text("10 mins").tag(10)
                                    Text("15 mins").tag(15)
                                    Text("20 mins").tag(20)
                                    Text("30 mins").tag(30)
                                    Text("45 mins").tag(45)
                                    Text("60 mins").tag(60)
                                }
                            }
                        }
                        
                        // Recurrence & Strictness
                        Section(header: Text("RECURRENCE & EXPIRATION RULES")) {
                            Picker("How Often", selection: $frequency) {
                                ForEach(HabitFrequency.allCases) { freq in
                                    Text(freq.rawValue).tag(freq)
                                }
                            }
                            
                            Picker("Strictness Mode", selection: $strictness) {
                                ForEach(HabitStrictness.allCases) { st in
                                    Text(st.rawValue).tag(st)
                                }
                            }
                            
                            if strictness == .strict {
                                Text("⚡ Fatal: If the day passes without logging, streak breaks and retroactive logging is locked.")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "#FF5A5F"))
                            } else if strictness == .flexible {
                                Text("🛡️ Flexible: Allows backfilling missed days within grace period.")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "#0FC580"))
                            } else {
                                Text("🔄 Rollover: Uncompleted quota rolls over to the next day.")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "#923DFF"))
                            }
                        }
                        
                        // Time of Day & Appearance
                        Section(header: Text("TIME & APPEARANCE")) {
                            Picker("Time of Day", selection: $selectedTimeOfDay) {
                                ForEach(TimeOfDay.allCases) { time in
                                    Text(time.rawValue).tag(time)
                                }
                            }
                            
                            HStack {
                                Text("Color Accent")
                                Spacer()
                                ForEach(colorPalette, id: \.self) { hex in
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 26, height: 26)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColorHex == hex ? 2.5 : 0)
                                        )
                                        .onTapGesture {
                                            selectedColorHex = hex
                                            habitStore.triggerHaptic(.light)
                                        }
                                }
                            }
                            
                            HStack {
                                Text("Icon Symbol")
                                Spacer()
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(availableIcons, id: \.self) { icon in
                                            ZStack {
                                                Circle()
                                                    .fill(selectedIcon == icon ? Color(hex: selectedColorHex) : Color.white.opacity(0.1))
                                                    .frame(width: 32, height: 32)
                                                Image(systemName: icon)
                                                    .font(.system(size: 14))
                                                    .foregroundColor(selectedIcon == icon ? .white : .secondary)
                                            }
                                            .onTapGesture {
                                                selectedIcon = icon
                                                habitStore.triggerHaptic(.light)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Submit Button
                        Section {
                            Button {
                                guard !habitName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                                habitStore.addHabit(
                                    name: habitName,
                                    icon: selectedIcon,
                                    colorHex: selectedColorHex,
                                    timeOfDay: selectedTimeOfDay,
                                    trackingType: trackingType,
                                    targetAmount: targetAmount,
                                    unit: unit,
                                    stepAmount: stepAmount,
                                    targetReps: targetReps,
                                    targetDurationMinutes: targetDurationMinutes,
                                    frequency: frequency,
                                    strictness: strictness,
                                    repeatSchedule: frequency.rawValue
                                )
                                dismiss()
                            } label: {
                                Text("Create Habit")
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(hex: "#5700CB"))
                        }
                    }
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
