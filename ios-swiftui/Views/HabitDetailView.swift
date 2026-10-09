//
//  HabitDetailView.swift
//  Detailed Habit Performance, Streak Stats, and Monthly Heatmap
//

import SwiftUI

public struct HabitDetailView: View {
    @EnvironmentObject var habitStore: HabitStore
    public let habit: Habit
    
    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Hero Header
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 26)
                            .fill(Color(hex: habit.colorHex))
                            .frame(width: 80, height: 80)
                            .shadow(color: Color(hex: habit.colorHex).opacity(0.4), radius: 15, y: 8)
                        
                        Image(systemName: habit.icon)
                            .font(.system(size: 38))
                            .foregroundColor(.white)
                    }
                    
                    Text(habit.name)
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Text("\(habit.repeatSchedule) • \(habit.timeOfDay.rawValue.uppercased()) • Goal: \(habit.goalText)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 10)
                
                // 2x2 Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    StatCard(label: "CURRENT STREAK", value: "\(habit.streak)d", color: Color(hex: "#FF7450"))
                    StatCard(label: "BEST STREAK", value: "\(habit.bestStreak)d", color: .white)
                    StatCard(label: "TOTAL LOGS", value: "\(habit.totalLogs)", color: .white)
                    StatCard(label: "CONSISTENCY", value: "94%", color: Color(hex: "#0FC580"))
                }
                
                // Monthly Heatmap Card
                VStack(alignment: .leading, spacing: 14) {
                    Text("Completion Heatmap (Last 28 Days)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(1...28, id: \.self) { day in
                            Text("\(day)")
                                .font(.system(size: 12, weight: .bold))
                                .frame(maxWidth: .infinity, minHeight: 36)
                                .background(day <= habit.streak ? Color(hex: "#0FC580") : Color.white.opacity(0.08))
                                .foregroundColor(day <= habit.streak ? .white : .secondary)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(18)
                .background(Color(hex: "#1A1E30"))
                .cornerRadius(20)
                
                // Check-in Action Button
                Button {
                    habitStore.toggleHabit(id: habit.id)
                } label: {
                    HStack {
                        Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                        Text(habit.isCompleted ? "Completed Today! 🎉" : "Log Check-in Now")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(colors: [Color(hex: "#5700CB"), Color(hex: "#0062E4")], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(18)
                }
            }
            .padding(20)
        }
        .background(Color(hex: "#121524").ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatCard: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 26, weight: .heavy))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(hex: "#1A1E30"))
        .cornerRadius(18)
    }
}
