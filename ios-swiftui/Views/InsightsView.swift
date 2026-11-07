//
//  InsightsView.swift
//  Productive - Native Swift Charts Analytics, Donut Breakdown & 84-Day Activity Heatmap
//

import SwiftUI
import Charts

private struct DailyAdherencePoint: Identifiable {
    let id: String
    let label: String
    let percent: Int
}

private struct BucketSharePoint: Identifiable {
    let id: String
    let bucket: TimeOfDay
    let completedCount: Int
}

public struct InsightsView: View {
    @EnvironmentObject var habitStore: HabitStore
    
    private var weeklyPoints: [DailyAdherencePoint] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        
        return (-6...0).compactMap { offset in
            guard let date = cal.date(byAdding: .day, value: offset, to: today) else { return nil }
            let key = HabitStore.dateFormatter.string(from: date)
            let pct = habitStore.completionPercentage(on: date, dateKey: key)
            return DailyAdherencePoint(id: key, label: HabitStore.dayLetterFormatter.string(from: date), percent: pct)
        }
    }
    
    private var averageWeeklyRate: Int {
        guard !weeklyPoints.isEmpty else { return 0 }
        let sum = weeklyPoints.reduce(0) { $0 + $1.percent }
        return sum / weeklyPoints.count
    }
    
    private var bucketShares: [BucketSharePoint] {
        TimeOfDay.allCases.map { bucket in
            let count = habitStore.habits
                .filter { $0.timeOfDay == bucket }
                .reduce(0) { $0 + $1.totalLogs }
            return BucketSharePoint(id: bucket.rawValue, bucket: bucket, completedCount: max(0, count))
        }
    }
    
    private var heatmap84Days: [(key: String, ratio: Double)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (-83...0).compactMap { offset in
            guard let d = cal.date(byAdding: .day, value: offset, to: today) else { return nil }
            let key = HabitStore.dateFormatter.string(from: d)
            return (key: key, ratio: Double(habitStore.completionPercentage(on: d, dateKey: key)) / 100.0)
        }
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Pinned Non-Scrolling Header + KPI Summary Strip
                VStack(alignment: .leading, spacing: 12) {
                    Text("Insights")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .padding(.top, 10)
                    
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("7-Day Consistency")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("\(averageWeeklyRate)%")
                                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                                    .contentTransition(.numericText())
                                let totalLogs = habitStore.habits.reduce(0) { $0 + $1.totalLogs }
                                Text("\(totalLogs) lifetime logs • \(habitStore.activeHabits.count) active")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "chart.bar.doc.horizontal.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.accentColor)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .background(Color(.systemGroupedBackground))
                
                Divider()
                    .opacity(0.45)
                
                // Dedicated Vertically-Scrolling Charts & Heatmap Area
                List {
                
                // Native Swift Charts: 7-Day Adherence BarMark + RuleMark
                Section(header: Text("Last 7 Days Adherence")) {
                    Chart {
                        ForEach(weeklyPoints) { pt in
                            BarMark(
                                x: .value("Day", pt.label),
                                y: .value("Completion %", pt.percent)
                            )
                            .foregroundStyle(Color.accentColor.gradient)
                            .cornerRadius(6)
                        }
                        
                        RuleMark(y: .value("Average", averageWeeklyRate))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                            .foregroundStyle(.orange)
                            .annotation(position: .top, alignment: .leading) {
                                Text("Avg \(averageWeeklyRate)%")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.orange)
                            }
                    }
                    .chartYScale(domain: 0...100)
                    .frame(height: 190)
                    .padding(.vertical, 8)
                }
                
                // Native Swift Charts: Time-of-Day Donut SectorMark
                Section(header: Text("Completions by Time of Day")) {
                    let totalBucketLogs = bucketShares.reduce(0) { $0 + $1.completedCount }
                    if totalBucketLogs == 0 {
                        Text("Check off habits to unlock your time-of-day rhythm breakdown.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        HStack(spacing: 20) {
                            Chart(bucketShares) { item in
                                SectorMark(
                                    angle: .value("Logs", max(0, item.completedCount)),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 2
                                )
                                .foregroundStyle(by: .value("Routine", item.bucket.rawValue))
                                .cornerRadius(4)
                            }
                            .frame(width: 130, height: 130)
                            .chartLegend(.hidden)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(bucketShares) { item in
                                    HStack {
                                        Image(systemName: item.bucket.icon)
                                            .foregroundStyle(item.bucket.tintColor)
                                            .frame(width: 18)
                                        Text(item.bucket.rawValue)
                                            .font(.caption.weight(.semibold))
                                        Spacer()
                                        Text("\(item.completedCount)")
                                            .font(.caption.monospacedDigit().weight(.bold))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
                
                // 12-Week Activity Heatmap Grid
                Section(header: Text("12-Week Consistency Heatmap")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 14), spacing: 4) {
                        ForEach(heatmap84Days, id: \.key) { cell in
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(heatmapColor(for: cell.ratio))
                                .frame(height: 16)
                        }
                    }
                    .padding(.vertical, 6)
                }
                
                // Top Habit Streaks Leaderboard
                Section(header: Text("Streak Leaderboard")) {
                    if habitStore.activeHabits.isEmpty {
                        Text("No active habits yet.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(habitStore.activeHabits.sorted { $0.streak > $1.streak }.prefix(5)) { habit in
                            HStack(spacing: 12) {
                                Image(systemName: habit.icon)
                                    .foregroundStyle(.white)
                                    .frame(width: 30, height: 30)
                                    .background(Color(hex: habit.colorHex), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(habit.name)
                                        .font(.subheadline.weight(.semibold))
                                    Text("Best: \(habit.bestStreak)d • \(habit.totalLogs) total")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Label("\(habit.streak)d", systemImage: "flame.fill")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
                }
                .listStyle(.insetGrouped)
                .listSectionSpacing(16)
                .contentMargins(.top, 12, for: .scrollContent)
                .scrollContentBackground(.hidden)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    private func heatmapColor(for ratio: Double) -> Color {
        if ratio <= 0 { return Color(.tertiarySystemGroupedBackground) }
        if ratio < 0.4 { return Color.green.opacity(0.35) }
        if ratio < 0.8 { return Color.green.opacity(0.65) }
        return Color.green
    }
}

