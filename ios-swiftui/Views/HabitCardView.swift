//
//  HabitCardView.swift
//  Productive - Semantic Cupertino Habit Row Component
//  Supports SF Symbol Bounce, Numeric Rolling Counters, Subtasks, Rollover Quotas,
//  Quit Abstinence Counters, Daily Limit Gauges, Reps Steppers & Focus Timer Trigger
//

import SwiftUI

public struct HabitCardView: View {
    @EnvironmentObject var habitStore: HabitStore
    public let habit: Habit
    public var dateKey: String = ""
    public var onOpenTimer: (() -> Void)? = nil
    
    private var activeDateKey: String {
        dateKey.isEmpty ? habitStore.todayKey : dateKey
    }
    
    private var isCompleted: Bool {
        habit.isCompleted(on: activeDateKey)
    }
    
    private var isSkipped: Bool {
        habit.isSkipped(on: activeDateKey)
    }
    
    private var isLockedMissed: Bool {
        habitStore.isLockedByStrictMode(habit, on: activeDateKey)
    }
    
    private var currentAmount: Double {
        habit.amount(on: activeDateKey)
    }
    
    private var effectiveTarget: Double {
        habitStore.effectiveTargetAmount(for: habit, on: activeDateKey)
    }
    
    private var rolloverExtra: Double {
        habitStore.rolloverBonus(for: habit, on: activeDateKey)
    }
    
    private var currentReps: Int {
        habit.reps(on: activeDateKey)
    }
    
    public init(habit: Habit, dateKey: String = "", onOpenTimer: (() -> Void)? = nil) {
        self.habit = habit
        self.dateKey = dateKey
        self.onOpenTimer = onOpenTimer
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top Row: Icon, Name & Metadata, Primary Action Control
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(hex: habit.colorHex))
                        .frame(width: 42, height: 42)
                    
                    Image(systemName: habit.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, value: isCompleted)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(habit.name)
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .foregroundStyle(isCompleted || isSkipped ? .secondary : .primary)
                            .strikethrough(isCompleted && habit.polarity == .build)
                            .lineLimit(1)
                        
