//
//  AddHabitSheet.swift
//  Cupertino Bottom Sheet for Presets and Custom Multi-Mode Habit Builder
//

import SwiftUI

public struct AddHabitSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var habitStore: HabitStore
    
    @State private var selectedTab = 0 // 0: Presets, 1: Custom Builder
    
    // Custom Builder States
    @State private var habitName: String = ""
    @State private var trackingType: HabitTrackingType = .binary
    @State private var targetAmount: Double = 2000
    @State private var unit: String = "ml"
    @State private var stepAmount: Double = 250
    @State private var targetReps: Int = 3
    @State private var frequency: HabitFrequency = .daily
    @State private var strictness: HabitStrictness = .strict
    @State private var selectedTimeOfDay: TimeOfDay = .morning
    @State private var selectedColorHex: String = "#5700CB"
    @State private var selectedIcon: String = "drop.fill"
    
    let colorPalette = ["#5700CB", "#0062E4", "#0FC580", "#FF7450", "#F8BD32", "#F63566"]
    let availableUnits = ["ml", "L", "glasses", "cups", "pages", "mins", "km"]
    let repOptions = [2, 3, 4, 5, 10]
    
    let popularPresets: [(String, String, String, TimeOfDay, HabitTrackingType, Double, String, Int)] = [
        ("Drink water (2L)", "drop.fill", "#1B8FFF", .morning, .amount, 2000, "ml", 1),
        ("Workout at gym", "figure.strengthtraining.traditional", "#923DFF", .afternoon, .binary, 0, "", 1),
        ("Eat fruits & veggies", "leaf.fill", "#0FC580", .afternoon, .reps, 0, "", 3),
        ("Read before bed", "book.closed.fill", "#FF7450", .evening, .amount, 20, "pages", 1),
        ("Sleep by 11 PM", "moon.fill", "#4C00B2", .evening, .binary, 0, "", 1),
        ("Take vitamins", "pill.fill", "#F8BD32", .anytime, .reps, 0, "", 2),
        ("Brisk walk", "figure.walk", "#0FC580", .afternoon, .amount, 30, "mins", 1),
        ("Mindful meditation", "sparkles", "#FF7450", .evening, .binary, 0, "", 1)
    ]
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Switcher
                Picker("Creation Mode", selection: $selectedTab) {
                    Text("✨ Popular Presets").tag(0)
                    Text("🛠️ Custom Builder").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                if selectedTab == 0 {
                    // TAB 1: PRESETS LIST
                    List {
                        Section(header: Text("CURATED PRESETS").font(.system(size: 11, weight: .bold))) {
                            ForEach(popularPresets, id: \.0) { preset in
                                HStack(spacing: 14) {
                                    // Item area: Tap to open and customize configuration
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color(hex: preset.2))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: preset.1)
                                                .foregroundColor(.white)
                                                .font(.system(size: 16))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(preset.0)
                                                .font(.system(size: 15, weight: .bold))
                                            HStack(spacing: 6) {
                                                Text(preset.3.rawValue)
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.secondary)
                                                Text("•")
                                                    .foregroundColor(.secondary)
                                                Text(preset.4.rawValue)
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundColor(Color(hex: "#007AFF"))
                                            }
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        // Open item to customize configuration
                                        habitName = preset.0
                                        selectedIcon = preset.1
                                        selectedColorHex = preset.2
                                        selectedTimeOfDay = preset.3
                                        trackingType = preset.4
                                        targetAmount = preset.5 > 0 ? preset.5 : 2000
                                        unit = !preset.6.isEmpty ? preset.6 : "ml"
                                        targetReps = preset.7 > 0 ? preset.7 : 3
                                        selectedTab = 1 // Switch to Custom Habit Builder tab
                                        habitStore.triggerHaptic(.light)
                                    }
                                    
                                    Spacer()
                                    
                                    // Direct Add button
                                    Button("+ Add") {
                                        habitStore.addHabit(
                                            name: preset.0,
                                            icon: preset.1,
                                            colorHex: preset.2,
                                            timeOfDay: preset.3,
                                            trackingType: preset.4,
                                            targetAmount: preset.5,
                                            unit: preset.6,
                                            targetReps: preset.7
                                        )
                                        dismiss()
                                    }
                                    .font(.system(size: 13, weight: .bold))
                                    .buttonStyle(.borderedProminent)
                                    .tint(Color(hex: "#007AFF"))
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                } else {
                    // TAB 2: CUSTOM HABIT BUILDER
                    Form {
                        Section(header: Text("HABIT DETAILS")) {
                            TextField("Habit Name (e.g. Drink 2.5L Water)", text: $habitName)
                            
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
                                HStack(spacing: 12) {
                                    Button(action: {
                                        if targetReps > 1 { targetReps -= 1 }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 26))
                                            .foregroundColor(.blue)
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
                                        if targetReps < 99 { targetReps += 1 }
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 26))
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(.borderless)
                                    
                                    Spacer()
                                    
                                    Text("\(targetReps) times / day")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
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
                        
                        // Time of Day & Accent Color
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
                                    icon: trackingType == .amount ? "drop.fill" : (trackingType == .reps ? "number.circle.fill" : "sparkles"),
                                    colorHex: selectedColorHex,
                                    timeOfDay: selectedTimeOfDay,
                                    trackingType: trackingType,
                                    targetAmount: targetAmount,
                                    unit: unit,
                                    stepAmount: stepAmount,
                                    targetReps: targetReps,
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
