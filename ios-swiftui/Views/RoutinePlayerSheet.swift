//
//  RoutinePlayerSheet.swift
//  Productive - Guided Step-by-Step Routine Player ("Play Morning / Evening Routine")
//

import SwiftUI
import Combine

public struct RoutinePlayerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var habitStore: HabitStore
    
    public let bucket: TimeOfDay
    public let dateKey: String
    
    @State private var currentIndex: Int = 0
    @State private var localSecondsRemaining: Int = 0
    @State private var isLocalTimerRunning: Bool = false
    
    private var bucketHabits: [Habit] {
        habitStore.activeHabits.filter { $0.timeOfDay == bucket }
    }
    
    private var currentHabit: Habit? {
        guard bucketHabits.indices.contains(currentIndex) else { return nil }
        return bucketHabits[currentIndex]
    }
    
    private var completedInBucket: Int {
        bucketHabits.filter { $0.isCompleted(on: dateKey) || $0.isSkipped(on: dateKey) }.count
    }
    
    public init(bucket: TimeOfDay, dateKey: String) {
        self.bucket = bucket
        self.dateKey = dateKey
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if bucketHabits.isEmpty {
                    ContentUnavailableView(
                        "No \(bucket.rawValue) Habits",
                        systemImage: bucket.icon,
                        description: Text("Add habits to your \(bucket.rawValue.lowercased()) routine to play them step-by-step.")
                    )
                } else if currentIndex >= bucketHabits.count {
                    // Routine Finished Celebration
                    VStack(spacing: 18) {
                        Spacer()
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(bucket.tintColor)
                            .symbolEffect(.bounce, value: currentIndex)
                        
                        Text("\(bucket.rawValue) Routine Complete!")
                            .font(.system(.title2, design: .rounded).weight(.heavy))
                        
                        Text("You finished \(completedInBucket) of \(bucketHabits.count) habits in this routine.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Spacer()
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("Done")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal)
                    }
                    .padding()
                } else if let habit = currentHabit {
                    // Step Progress Strip
                    VStack(spacing: 8) {
                        HStack {
                            Label("\(bucket.rawValue) Playlist", systemImage: bucket.icon)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(bucket.tintColor)
                            Spacer()
                            Text("Step \(currentIndex + 1) of \(bucketHabits.count)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: Double(currentIndex), total: Double(max(1, bucketHabits.count)))
                            .tint(Color(hex: habit.colorHex))
                    }
                    .padding(.horizontal)
                    
                    // Active Habit Focus Card
                    VStack(spacing: 18) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color(hex: habit.colorHex))
                                .frame(width: 80, height: 80)
                                .shadow(color: Color(hex: habit.colorHex).opacity(0.35), radius: 12, y: 6)
                            Image(systemName: habit.icon)
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text(habit.name)
                                .font(.system(.title3, design: .rounded).weight(.heavy))
                                .multilineTextAlignment(.center)
                            Text(habit.summaryGoalLabel)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        // Subtasks Checklist inside Routine Step
                        if !habit.subtasks.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(habit.subtasks) { step in
                                    let done = habit.history[dateKey]?.completedSubtaskIds.contains(step.id) ?? false
                                    Button {
                                        habitStore.toggleSubtask(habitId: habit.id, subtaskId: step.id, on: dateKey)
                                    } label: {
                                        HStack {
                                            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                                                .foregroundStyle(done ? .green : .secondary)
                                            Text(step.title)
                                                .font(.subheadline)
                                                .strikethrough(done)
                                                .foregroundStyle(done ? .secondary : .primary)
                                            Spacer()
                                        }
                                        .padding(10)
                                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // Mode-specific quick control
                        if habit.trackingType == .amount {
                            let cur = Int(habit.amount(on: dateKey))
                            let tgt = Int(habitStore.effectiveTargetAmount(for: habit, on: dateKey))
                            VStack(spacing: 8) {
                                Text("\(cur) / \(tgt) \(habit.unit)")
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                    .contentTransition(.numericText())
                                Button("+\(Int(habit.stepAmount)) \(habit.unit)") {
                                    habitStore.incrementAmount(id: habit.id, step: habit.stepAmount, on: dateKey)
                                }
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.capsule)
                            }
                        } else if habit.trackingType == .timer {
                            let m = localSecondsRemaining / 60
                            let s = localSecondsRemaining % 60
                            VStack(spacing: 8) {
                                Text(String(format: "%02d:%02d", m, s))
                                    .font(.system(size: 38, weight: .heavy, design: .rounded).monospacedDigit())
                                    .contentTransition(.numericText())
                                Button(isLocalTimerRunning ? "Pause Timer" : "Start Step Timer") {
                                    isLocalTimerRunning.toggle()
                                }
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.capsule)
                            }
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Navigation & Check-in Actions
                    HStack(spacing: 12) {
                        Button {
                            habitStore.toggleSkipHabit(id: habit.id, reason: "Skipped in routine", on: dateKey)
                            advanceStep()
                        } label: {
                            Label("Skip", systemImage: "forward.end.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            if !habit.isCompleted(on: dateKey) {
                                habitStore.toggleHabit(id: habit.id, on: dateKey)
                            }
                            advanceStep()
                        } label: {
                            Label(currentIndex + 1 == bucketHabits.count ? "Complete & Finish" : "Complete & Next", systemImage: "checkmark.circle.fill")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: habit.colorHex))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("\(bucket.rawValue) Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                if let firstPending = bucketHabits.firstIndex(where: { !$0.isCompleted(on: dateKey) && !$0.isSkipped(on: dateKey) }) {
                    currentIndex = firstPending
                }
                syncStepTimer()
            }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                if isLocalTimerRunning && localSecondsRemaining > 0 {
                    localSecondsRemaining -= 1
                }
            }
        }
    }
    
    private func advanceStep() {
        isLocalTimerRunning = false
        withAnimation(.snappy) {
            currentIndex += 1
        }
        syncStepTimer()
    }
    
    private func syncStepTimer() {
        if let habit = currentHabit {
            localSecondsRemaining = max(1, habit.targetDurationMinutes) * 60
        }
    }
}