                        if let mood = habit.mood(on: activeDateKey) {
                            Text(mood.emoji)
                                .font(.caption)
                        }
                        if !habit.note(on: activeDateKey).isEmpty {
                            Image(systemName: "note.text")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Metadata Pills
                    HStack(spacing: 6) {
                        if habit.polarity == .quit {
                            Label("Quit", systemImage: "hand.raised.fill")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.pink)
                        } else if habit.polarity == .limit {
                            Label("Max \(Int(habit.targetAmount)) \(habit.unit)", systemImage: "gauge.with.dots.needle.33percent")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.purple)
                        } else {
                            Text(habit.frequency.rawValue)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        
                        if isSkipped {
                            Label(habit.history[activeDateKey]?.usedFreezeShield == true ? "Frozen" : "Skipped", systemImage: "snowflake")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.cyan)
                        } else if rolloverExtra > 0 {
                            Label("+\(Int(rolloverExtra)) rollover", systemImage: "arrow.triangle.2.circlepath")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.purple)
                        }
                        
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                            Text("\(habit.streak)d")
                                .contentTransition(.numericText())
                        }
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.orange)
                    }
                }
                
                Spacer(minLength: 4)
                
                // Trailing Checkmark / Lock / Shield Action
                if isLockedMissed {
                    Image(systemName: "lock.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .frame(width: 34, height: 34)
                        .background(.red.opacity(0.12), in: Circle())
                } else {
                    Button {
                        habitStore.toggleHabit(id: habit.id, on: activeDateKey)
                    } label: {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : (isSkipped ? "forward.circle.fill" : "circle"))
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(isCompleted ? Color.green : (isSkipped ? Color.cyan : Color.secondary.opacity(0.45)))
                            .symbolEffect(.bounce, value: isCompleted)
                    }
                    .buttonStyle(.borderless)
                }
            }
            
            // Subtasks Checklist (if configured)
            if !habit.subtasks.isEmpty && !isSkipped {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(habit.subtasks) { subtask in
                        let subDone = habit.history[activeDateKey]?.completedSubtaskIds.contains(subtask.id) ?? false
                        Button {
                            habitStore.toggleSubtask(habitId: habit.id, subtaskId: subtask.id, on: activeDateKey)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: subDone ? "checkmark.square.fill" : "square")
                                    .font(.caption)
                                    .foregroundStyle(subDone ? Color(hex: habit.colorHex) : .secondary)
                                Text(subtask.title)
                                    .font(.caption)
                                    .strikethrough(subDone)
                                    .foregroundStyle(subDone ? .secondary : .primary)
                                Spacer()
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.leading, 54)
            }
            
            // Polarity & Tracking Mode Interactive Controls
            if habit.polarity == .quit {
                quitControlsRow
            } else if habit.polarity == .limit {
                limitControlsRow
            } else if habit.trackingType == .amount {
                amountControlsRow
            } else if habit.trackingType == .reps {
                repsControlsRow
            } else if habit.trackingType == .timer {
                timerControlsRow
            }
        }
        .padding(.vertical, 4)
        .opacity(isSkipped ? 0.72 : 1.0)
    }
    
    // MARK: - Mode Subviews
    
    private var quitControlsRow: some View {
        let daysClean = max(habit.streak, Calendar.current.dateComponents([.day], from: habit.abstainedSince ?? habit.createdAt, to: Date()).day ?? 0)
        let slipsToday = habit.history[activeDateKey]?.slipCount ?? 0
        
        return HStack {
            Text(slipsToday > 0 ? "Slipped \(slipsToday)x on this date" : "\(daysClean)d clean abstinence")
                .font(.caption.weight(.semibold))
                .foregroundStyle(slipsToday > 0 ? .red : .green)
            
            Spacer()
            
            Button {
                habitStore.logQuitSlip(id: habit.id, on: activeDateKey)
            } label: {
                Text("Log Slip")
                    .font(.caption2.weight(.bold))
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .controlSize(.mini)
        }
        .padding(.leading, 54)
    }
    
    private var limitControlsRow: some View {
        let ratio = min(1.0, currentAmount / max(1, habit.targetAmount))
        let overBudget = currentAmount > habit.targetAmount
        
        return VStack(spacing: 6) {
            HStack {
                Text("\(Int(currentAmount)) / \(Int(habit.targetAmount)) \(habit.unit) cap")
                    .font(.caption.weight(.semibold))
                    .contentTransition(.numericText())
                    .foregroundStyle(overBudget ? .red : .secondary)
                Spacer()
                Button("+1 \(habit.unit)") {
                    habitStore.incrementAmount(id: habit.id, step: max(1, habit.stepAmount), on: activeDateKey)
                }
                .font(.caption2.weight(.bold))
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
            ProgressView(value: ratio)
                .tint(overBudget ? .red : (ratio > 0.75 ? .orange : .green))
        }
        .padding(.leading, 54)
    }
    
    private var amountControlsRow: some View {
        let pct = min(1.0, currentAmount / max(1, effectiveTarget))
        
        return VStack(spacing: 6) {
            HStack {
                Text("\(Int(currentAmount)) / \(Int(effectiveTarget)) \(habit.unit)")
                    .font(.caption.weight(.semibold))
                    .contentTransition(.numericText())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(pct * 100))%")
                    .font(.caption.weight(.bold))
                    .contentTransition(.numericText())
                    .foregroundStyle(Color(hex: habit.colorHex))
            }
            
            ProgressView(value: pct)
                .tint(Color(hex: habit.colorHex))
            
            if !isCompleted && !isLockedMissed {
                HStack(spacing: 8) {
                    Button("+\(Int(habit.stepAmount)) \(habit.unit)") {
                        habitStore.incrementAmount(id: habit.id, step: habit.stepAmount, on: activeDateKey)
                    }
                    .font(.caption2.weight(.bold))
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    
                    Button("+\(Int(habit.stepAmount * 2)) \(habit.unit)") {
                        habitStore.incrementAmount(id: habit.id, step: habit.stepAmount * 2, on: activeDateKey)
                    }
                    .font(.caption2.weight(.bold))
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    
                    Spacer()
                }
            }
        }
        .padding(.leading, 54)
    }
    
    private var repsControlsRow: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(1...min(10, max(1, habit.targetReps)), id: \.self) { idx in
                    Circle()
                        .fill(idx <= currentReps ? Color(hex: habit.colorHex) : Color.secondary.opacity(0.2))
                        .frame(width: 7, height: 7)
                }
            }
            
            Spacer()
            
            if !isLockedMissed {
                HStack(spacing: 8) {
                    Button {
                        habitStore.stepReps(id: habit.id, delta: -1, on: activeDateKey)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    
                    Text("\(currentReps)/\(habit.targetReps)")
                        .font(.caption.monospacedDigit().weight(.bold))
                        .contentTransition(.numericText())
                    
                    Button {
                        habitStore.stepReps(id: habit.id, delta: 1, on: activeDateKey)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color(hex: habit.colorHex))
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(.leading, 54)
    }
    
    private var timerControlsRow: some View {
        let isThisRunning = (habitStore.activeTimerHabitId == habit.id && habitStore.isTimerRunning)
        
        return HStack {
            Label("\(habit.targetDurationMinutes) min session", systemImage: "timer")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button {
                onOpenTimer?()
            } label: {
                Label(
                    isThisRunning ? "Focusing..." : (isCompleted ? "Focus Again" : "Start Timer"),
                    systemImage: isThisRunning ? "waveform" : "play.fill"
                )
                .font(.caption2.weight(.bold))
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: habit.colorHex))
            .controlSize(.mini)
        }
        .padding(.leading, 54)
    }
}
