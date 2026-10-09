//
//  ChallengesView.swift & InsightsView.swift
//  Challenges Roadmap and Performance Analytics Views
//

import SwiftUI

public struct ChallengesView: View {
    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Hero Active Challenge
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ACTIVE CHALLENGE")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                        
                        Text("21-Day Morning Miracle")
                            .font(.system(size: 22, weight: .heavy))
                        
                        Text("Hydration, morning sunlight, and mindfulness to supercharge your energy levels.")
                            .font(.system(size: 13))
                            .opacity(0.9)
                        
                        ProgressView(value: 8, total: 21)
                            .tint(.white)
                        
                        Text("Day 8 of 21 • 62% Consistency")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .padding(24)
                    .foregroundColor(.white)
                    .background(
                        LinearGradient(colors: [Color(hex: "#FF416C"), Color(hex: "#8A2387")], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .cornerRadius(24)
                    
                    // Available Challenges
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Recommended Challenges")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        ChallengeRow(title: "Hydration Hero", subtitle: "Drink 2.5L water daily", duration: "14 Days", icon: "drop.fill", color: "#1B8FFF")
                        ChallengeRow(title: "Digital Detox & Sleep", subtitle: "No screens 1 hour before bed", duration: "7 Days", icon: "moon.fill", color: "#4C00B2")
                        ChallengeRow(title: "30-Day Fitness Momentum", subtitle: "Workout 30 mins each day", duration: "30 Days", icon: "figure.run", color: "#FF7450")
                    }
                }
                .padding(20)
            }
            .background(Color(hex: "#121524").ignoresSafeArea())
            .navigationTitle("Challenges")
        }
    }
}

struct ChallengeRow: View {
    let title: String
    let subtitle: String
    let duration: String
    let icon: String
    let color: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: color))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(duration)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "#007AFF"))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(hex: "#007AFF").opacity(0.12))
                .cornerRadius(10)
        }
        .padding(14)
        .background(Color(hex: "#1A1E30"))
        .cornerRadius(18)
    }
}

public struct InsightsView: View {
    let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    let heights: [CGFloat] = [75, 90, 85, 100, 60, 70, 80]
    
    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("94.8%")
                            .font(.system(size: 36, weight: .heavy))
                            .foregroundColor(.white)
                        Text("Overall Habit Consistency this month. You're in the top 5% of Productive users!")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(colors: [Color(hex: "#0062E4"), Color(hex: "#00C49F")], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .cornerRadius(24)
                    
                    // Weekly Bar Chart
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Weekly Adherence")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(alignment: .bottom, spacing: 12) {
                            ForEach(0..<7, id: \.self) { i in
                                VStack(spacing: 8) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(LinearGradient(colors: [Color(hex: "#5700CB"), Color(hex: "#0062E4")], startPoint: .top, endPoint: .bottom))
                                        .frame(height: heights[i])
                                    Text(days[i])
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 140)
                    }
                    .padding(20)
                    .background(Color(hex: "#1A1E30"))
                    .cornerRadius(20)
                }
                .padding(20)
            }
            .background(Color(hex: "#121524").ignoresSafeArea())
            .navigationTitle("Insights")
        }
    }
}
