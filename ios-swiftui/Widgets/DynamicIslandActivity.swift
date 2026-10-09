//
//  DynamicIslandActivity.swift
//  iPhone 15 Pro Dynamic Island ActivityKit Widget
//  Provides native Live Activity pill and expanded Dynamic Island presentations
//

import ActivityKit
import WidgetKit
import SwiftUI

public struct HabitActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var currentHabitName: String
        public var progressText: String
        public var percentComplete: Double
        
        public init(currentHabitName: String, progressText: String, percentComplete: Double) {
            self.currentHabitName = currentHabitName
            self.progressText = progressText
            self.percentComplete = percentComplete
        }
    }
    
    public var habitCategory: String
    
    public init(habitCategory: String) {
        self.habitCategory = habitCategory
    }
}

public struct ProductiveLiveActivityWidget: Widget {
    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: HabitActivityAttributes.self) { context in
            // Lock Screen presentation
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#1B8FFF"))
                        .frame(width: 40, height: 40)
                    Image(systemName: "drop.fill")
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.currentHabitName)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Daily Routine • \(context.state.progressText)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(Int(context.state.percentComplete * 100))%")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "#0FC580"))
            }
            .padding(16)
            .background(Color(hex: "#121524"))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island on iPhone 15 Pro
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: "drop.fill")
                            .foregroundColor(Color(hex: "#1B8FFF"))
                        Text(context.state.currentHabitName)
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.progressText)
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(Color(hex: "#0FC580"))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.percentComplete)
                        .tint(Color(hex: "#0FC580"))
                        .padding(.top, 4)
                }
            } compactLeading: {
                // Compact Leading: Habit Icon
                Image(systemName: "drop.fill")
                    .foregroundColor(Color(hex: "#1B8FFF"))
            } compactTrailing: {
                // Compact Trailing: Progress
                Text("\(Int(context.state.percentComplete * 100))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#0FC580"))
            } minimal: {
                Image(systemName: "drop.fill")
                    .foregroundColor(Color(hex: "#1B8FFF"))
            }
        }
    }
}
