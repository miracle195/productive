//
//  DueTasksPopupSheet.swift
//  Productive - Responsive Due Tasks Modal Popup Sheet
//  Triggered by tapping any circle in the Daily Progress Screen Widget
//

import SwiftUI

public enum DueTasksPopupFilter: Identifiable, Equatable {
    case all
    case routine(TimeOfDay)
    case singleHabit(UUID)
    
    public var id: String {
        switch self {
        case .all: return "all"
        case .routine(let bucket): return "routine_\(bucket.rawValue)"
        case .singleHabit(let id): return "habit_\(id.uuidString)"
        }
    }
}

public struct DueTasksPopupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var habitStore: HabitStore
    
    public let filter: DueTasksPopupFilter
    public let dateKey: String
    
    @State private var filterSegment: Int = 0 // 0: All, 1: Pending, 2: Done
    @State private var activeTimerTarget: Habit? = nil
    
    private var activeDate: Date {
        Habit.isoDateFormatter.date(from: dateKey) ?? Date()
    }
    
    private var baseDueHabits: [Habit] {
        let allDue = habitStore.habitsDue(on: activeDate)
        switch filter {
        case .all:
            return allDue
        case .routine(let bucket):
            return allDue.filter { $0.timeOfDay == bucket }
        case .singleHabit(let id):
            return allDue.filter { $0.id == id }
        }
    }
    
    private var displayedHabits: [Habit] {
        switch filterSegment {
        case 1:
            return baseDueHabits.filter { !$0.isCompleted(on: dateKey) && !$0.isSkipped(on: dateKey) }
        case 2:
            return baseDueHabits.filter { $0.isCompleted(on: dateKey) }
        default:
            return baseDueHabits
        }
    }
    
    private var completedCount: Int {
        baseDueHabits.filter { $0.isCompleted(on: dateKey) || $0.isSkipped(on: dateKey) }.count
    }
    
    private var totalCount: Int {
        baseDueHabits.count
    }
    
    private var completionFraction: Double {
        totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0.0
    }
    
    private var completionPercent: Int {
        Int(round(completionFraction * 100))
    }
    
    private var headerTitle: String {
        switch filter {
        case .all:
            return "Today's Due Tasks"
        case .routine(let bucket):
            return "\(bucket.rawValue) Tasks"
        case .singleHabit(let id):
            let name = habitStore.habits.first(where: { $0.id == id })?.name ?? "Habit Goal"
            return name
        }
    }
    
    private var headerIcon: String {
        switch filter {
        case .all:
            return "checklist.checked"
        case .routine(let bucket):
            return bucket.icon
        case .singleHabit(let id):
            return habitStore.habits.first(where: { $0.id == id })?.icon ?? "sparkles"
        }
    }
    
    private var headerColor: Color {
        switch filter {
        case .all:
            return Color.accentColor
        case .routine(let bucket):
            return bucket.tintColor
        case .singleHabit(let id):
            if let h = habitStore.habits.first(where: { $0.id == id }) {
                return Color(hex: h.colorHex)
            }
            return Color.accentColor
        }
    }
    
    public init(filter: DueTasksPopupFilter, dateKey: String) {
        self.filter = filter
        self.dateKey = dateKey
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Hero Summary Card
                headerSummaryCard
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 10)
                
                // Segmented Filter (if multiple habits)
                if filter != .all || baseDueHabits.count > 1 {
                    Picker("Filter", selection: $filterSegment) {
                        Text("All (\(totalCount))").tag(0)
                        Text("Due (\(totalCount - completedCount))").tag(1)
                        Text("Done (\(completedCount))").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                }
                
                Divider()
                    .opacity(0.4)
                
                // Scrollable Tasks List
                if displayedHabits.isEmpty {
                    VStack(spacing: 12) {
                        Spacer(minLength: 40)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.green.gradient)
                        Text("No Tasks Pending")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                        Text(filterSegment == 1 ? "All scheduled tasks for this filter are complete!" : "No tasks match this selection.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(displayedHabits) { habit in
                                popupHabitRow(for: habit)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
                
                // Bottom Quick Action Bar
                bottomActionBar
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(headerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
            .sheet(item: $activeTimerTarget) { habit in
                FocusTimerSheet(habit: habit)
                    .environmentObject(habitStore)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Header Summary Card
    
    private var headerSummaryCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [headerColor, headerColor.opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: headerIcon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(headerTitle)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("\(completedCount) of \(totalCount) completed • \(completionPercent)%")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                
                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.08))
                            .frame(height: 5.5)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: completionPercent == 100 ? [.green, .mint] : [headerColor, headerColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geo.size.width * CGFloat(completionFraction)), height: 5.5)
                            .animation(.snappy, value: completionFraction)
                    }
                }
                .frame(height: 6)
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 0.8)
        )
    }
    
    // MARK: - Popup Habit Row Card
    
    private func popupHabitRow(for habit: Habit) -> some View {
        let isDone = habit.isCompleted(on: dateKey)
        let isSkipped = habit.isSkipped(on: dateKey)
        let habitColor = Color(hex: habit.colorHex)
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(habitColor)
                        .frame(width: 38, height: 38)
                    Image(systemName: habit.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                // Title & Subtitle
                VStack(alignment: .leading, spacing: 2.5) {
                    Text(habit.name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(isDone ? .secondary : .primary)
                        .strikethrough(isDone && habit.polarity == .build)
                    
                    HStack(spacing: 5) {
                        Text(habit.timeOfDay.rawValue)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                            Text(habit.streakDisplay)
                        }
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(habit.streak > 0 ? .orange : .secondary)
                    }
                }
                
                Spacer(minLength: 8)
                
                // Dedicated Instant Check Ring
                Button {
                    withAnimation(.snappy(duration: 0.22)) {
                        habitStore.toggleHabit(id: habit.id, on: dateKey)
                    }
                    habitStore.triggerHaptic(.medium)
                } label: {
                    ZStack {
                        if isDone {
                            Circle()
                                .fill(Color.green.gradient)
                                .frame(width: 32, height: 32)
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .heavy))
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
                                .stroke(Color.secondary.opacity(0.35), lineWidth: 2.2)
                                .frame(width: 30, height: 30)
                        }
                    }
                    .frame(width: 36, height: 36)
                    .contentShape(Circle())
                }
                .buttonStyle(TactileScaleButtonStyle(pressedScale: 0.86))
            }
            
            // Subtasks checklist inside popup
            if !habit.subtasks.isEmpty && !isSkipped {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(habit.subtasks) { step in
                        let stepDone = habit.history[dateKey]?.completedSubtaskIds.contains(step.id) ?? false
                        Button {
                            withAnimation(.snappy(duration: 0.18)) {
                                habitStore.toggleSubtask(habitId: habit.id, subtaskId: step.id, on: dateKey)
                            }
                            habitStore.triggerHaptic(.light)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: stepDone ? "checkmark.square.fill" : "square")
                                    .font(.caption)
                                    .foregroundStyle(stepDone ? habitColor : .secondary)
                                Text(step.title)
                                    .font(.system(size: 12, design: .rounded))
                                    .strikethrough(stepDone)
                                    .foregroundStyle(stepDone ? .secondary : .primary)
                                Spacer()
                            }
                            .padding(.vertical, 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.leading, 50)
                .padding(.top, 2)
            }
            
            // Quick Amount / Reps / Timer Stepper inside popup
            if habit.trackingType == .timer && !isDone {
                HStack {
                    Spacer()
                    Button {
                        activeTimerTarget = habit
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text("Start \(habit.targetDurationMinutes)m Timer")
                                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5)
                        .background(Color(hex: "#FF7450"), in: Capsule())
                    }
                    .buttonStyle(TactileScaleButtonStyle())
                }
                .padding(.leading, 50)
            } else if habit.trackingType == .amount && habit.polarity == .build && !isDone {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.snappy) {
                            habitStore.incrementAmount(id: habit.id, step: habit.stepAmount, on: dateKey)
                        }
                    } label: {
                        Text("+\(Int(habit.stepAmount)) \(habit.unit)")
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(TactileScaleButtonStyle())
                }
                .padding(.leading, 50)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 0.8)
        )
    }
    
    // MARK: - Bottom Action Bar
    
    private var bottomActionBar: some View {
        HStack(spacing: 12) {
            let pendingCount = totalCount - completedCount
            if pendingCount > 0 {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        for h in baseDueHabits where !h.isCompleted(on: dateKey) {
                            habitStore.toggleHabit(id: h.id, on: dateKey)
                        }
                    }
                    habitStore.triggerHaptic(.success)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Complete All (\(pendingCount))")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
            }
            
            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .frame(maxWidth: pendingCount > 0 ? 90 : .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }
}

