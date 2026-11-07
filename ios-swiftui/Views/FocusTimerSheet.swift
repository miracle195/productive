//
//  FocusTimerSheet.swift
//  Productive - Real Interactive Focus Session, Pomodoro & Stopwatch Sheet
//  Includes JournalEntrySheet for Mood Tags & Daily Reflection Notes
//

import SwiftUI

public struct FocusTimerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var habitStore: HabitStore
    public let habit: Habit
    
    private var progressFraction: Double {
        if habitStore.timerMode == .stopwatch {
            let target = Double(max(60, habit.targetDurationMinutes * 60))
            return min(1.0, Double(habitStore.timerElapsedSeconds) / target)
        } else {
            let total = Double(max(1, habitStore.timerTotalSeconds))
            let done = Double(max(0, habitStore.timerTotalSeconds - habitStore.timerRemainingSeconds))
            return min(1.0, done / total)
        }
    }
    
    private var formattedPrimaryTime: String {
        let secs = habitStore.timerMode == .stopwatch ? habitStore.timerElapsedSeconds : habitStore.timerRemainingSeconds
        let m = secs / 60
        let s = secs % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    public init(habit: Habit) {
        self.habit = habit
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Mode Picker
                Picker("Timer Mode", selection: Binding(
                    get: { habitStore.timerMode },
                    set: { habitStore.setTimerMode($0, for: habit) }
                )) {
                    ForEach(FocusTimerMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                Spacer(minLength: 4)
                
                // Apple Fitness-Style Circular Timer Dial
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.08), lineWidth: 14)
                        .frame(width: 230, height: 230)
                    
                    Circle()
                        .trim(from: 0, to: progressFraction)
                        .stroke(
                            Color(hex: habit.colorHex),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .frame(width: 230, height: 230)
                        .rotationEffect(.degrees(-90))
                        .animation(.smooth(duration: 0.4), value: progressFraction)
                    
                    VStack(spacing: 6) {
                        Image(systemName: habit.icon)
                            .font(.title2)
                            .foregroundStyle(Color(hex: habit.colorHex))
                            .symbolEffect(.bounce, value: habitStore.isTimerRunning)
                        
                        Text(formattedPrimaryTime)
                            .font(.system(size: 48, weight: .heavy, design: .rounded).monospacedDigit())
                            .contentTransition(.numericText())
                            .foregroundStyle(.primary)
                        
                        Text(habitStore.isTimerRunning ? "Live in Dynamic Island" : "Ready to Focus")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Quick Time Adjusters
                if habitStore.timerMode != .stopwatch {
                    HStack(spacing: 12) {
                        Button {
                            habitStore.adjustTimer(bySeconds: -60)
                        } label: {
                            Label("1m", systemImage: "minus")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        
                        Button {
                            habitStore.adjustTimer(bySeconds: 5 * 60)
                        } label: {
                            Label("5m", systemImage: "plus")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                    }
                }
                
                Spacer(minLength: 4)
                
                // Primary Playback Controls
                HStack(spacing: 16) {
                    Button(role: .destructive) {
                        habitStore.stopTimer()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .frame(width: 52, height: 52)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    
                    Button {
                        if habitStore.isTimerRunning {
                            habitStore.pauseTimer()
                        } else {
                            habitStore.startOrResumeTimer(for: habit)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: habitStore.isTimerRunning ? "pause.fill" : "play.fill")
                            Text(habitStore.isTimerRunning ? "Pause" : "Start Focus")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: habit.colorHex))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    Button {
                        habitStore.completeTimerSession()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.headline)
                            .frame(width: 52, height: 52)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel("Complete Session Now")
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            .padding(.top, 8)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(habit.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Minimize") { dismiss() }
                }
            }
            .onAppear {
                habitStore.prepareTimer(for: habit)
            }
        }
    }
}

// MARK: - Mood & Reflection Journal Sheet

public struct JournalEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var habitStore: HabitStore
    
    public let habit: Habit
    public let dateKey: String
    
    @State private var noteText: String = ""
    @State private var selectedMood: HabitMood? = nil
    
    public init(habit: Habit, dateKey: String) {
        self.habit = habit
        self.dateKey = dateKey
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("How did it feel?")) {
                    HStack(spacing: 10) {
                        ForEach(HabitMood.allCases) { mood in
                            let isSelected = (selectedMood == mood)
                            Button {
                                selectedMood = (isSelected ? nil : mood)
                                habitStore.triggerHaptic(.light)
                            } label: {
                                VStack(spacing: 4) {
                                    Text(mood.emoji)
                                        .font(.title2)
                                    Text(mood.rawValue)
                                        .font(.caption2.weight(.semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    isSelected ? Color.accentColor.opacity(0.18) : Color(.tertiarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Reflection Note (\(dateKey))")) {
                    TextField("What helped or got in the way today?", text: $noteText, axis: .vertical)
                        .lineLimit(4...8)
                }
            }
            .navigationTitle("Reflection Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        habitStore.saveJournalEntry(habitId: habit.id, dateKey: dateKey, note: noteText, mood: selectedMood)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                noteText = habit.note(on: dateKey)
                selectedMood = habit.mood(on: dateKey)
            }
        }
    }
}

