//
//  DynamicIslandActivity.swift
//  iPhone 15 Pro Dynamic Island ActivityKit Widget & LiveActivityManager
//  Synced in real time with HabitStore Focus Timers, Routines, and Daily Progress
//

import ActivityKit
import WidgetKit
import SwiftUI

public struct HabitActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var currentHabitName: String
        public var iconName: String
        public var colorHex: String
        public var progressText: String
        public var percentComplete: Double
        public var timerEndDate: Date?
        
        public init(
            currentHabitName: String,
            iconName: String = "sparkles",
            colorHex: String = "#007AFF",
            progressText: String,
            percentComplete: Double,
            timerEndDate: Date? = nil
        ) {
            self.currentHabitName = currentHabitName
            self.iconName = iconName
            self.colorHex = colorHex
            self.progressText = progressText
            self.percentComplete = percentComplete
            self.timerEndDate = timerEndDate
        }
    }
    
    public var habitCategory: String
    
    public init(habitCategory: String) {
        self.habitCategory = habitCategory
    }
}

@MainActor
public final class LiveActivityManager {
    public static let shared = LiveActivityManager()
    private var currentActivity: Activity<HabitActivityAttributes>?
    
    private init() {}
    
    public func startOrUpdate(
        habitName: String,
        iconName: String,
        colorHex: String,
        category: String,
        progressText: String,
        percentComplete: Double,
        timerEndDate: Date? = nil
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let state = HabitActivityAttributes.ContentState(
            currentHabitName: habitName,
            iconName: iconName,
            colorHex: colorHex,
            progressText: progressText,
            percentComplete: min(1.0, max(0.0, percentComplete)),
            timerEndDate: timerEndDate
        )
        let content = ActivityContent(state: state, staleDate: nil)
        
        if let activity = currentActivity {
            Task {
                await activity.update(content)
            }
        } else {
            let attributes = HabitActivityAttributes(habitCategory: category)
            currentActivity = try? Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        }
    }
    
    public func endAll() {
        Task {
            for activity in Activity<HabitActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            currentActivity = nil
        }
    }
}

public struct ProductiveLiveActivityWidget: Widget {
    public init() {}
    
    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: HabitActivityAttributes.self) { context in
            // Lock Screen Live Activity Banner
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(hex: context.state.colorHex))
                        .frame(width: 42, height: 42)
                    Image(systemName: context.state.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(context.state.currentHabitName)
                        .font(.system(.headline, design: .rounded))
                    Text("\(context.attributes.habitCategory) • \(context.state.progressText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if let endDate = context.state.timerEndDate, endDate > Date() {
                    Text(timerInterval: Date()...endDate, countsDown: true)
                        .font(.system(.title3, design: .rounded).monospacedDigit().bold())
                        .foregroundStyle(Color(hex: context.state.colorHex))
                } else {
                    Text("\(Int(context.state.percentComplete * 100))%")
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundStyle(.green)
                }
            }
            .padding(16)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: context.state.iconName)
                            .foregroundStyle(Color(hex: context.state.colorHex))
                        Text(context.state.currentHabitName)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let endDate = context.state.timerEndDate, endDate > Date() {
                        Text(timerInterval: Date()...endDate, countsDown: true)
                            .font(.system(size: 14, weight: .heavy, design: .rounded).monospacedDigit())
                            .foregroundStyle(.orange)
                    } else {
                        Text(context.state.progressText)
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(.green)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.percentComplete)
                        .tint(Color(hex: context.state.colorHex))
                        .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: context.state.iconName)
                    .foregroundStyle(Color(hex: context.state.colorHex))
            } compactTrailing: {
                if let endDate = context.state.timerEndDate, endDate > Date() {
                    Text(timerInterval: Date()...endDate, countsDown: true)
                        .font(.system(size: 11, weight: .bold, design: .rounded).monospacedDigit())
                        .frame(maxWidth: 46)
                        .foregroundStyle(.orange)
                } else {
                    Text("\(Int(context.state.percentComplete * 100))%")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                }
            } minimal: {
                Image(systemName: context.state.iconName)
                    .foregroundStyle(Color(hex: context.state.colorHex))
            }
        }
    }
}
