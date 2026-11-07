//
//  HabitDetailView.swift
//  Productive - Live Habit Performance, Real Monthly Heatmap, Edit/Archive & Reflection Journal
//

import SwiftUI

public struct HabitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var habitStore: HabitStore
    
    public let habitId: UUID
    
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    @State private var showingTimerSheet = false
    @State private var journalDateKey: String? = nil
    
    private var habit: Habit? {
        habitStore.habits.first(where: { $0.id == habitId })
    }
    
    public init(habitId: UUID) {
        self.habitId = habitId
    }
    
    public init(habit: Habit) {
        self.habitId = habit.id
    }
    
    private var last28Dates: [(dateKey: String, dayNum: String, isToday: Bool)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let numFmt = DateFormatter()
        numFmt.dateFormat = "d"
        return (-27...0).compactMap { offset in
            guard let d = cal.date(byAdding: .day, value: offset, to: today) else { return nil }
            return (
                dateKey: HabitStore.dateFormatter.string(from: d),
                dayNum: numFmt.string(from: d),
                isToday: offset == 0
            )
        }
    }
    
    public var body: some View {
        Group {
            if let habit = habit {
                VStack(spacing: 0) {
                    // Pinned Compact Hero Header (Stays steady while metrics & heatmap scroll below)
                    VStack(spacing: 8) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(hex: habit.colorHex).gradient)
                                    .frame(width: 54, height: 54)
                                    .shadow(color: Color(hex: habit.colorHex).opacity(0.3), radius: 8, y: 4)
                                
                                Image(systemName: habit.icon)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(habit.name)
                                    .font(.system(.title3, design: .rounded).weight(.heavy))
                                    .lineLimit(2)
                                
                                Text("\(habit.frequency.rawValue) • \(habit.timeOfDay.rawValue) • \(habit.summaryGoalLabel)")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer(minLength: 0)
                        }
                        
                        HStack(spacing: 8) {
                            Button {
                                if habit.trackingType == .timer {
                                    showingTimerSheet = true
                                } else {
                                    withAnimation(.snappy(duration: 0.2)) {
                                        habitStore.toggleHabit(id: habit.id)
                                    }
                                }
                            } label: {
                                Label(
                                    habit.isCompleted(on: habitStore.todayKey) ? "Completed Today" : (habit.trackingType == .timer ? "Start Focus Timer" : "Check In Today"),
                                    systemImage: habit.isCompleted(on: habitStore.todayKey) ? "checkmark.circle.fill" : "bolt.fill"
                                )
                                .font(.caption.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(hex: habit.colorHex))
                            .buttonBorderShape(.capsule)
                            
                            Button {
                                journalDateKey = habitStore.todayKey
                            } label: {
                                Label("Log Note", systemImage: "square.and.pencil")
                                    .font(.caption.weight(.bold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGroupedBackground))
                    
                    Divider()
                        .opacity(0.45)
                    
                    // Dedicated Scrollable Analytics, Heatmap & Journal Region
                    List {
                        // Key Metrics Grid
                        Section(header: Text("Performance Metrics")) {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                MetricTile(title: "Current Streak", value: "\(habit.streak)d", icon: "flame.fill", tint: .orange)
                                MetricTile(title: "Best Streak", value: "\(habit.bestStreak)d", icon: "crown.fill", tint: .yellow)
                                MetricTile(title: "Total Logs", value: "\(habit.totalLogs)", icon: "checkmark.seal.fill", tint: .green)
                                MetricTile(title: "28d Rate", value: "\(consistency28Day(for: habit))%", icon: "chart.line.uptrend.xyaxis", tint: .blue)
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                            .listRowBackground(Color.clear)
                        }
                    
                    // Real 28-Day Interactive Calendar Heatmap
                    Section(
                        header: Text("Last 28 Days (Tap any date to add/view note)"),
                        footer: Text("Green = Completed • Cyan = Skipped / Shielded • Red = Missed Strict Day")
                    ) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                            ForEach(last28Dates, id: \.dateKey) { item in
                                let rec = habit.history[item.dateKey]
                                let done = rec?.isCompleted == true
                                let skipped = (rec?.isSkipped == true) || (rec?.usedFreezeShield == true)
                                let lockedMiss = habitStore.isLockedByStrictMode(habit, on: item.dateKey)
                                
                                Button {
                                    journalDateKey = item.dateKey
                                } label: {
                                    VStack(spacing: 2) {
                                        Text(item.dayNum)
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                        if let mood = rec?.mood {
                                            Text(mood.emoji)
                                                .font(.system(size: 8))
                                        }
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 38)
                                    .background(
                                        done ? Color.green :
                                        skipped ? Color.cyan.opacity(0.35) :
                                        lockedMiss ? Color.red.opacity(0.22) :
                                        Color(.tertiarySystemGroupedBackground),
                                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    )
                                    .foregroundStyle(done ? .white : .primary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(item.isToday ? Color.accentColor : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    
                    // Reflection & Mood Journal Feed
                    let journalRecords = habit.history
                        .filter { !$0.value.note.isEmpty || $0.value.mood != nil }
                        .sorted { $0.key > $1.key }
                    
                    Section(header: Text("Reflection Journal (\(journalRecords.count))")) {
                        if journalRecords.isEmpty {
                            Text("No reflection notes yet. Tap \"Log Note\" or any date above to track mood & insights.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(journalRecords, id: \.key) { entry in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(entry.key)
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.secondary)
                                        if let mood = entry.value.mood {
                                            Text("\(mood.emoji) \(mood.rawValue)")
                                                .font(.caption.weight(.semibold))
                                        }
                                        Spacer()
                                        if entry.value.isCompleted {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.caption)
                                                .foregroundStyle(.green)
                                        }
                                    }
                                    if !entry.value.note.isEmpty {
                                        Text(entry.value.note)
                                            .font(.subheadline)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    
                    // Management Actions
                    Section {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Label("Edit Habit Configuration", systemImage: "slider.horizontal.3")
                        }
                        
                        Button {
                            habitStore.toggleArchiveHabit(id: habit.id)
                            dismiss()
                        } label: {
                            Label(habit.isArchived ? "Unarchive Habit" : "Archive / Pause Habit", systemImage: "archivebox")
                        }
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Habit", systemImage: "trash")
                        }
                    }
                    }
                    .listStyle(.insetGrouped)
                    .listSectionSpacing(16)
                    .contentMargins(.top, 12, for: .scrollContent)
                }
                .toolbar(.visible, for: .navigationBar)
                .navigationTitle("Overview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Edit") {
                            showingEditSheet = true
                        }
                    }
                }
                .sheet(isPresented: $showingEditSheet) {
                    AddHabitSheet(editingHabit: habit)
                        .environmentObject(habitStore)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                }
                .sheet(isPresented: $showingTimerSheet) {
                    FocusTimerSheet(habit: habit)
                        .environmentObject(habitStore)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
                .sheet(isPresented: Binding(
                    get: { journalDateKey != nil },
                    set: { if !$0 { journalDateKey = nil } }
                )) {
                    if let key = journalDateKey {
                        JournalEntrySheet(habit: habit, dateKey: key)
                            .environmentObject(habitStore)
                            .presentationDetents([.medium])
                            .presentationDragIndicator(.visible)
                    }
                }
                .alert("Delete Habit?", isPresented: $showingDeleteAlert) {
                    Button("Delete", role: .destructive) {
                        habitStore.deleteHabit(id: habit.id)
                        dismiss()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This permanently deletes \"\(habit.name)\" and all of its historical logs.")
                }
            } else {
                ContentUnavailableView("Habit Removed", systemImage: "checkmark.circle")
            }
        }
    }
    
    private func consistency28Day(for habit: Habit) -> Int {
        let completedOrSkipped = last28Dates.filter {
            habit.isCompleted(on: $0.dateKey) || habit.isSkipped(on: $0.dateKey)
        }.count
        return Int((Double(completedOrSkipped) / 28.0) * 100)
    }
}

private struct MetricTile: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                Text(title)
                    .foregroundStyle(.secondary)
            }
            .font(.caption.weight(.semibold))
            
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
