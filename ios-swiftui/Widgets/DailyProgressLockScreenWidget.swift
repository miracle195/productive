//
//  DailyProgressLockScreenWidget.swift
//  Productive - Daily Progress Circles System Widget for Lock Screen & Home Screen
//  Supports .accessoryCircular, .accessoryRectangular, .accessoryInline, .systemSmall, .systemMedium
//  Deep-links directly to the interactive Due Tasks Popup Sheet via productive://due-tasks
//

import WidgetKit
import SwiftUI

public struct DailyProgressEntry: TimelineEntry {
    public let date: Date
    public let snapshot: WidgetDailySnapshot
    
    public init(date: Date, snapshot: WidgetDailySnapshot) {
        self.date = date
        self.snapshot = snapshot
    }
}

public struct DailyProgressWidgetProvider: TimelineProvider {
    public init() {}
    
    public func placeholder(in context: Context) -> DailyProgressEntry {
        DailyProgressEntry(date: Date(), snapshot: .preview)
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (DailyProgressEntry) -> Void) {
        let snapshot = WidgetSnapshotStore.load()
        completion(DailyProgressEntry(date: Date(), snapshot: snapshot))
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<DailyProgressEntry>) -> Void) {
        let snapshot = WidgetSnapshotStore.load()
        let entry = DailyProgressEntry(date: Date(), snapshot: snapshot)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

public struct DailyProgressLockScreenWidget: Widget {
    public let kind: String = "DailyProgressLockScreenWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyProgressWidgetProvider()) { entry in
            DailyProgressWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Daily Progress Circles")
        .description("Circular progress rings, streak flame, and due tasks for your Lock Screen and Home Screen.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .systemSmall,
            .systemMedium
        ])
    }
}

// MARK: - Root Entry View

public struct DailyProgressWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    public let entry: DailyProgressEntry
    
    public init(entry: DailyProgressEntry) {
        self.entry = entry
    }
    
    public var body: some View {
        switch family {
        case .accessoryCircular:
            LockScreenCircularWidgetView(snapshot: entry.snapshot)
        case .accessoryRectangular:
            LockScreenRectangularWidgetView(snapshot: entry.snapshot)
        case .accessoryInline:
            LockScreenInlineWidgetView(snapshot: entry.snapshot)
        case .systemSmall:
            SystemSmallDailyProgressWidgetView(snapshot: entry.snapshot)
        case .systemMedium:
            SystemMediumDailyProgressWidgetView(snapshot: entry.snapshot)
        default:
            LockScreenCircularWidgetView(snapshot: entry.snapshot)
        }
    }
}

// MARK: - 1. Lock Screen Circular Gauge (.accessoryCircular)

struct LockScreenCircularWidgetView: View {
    let snapshot: WidgetDailySnapshot
    
    var body: some View {
        let fraction = snapshot.totalDueCount > 0 ? Double(snapshot.completedCount) / Double(snapshot.totalDueCount) : 0.0
        let isAllDone = snapshot.totalDueCount > 0 && snapshot.completedCount >= snapshot.totalDueCount
        
        Gauge(value: fraction) {
            Image(systemName: "checklist")
        } currentValueLabel: {
            VStack(spacing: -1) {
                if isAllDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                } else if snapshot.streakDays > 0 {
                    HStack(spacing: 1) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 9))
                        Text("\(snapshot.streakDays)")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                    }
                } else {
                    Text("\(snapshot.completionPercentage)%")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                }
            }
        }
        .gaugeStyle(.accessoryCircular)
        .widgetURL(URL(string: "productive://due-tasks?filter=all"))
    }
}

// MARK: - 2. Lock Screen Rectangular Card (.accessoryRectangular - Simplified Daily Focus with Circles)

struct LockScreenRectangularWidgetView: View {
    let snapshot: WidgetDailySnapshot
    
