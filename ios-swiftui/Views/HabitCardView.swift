//
//  HabitCardView.swift
//  Productive - High-Responsiveness Semantic Cupertino Habit Row
//  120Hz Tactile Spring Controls, Clean Chevron-Free Alignment, Custom Smooth Progress Track,
//  Subtasks, Rollover Quotas, Quit Abstinence, Daily Limit Gauges & Reps Steppers
//

import SwiftUI

public struct HabitCardView: View {
    @EnvironmentObject var habitStore: HabitStore
    public let habit: Habit
    public var dateKey: String = ""
    public var onOpenDetail: (() -> Void)? = nil
    public var onOpenTimer: (() -> Void)? = nil
    public var onEditHabit: (() -> Void)? = nil
    public var onLogNote: (() -> Void)? = nil
    
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
    
    private var accentColor: Color {
        Color(hex: habit.colorHex)
    }
    
    public init(
        habit: Habit,
        dateKey: String = "",
        onOpenDetail: (() -> Void)? = nil,
        onOpenTimer: (() -> Void)? = nil,
        onEditHabit: (() -> Void)? = nil,
        onLogNote: (() -> Void)? = nil
    ) {
        self.habit = habit
        self.dateKey = dateKey
        self.onOpenDetail = onOpenDetail
        self.onOpenTimer = onOpenTimer
        self.onEditHabit = onEditHabit
        self.onLogNote = onLogNote
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top Row: Tappable Icon + Title Area (Opens Overview) & Dedicated Instant Check Ring
            HStack(spacing: 12) {
                Button {
                    habitStore.triggerHaptic(.light)
                    onOpenDetail?()
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [accentColor, accentColor.opacity(0.78)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 42, height: 42)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 0.7)
                                )
                            
                            Image(systemName: habit.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .symbolEffect(.bounce, value: isCompleted)
                        }
                        
                        VStack(alignment: .leading, spacing: 3.5) {
                            HStack(spacing: 5) {
                                Text(habit.name)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
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
                                    Text(habit.repeatLabel)
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(.secondary)
                                }
                                
                                if isSkipped {
                                    Label(habit.history[activeDateKey]?.usedFreezeShield == true ? "Frozen" : "Skipped", systemImage: "snowflake")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.cyan)
                                } else if !habit.subtasks.isEmpty {
                                    let doneCount = habit.history[activeDateKey]?.completedSubtaskIds.count ?? 0
                                    let totalCount = habit.subtasks.count
                                    let subPct = totalCount > 0 ? Int(round((Double(doneCount) / Double(totalCount)) * 100)) : 0
                                    Label("\(doneCount)/\(totalCount) (\(subPct)%)", systemImage: "checklist")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(isCompleted ? Color.green : accentColor)
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
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(TactileScaleButtonStyle(pressedScale: 0.98))
                
                HStack(spacing: 6) {
                    // Visible ••• Action Menu Button (Matches HTML Simulator 1:1!)
                    Menu {
                        Button {
                            habitStore.triggerHaptic(.light)
                            onOpenDetail?()
                        } label: {
                            Label("Habit Overview & Heatmap", systemImage: "chart.bar.xaxis")
                        }
                        
                        Button {
                            withAnimation(.snappy(duration: 0.2)) {
                                habitStore.toggleHabit(id: habit.id, on: activeDateKey)
                            }
                        } label: {
                            Label(isCompleted ? "Mark Incomplete" : "Mark Completed", systemImage: "checkmark.circle")
                        }
                        
                        if habit.trackingType == .timer {
                            Button {
                                onOpenTimer?()
                            } label: {
                                Label("Open Focus Timer", systemImage: "timer")
                            }
                        }
                        
                        Button {
                            onLogNote?()
                        } label: {
                            Label("Add Mood & Reflection Note", systemImage: "square.and.pencil")
                        }
                        
                        Button {
                            habitStore.toggleSkipHabit(id: habit.id, on: activeDateKey)
                        } label: {
                            Label(isSkipped ? "Remove Skip" : "Skip / Rest Day", systemImage: "forward.end")
                        }
                        
                        if isLockedMissed && habitStore.streakFreezeShields > 0 {
                            Button {
                                _ = habitStore.useFreezeShield(for: habit.id, on: activeDateKey)
                            } label: {
                                Label("Use Streak Freeze Shield (\(habitStore.streakFreezeShields) left)", systemImage: "snowflake")
                            }
                        }
                        
                        Divider()
                        
                        Button {
                            onEditHabit?()
                        } label: {
                            Label("Edit Habit", systemImage: "pencil")
                        }
                        
                        Button {
                            habitStore.duplicateHabit(id: habit.id)
                        } label: {
                            Label("Duplicate Habit", systemImage: "plus.square.on.square")
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
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 30, height: 30)
                            .background(Color.primary.opacity(0.06), in: Circle())
                    }
                    .buttonStyle(TactileScaleButtonStyle(pressedScale: 0.88))
                    
                    // Dedicated Instant Checkmark / Lock Ring
                    if isLockedMissed {
                        Image(systemName: "lock.fill")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .frame(width: 34, height: 34)
                            .background(.red.opacity(0.12), in: Circle())
                    } else {
                        Button {
                            withAnimation(.snappy(duration: 0.2)) {
                                habitStore.toggleHabit(id: habit.id, on: activeDateKey)
                            }
                        } label: {
                            ZStack {
                                if isCompleted {
                                    Circle()
                                        .fill(Color.green.gradient)
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .heavy))
                                        .foregroundStyle(.white)
                                } else if isSkipped {
                                    Circle()
                                        .fill(Color.cyan.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.cyan)
                                } else {
                                    Circle()
                                        .stroke(Color.secondary.opacity(0.38), lineWidth: 2.2)
                                        .frame(width: 30, height: 30)
                                }
                            }
                            .frame(width: 36, height: 36)
                            .contentShape(Circle())
                        }
                        .buttonStyle(TactileScaleButtonStyle(pressedScale: 0.86))
                    }
                }
            }
            
            // Subtasks Checklist with Live Proportional Progress Bar
            if !habit.subtasks.isEmpty && !isSkipped {
                let totalSubs = habit.subtasks.count
                let doneSubsCount = habit.history[activeDateKey]?.completedSubtaskIds.count ?? 0
                let fraction = totalSubs > 0 ? (Double(doneSubsCount) / Double(totalSubs)) : 0.0
                let pct = Int(round(fraction * 100))
                
                VStack(alignment: .leading, spacing: 6) {
                    // Fractional Progress Text & Smooth Progress Bar
                    HStack(spacing: 8) {
                        Text("\(doneSubsCount) of \(totalSubs) steps done")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(isCompleted ? Color.green : Color.secondary)
                        
                        Spacer()
                        
                        Text("\(pct)%")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(isCompleted ? Color.green : accentColor)
                            .contentTransition(.numericText())
                    }
                    .padding(.leading, 52)
                    .padding(.trailing, 4)
                    
                    smoothProgressTrack(fraction: fraction, color: isCompleted ? Color.green : accentColor)
                        .frame(height: 5.5)
                        .padding(.leading, 52)
                        .padding(.trailing, 4)
                        .padding(.bottom, 2)
                    
                    // Checklist Items
                    ForEach(habit.subtasks) { subtask in
                        let subDone = habit.history[activeDateKey]?.completedSubtaskIds.contains(subtask.id) ?? false
                        Button {
                            withAnimation(.snappy(duration: 0.18)) {
                                habitStore.toggleSubtask(habitId: habit.id, subtaskId: subtask.id, on: activeDateKey)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: subDone ? "checkmark.square.fill" : "square")
                                    .font(.caption)
                                    .foregroundStyle(subDone ? accentColor : .secondary)
                                Text(subtask.title)
                                    .font(.caption)
                                    .strikethrough(subDone)
                                    .foregroundStyle(subDone ? .secondary : .primary)
                                Spacer()
                            }
                            .padding(.vertical, 1)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(TactileScaleButtonStyle(pressedScale: 0.97))
                    }
                }
                .padding(.top, 2)
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
        .opacity(isSkipped ? 0.72 : 1.0)
    }
    
    // MARK: - Smooth Capsule Progress Track
    
    private func smoothProgressTrack(fraction: Double, color: Color) -> some View {
        GeometryReader { geo in
            let clamped = min(1.0, max(0.0, fraction))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 5.5)
                
                Capsule()
                    .fill(color.gradient)
                    .frame(width: max(clamped > 0 ? 6 : 0, geo.size.width * clamped), height: 5.5)
                    .animation(.snappy(duration: 0.24), value: clamped)
            }
        }
        .frame(height: 5.5)
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
                    .foregroundStyle(.red)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(.red.opacity(0.14), in: Capsule())
            }
            .buttonStyle(TactileScaleButtonStyle())
        }
        .padding(.leading, 52)
    }
    
    private var limitControlsRow: some View {
        let ratio = min(1.0, currentAmount / max(1, habit.targetAmount))
        let overBudget = currentAmount > habit.targetAmount
        let barColor: Color = overBudget ? .red : (ratio > 0.75 ? .orange : .green)
        
        return VStack(spacing: 5) {
            HStack {
                Text("\(Int(currentAmount)) / \(Int(habit.targetAmount)) \(habit.unit) cap")
                    .font(.caption.weight(.semibold))
                    .contentTransition(.numericText())
                    .foregroundStyle(overBudget ? .red : .secondary)
                Spacer()
                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        habitStore.incrementAmount(id: habit.id, step: max(1, habit.stepAmount), on: activeDateKey)
                    }
                } label: {
                    Text("+\(Int(max(1, habit.stepAmount))) \(habit.unit)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.08), in: Capsule())
                }
                .buttonStyle(TactileScaleButtonStyle())
            }
            smoothProgressTrack(fraction: ratio, color: barColor)
        }
        .padding(.leading, 52)
    }
    
    private var amountControlsRow: some View {
        let pct = min(1.0, currentAmount / max(1, effectiveTarget))
        
        return VStack(spacing: 6) {
            HStack(alignment: .center) {
                Text("\(Int(currentAmount)) / \(Int(effectiveTarget)) \(habit.unit)")
                    .font(.caption.weight(.semibold))
                    .contentTransition(.numericText())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(pct * 100))%")
                    .font(.caption.weight(.heavy))
                    .contentTransition(.numericText())
                    .foregroundStyle(accentColor)
            }
            
            smoothProgressTrack(fraction: pct, color: accentColor)
            
            if !isCompleted && !isLockedMissed {
                HStack(spacing: 7) {
                    Button {
                        withAnimation(.snappy(duration: 0.2)) {
                            habitStore.incrementAmount(id: habit.id, step: habit.stepAmount, on: activeDateKey)
                        }
                    } label: {
                        Text("+\(Int(habit.stepAmount)) \(habit.unit)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4.5)
                            .background(accentColor.opacity(0.14), in: Capsule())
                    }
                    .buttonStyle(TactileScaleButtonStyle())
                    
                    Button {
                        withAnimation(.snappy(duration: 0.2)) {
                            habitStore.incrementAmount(id: habit.id, step: habit.stepAmount * 2, on: activeDateKey)
                        }
                    } label: {
                        Text("+\(Int(habit.stepAmount * 2)) \(habit.unit)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4.5)
                            .background(accentColor.opacity(0.14), in: Capsule())
                    }
                    .buttonStyle(TactileScaleButtonStyle())
                    
                    Spacer()
                }
            }
        }
        .padding(.leading, 52)
    }
    
    private var repsControlsRow: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(1...min(10, max(1, habit.targetReps)), id: \.self) { idx in
                    Circle()
                        .fill(idx <= currentReps ? accentColor : Color.secondary.opacity(0.22))
                        .frame(width: 7, height: 7)
                        .animation(.snappy(duration: 0.18), value: currentReps)
                }
            }
            
            Spacer()
            
            if !isLockedMissed {
                HStack(spacing: 6) {
                    Button {
                        withAnimation(.snappy(duration: 0.18)) {
                            habitStore.stepReps(id: habit.id, delta: -1, on: activeDateKey)
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(.secondary)
                            .frame(width: 26, height: 26)
                            .background(Color.primary.opacity(0.08), in: Circle())
                    }
                    .buttonStyle(TactileScaleButtonStyle(pressedScale: 0.88))
                    
                    Text("\(currentReps)/\(habit.targetReps)")
                        .font(.caption.monospacedDigit().weight(.heavy))
                        .contentTransition(.numericText())
                        .frame(minWidth: 28)
                    
                    Button {
                        withAnimation(.snappy(duration: 0.18)) {
                            habitStore.stepReps(id: habit.id, delta: 1, on: activeDateKey)
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(accentColor, in: Circle())
                    }
                    .buttonStyle(TactileScaleButtonStyle(pressedScale: 0.88))
                }
            }
        }
        .padding(.leading, 52)
    }
    
    private var timerControlsRow: some View {
        let isThisRunning = (habitStore.activeTimerHabitId == habit.id && habitStore.isTimerRunning)
        
        return HStack {
            Label("\(habit.targetDurationMinutes) min session", systemImage: "timer")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button {
                habitStore.triggerHaptic(.light)
                onOpenTimer?()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isThisRunning ? "waveform" : "play.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text(isThisRunning ? "Focusing..." : (isCompleted ? "Focus Again" : "Start Timer"))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(accentColor.gradient, in: Capsule())
            }
            .buttonStyle(TactileScaleButtonStyle())
        }
        .padding(.leading, 52)
    }
}