    var body: some View {
        let isAllDone = snapshot.totalDueCount > 0 && snapshot.completedCount >= snapshot.totalDueCount
        let fraction = snapshot.totalDueCount > 0 ? Double(snapshot.completedCount) / Double(snapshot.totalDueCount) : 0.0
        
        VStack(alignment: .leading, spacing: 4) {
            // Header: Daily Focus + Streak + Fraction
            HStack(spacing: 4) {
                Text("Daily Focus")
                    .font(.system(size: 11.5, weight: .heavy, design: .rounded))
                if snapshot.streakDays > 0 {
                    Text("• 🔥\(snapshot.streakDays)d")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                }
                Spacer(minLength: 2)
                Text("\(snapshot.completedCount)/\(snapshot.totalDueCount) • \(snapshot.completionPercentage)%")
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            // Simplified Circles Row (Tap any circle to elaborate details)
            HStack(spacing: 8) {
                // 1. Overall Daily Ring
                Link(destination: URL(string: "productive://due-tasks?filter=all")!) {
                    miniCircle(
                        icon: isAllDone ? "checkmark" : "flame.fill",
                        fraction: fraction,
                        color: isAllDone ? .green : .white,
                        label: "\(snapshot.completionPercentage)%"
                    )
                }
                
                // 2. Morning Routine Circle
                if snapshot.morningTotal > 0 {
                    Link(destination: URL(string: "productive://due-tasks?filter=routine_morning")!) {
                        let mFrac = Double(snapshot.morningDone) / Double(snapshot.morningTotal)
                        miniCircle(
                            icon: snapshot.morningDone >= snapshot.morningTotal ? "checkmark" : "sunrise.fill",
                            fraction: mFrac,
                            color: snapshot.morningDone >= snapshot.morningTotal ? .green : .orange,
                            label: "\(snapshot.morningDone)/\(snapshot.morningTotal)"
                        )
                    }
                }
                
                // 3. Afternoon Routine Circle
                if snapshot.afternoonTotal > 0 {
                    Link(destination: URL(string: "productive://due-tasks?filter=routine_afternoon")!) {
                        let aFrac = Double(snapshot.afternoonDone) / Double(snapshot.afternoonTotal)
                        miniCircle(
                            icon: snapshot.afternoonDone >= snapshot.afternoonTotal ? "checkmark" : "sun.max.fill",
                            fraction: aFrac,
                            color: snapshot.afternoonDone >= snapshot.afternoonTotal ? .green : .yellow,
                            label: "\(snapshot.afternoonDone)/\(snapshot.afternoonTotal)"
                        )
                    }
                }
                
                // 4. Evening Routine Circle
                if snapshot.eveningTotal > 0 {
                    Link(destination: URL(string: "productive://due-tasks?filter=routine_evening")!) {
                        let eFrac = Double(snapshot.eveningDone) / Double(snapshot.eveningTotal)
                        miniCircle(
                            icon: snapshot.eveningDone >= snapshot.eveningTotal ? "checkmark" : "moon.stars.fill",
                            fraction: eFrac,
                            color: snapshot.eveningDone >= snapshot.eveningTotal ? .green : .indigo,
                            label: "\(snapshot.eveningDone)/\(snapshot.eveningTotal)"
                        )
                    }
                }
                
                // 5. Anytime Circle
                if snapshot.anytimeTotal > 0 {
                    Link(destination: URL(string: "productive://due-tasks?filter=routine_anytime")!) {
                        let anFrac = Double(snapshot.anytimeDone) / Double(snapshot.anytimeTotal)
                        miniCircle(
                            icon: snapshot.anytimeDone >= snapshot.anytimeTotal ? "checkmark" : "clock.fill",
                            fraction: anFrac,
                            color: snapshot.anytimeDone >= snapshot.anytimeTotal ? .green : .blue,
                            label: "\(snapshot.anytimeDone)/\(snapshot.anytimeTotal)"
                        )
                    }
                }
            }
        }
        .widgetURL(URL(string: "productive://due-tasks?filter=all"))
    }
    
    private func miniCircle(icon: String, fraction: Double, color: Color, label: String) -> some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 2.5)
                    .frame(width: 26, height: 26)
                Circle()
                    .trim(from: 0, to: CGFloat(fraction))
                    .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 26, height: 26)
                    .rotationEffect(.degrees(-90))
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(color)
            }
            Text(label)
                .font(.system(size: 7.5, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

// MARK: - 3. Lock Screen Inline (.accessoryInline)

struct LockScreenInlineWidgetView: View {
    let snapshot: WidgetDailySnapshot
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
            Text("\(snapshot.streakDays)d • \(snapshot.completedCount)/\(snapshot.totalDueCount) habits (\(snapshot.completionPercentage)%)")
        }
        .widgetURL(URL(string: "productive://due-tasks?filter=all"))
    }
}

// MARK: - 4. Home Screen Small (.systemSmall)

struct SystemSmallDailyProgressWidgetView: View {
    let snapshot: WidgetDailySnapshot
    
    var body: some View {
        let fraction = snapshot.totalDueCount > 0 ? Double(snapshot.completedCount) / Double(snapshot.totalDueCount) : 0.0
        let isAllDone = snapshot.totalDueCount > 0 && snapshot.completedCount >= snapshot.totalDueCount
        
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Focus")
                        .font(.system(size: 13.5, weight: .heavy, design: .rounded))
                    Text("\(snapshot.completedCount)/\(snapshot.totalDueCount) done")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.12), lineWidth: 3.5)
                        .frame(width: 36, height: 36)
                    Circle()
                        .trim(from: 0, to: CGFloat(fraction))
                        .stroke(isAllDone ? Color.green : Color.accentColor, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(-90))
                    Text("\(snapshot.completionPercentage)%")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                }
            }
            
            Spacer()
            
            if let next = snapshot.nextDueHabitName, !next.isEmpty, !isAllDone {
                VStack(alignment: .leading, spacing: 2) {
                    Text("UP NEXT")
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 5) {
                        Image(systemName: snapshot.nextDueHabitIcon ?? "sparkles")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: snapshot.nextDueHabitColorHex ?? "#007AFF"))
                        Text(next)
                            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                    }
                }
            } else if isAllDone {
                Text("All completed! 🎉")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.orange)
                Text("\(snapshot.streakDays)d Top Streak")
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3.5)
            .background(Color.orange.opacity(0.12), in: Capsule())
        }
        .padding(13)
        .widgetURL(URL(string: "productive://due-tasks?filter=all"))
    }
}

// MARK: - 5. Home Screen Medium (.systemMedium - Creative Orbit Circles)

struct SystemMediumDailyProgressWidgetView: View {
    let snapshot: WidgetDailySnapshot
    
    var body: some View {
        let fraction = snapshot.totalDueCount > 0 ? Double(snapshot.completedCount) / Double(snapshot.totalDueCount) : 0.0
        let isAllDone = snapshot.totalDueCount > 0 && snapshot.completedCount >= snapshot.totalDueCount
        
        HStack(spacing: 12) {
            // Left Hero Circular Gauge
            Link(destination: URL(string: "productive://due-tasks?filter=all")!) {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .stroke(Color.primary.opacity(0.12), lineWidth: 4.5)
                            .frame(width: 54, height: 54)
                        Circle()
                            .trim(from: 0, to: CGFloat(fraction))
                            .stroke(isAllDone ? Color.green : Color.accentColor, style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
                            .frame(width: 54, height: 54)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: -1) {
                            Text("\(snapshot.completionPercentage)%")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                            Text("\(snapshot.completedCount)/\(snapshot.totalDueCount)")
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text("Daily Focus")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                .frame(width: 64)
            }
            
            Divider()
                .frame(height: 60)
                .opacity(0.3)
            
            // Right Routine Orbit Circles
            HStack(spacing: 7) {
                routineCircle(title: "Morning", icon: "sunrise.fill", color: .orange, done: snapshot.morningDone, total: snapshot.morningTotal, filterKey: "routine_morning")
                routineCircle(title: "Afternoon", icon: "sun.max.fill", color: .yellow, done: snapshot.afternoonDone, total: snapshot.afternoonTotal, filterKey: "routine_afternoon")
                routineCircle(title: "Evening", icon: "moon.stars.fill", color: .indigo, done: snapshot.eveningDone, total: snapshot.eveningTotal, filterKey: "routine_evening")
                routineCircle(title: "Anytime", icon: "clock.fill", color: .blue, done: snapshot.anytimeDone, total: snapshot.anytimeTotal, filterKey: "routine_anytime")
            }
        }
        .padding(12)
    }
    
    private func routineCircle(title: String, icon: String, color: Color, done: Int, total: Int, filterKey: String) -> some View {
        let isDone = total > 0 && done >= total
        let fraction = total > 0 ? Double(done) / Double(total) : 0.0
        
        return Link(destination: URL(string: "productive://due-tasks?filter=\(filterKey)")!) {
            VStack(spacing: 3) {
                ZStack {
                    Circle()
                        .stroke(color.opacity(0.18), lineWidth: 3.2)
                        .frame(width: 36, height: 36)
                    Circle()
                        .trim(from: 0, to: CGFloat(fraction))
                        .stroke(isDone ? Color.green : color, style: StrokeStyle(lineWidth: 3.2, lineCap: .round))
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(-90))
                    Image(systemName: isDone ? "checkmark" : icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isDone ? Color.green : color)
                }
                Text(title)
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("\(done)/\(total)")
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundStyle(isDone ? Color.green : .secondary)
            }
            .frame(width: 44)
        }
    }
}

