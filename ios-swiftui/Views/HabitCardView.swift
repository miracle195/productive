//
//  HabitCardView.swift
//  Interactive Multi-Mode Habit Card Component with Haptics
//  Strictly Isolated Per Calendar Date: completions, amounts, and reps
//

import SwiftUI

public struct HabitCardView: View {
    @EnvironmentObject var habitStore: HabitStore
    public let habit: Habit
    public var dateKey: String = ""
    
    private var activeDateKey: String {
        dateKey.isEmpty ? habitStore.todayKey : dateKey
    }
    
    private var isCompleted: Bool {
        habit.isCompleted(on: activeDateKey)
    }
    
    private var currentAmount: Double {
        habit.amount(on: activeDateKey)
    }
    
    private var currentReps: Int {
        habit.reps(on: activeDateKey)
    }
    
    public init(habit: Habit, dateKey: String = "") {
        self.habit = habit
        self.dateKey = dateKey
    }
    
    public var body: some View {
        NavigationLink(destination: HabitDetailView(habit: habit)) {
            VStack(alignment: .leading, spacing: 12) {
                // Top Row: Icon, Titles & Badges, Toggle Button
                HStack(spacing: 12) {
                    // Vibrant Icon Box
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: habit.colorHex))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: habit.icon)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    
                    // Habit Details & Metadata
                    VStack(alignment: .leading, spacing: 4) {
                        Text(habit.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(isCompleted ? .secondary : .primary)
                            .strikethrough(isCompleted)
                            .lineLimit(1)
                        
                        // Tag Badges Row
                        HStack(spacing: 6) {
                            Text(habit.repeatSchedule)
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(6)
                                .foregroundColor(.secondary)
                            
                            Text(habit.strictness.badgeText)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(badgeBackgroundColor(for: habit.strictness))
                                .cornerRadius(6)
                                .foregroundColor(badgeTextColor(for: habit.strictness))
                            
                            HStack(spacing: 2) {
                                Text("🔥")
                                Text("\(habit.streak)d")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: "#FF7450"))
                        }
                    }
                    
                    Spacer()
                    
                    // Checkmark Toggle Button (strictly bound to activeDateKey)
                    Button {
                        habitStore.toggleHabit(id: habit.id, on: activeDateKey)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(isCompleted ? Color(hex: "#0FC580") : Color.clear)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(isCompleted ? Color(hex: "#0FC580") : Color.white.opacity(0.18), lineWidth: 2)
                                )
                            
                            if isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Multi-Mode Body Section
                if habit.trackingType == .amount {
                    VStack(spacing: 6) {
                        HStack {
                            Text("\(Int(currentAmount)) / \(Int(habit.targetAmount)) \(habit.unit)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                            Spacer()
                            let pct = min(100, Int((currentAmount / max(1, habit.targetAmount)) * 100))
                            Text("\(pct)%")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: "#0FC580"))
                        }
                        
                        // Progress Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 6)
                                
                                let fillRatio = min(1.0, currentAmount / max(1, habit.targetAmount))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(LinearGradient(colors: [Color(hex: "#1B8FFF"), Color(hex: "#0FC580")], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: max(0, geo.size.width * CGFloat(fillRatio)), height: 6)
                            }
                        }
                        .frame(height: 6)
                        
                        // Quick Increment Chips
                        if !isCompleted {
                            HStack(spacing: 8) {
                                Button {
                                    habitStore.incrementAmount(id: habit.id, step: habit.stepAmount, on: activeDateKey)
                                } label: {
                                    Text("+\(Int(habit.stepAmount)) \(habit.unit)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button {
                                    habitStore.incrementAmount(id: habit.id, step: habit.stepAmount * 2, on: activeDateKey)
                                } label: {
                                    Text("+\(Int(habit.stepAmount * 2)) \(habit.unit)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Spacer()
                            }
                            .padding(.top, 2)
                        }
                    }
                    .padding(.top, 2)
                } else if habit.trackingType == .reps {
                    HStack {
                        // Rep Dots
                        HStack(spacing: 5) {
                            ForEach(1...max(1, habit.targetReps), id: \.self) { r in
                                Circle()
                                    .fill(r <= currentReps ? Color(hex: "#0FC580") : Color.white.opacity(0.15))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        
                        Spacer()
                        
                        // Stepper Buttons
                        HStack(spacing: 8) {
                            Button {
                                habitStore.stepReps(id: habit.id, delta: -1, on: activeDateKey)
                            } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text("\(currentReps) / \(habit.targetReps)")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundColor(.white)
                                .frame(minWidth: 44)
                            
                            Button {
                                habitStore.stepReps(id: habit.id, delta: 1, on: activeDateKey)
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.top, 2)
                } else if habit.trackingType == .timer {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "timer")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#FF7450"))
                            Text("\(habit.targetDurationMinutes) mins target")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            habitStore.toggleHabit(id: habit.id, on: activeDateKey)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: isCompleted ? "checkmark.circle.fill" : "play.fill")
                                    .font(.system(size: 11, weight: .bold))
                                Text(isCompleted ? "Session Done 🎉" : "Start \(habit.targetDurationMinutes)m")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isCompleted ?
                                        LinearGradient(colors: [Color(hex: "#0FC580"), Color(hex: "#00B4DB")], startPoint: .leading, endPoint: .trailing) :
                                        LinearGradient(colors: [Color(hex: "#5700CB"), Color(hex: "#0062E4")], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.top, 2)
                }
            }
            .padding(14)
            .background(Color(hex: "#1A1E30").opacity(isCompleted ? 0.6 : 1.0))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isCompleted ? Color.white.opacity(0.04) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func badgeBackgroundColor(for strictness: HabitStrictness) -> Color {
        switch strictness {
        case .strict: return Color(hex: "#FF5A5F").opacity(0.15)
        case .flexible: return Color(hex: "#0FC580").opacity(0.15)
        case .rollover: return Color(hex: "#923DFF").opacity(0.15)
        }
    }
    
    private func badgeTextColor(for strictness: HabitStrictness) -> Color {
        switch strictness {
        case .strict: return Color(hex: "#FF5A5F")
        case .flexible: return Color(hex: "#0FC580")
        case .rollover: return Color(hex: "#923DFF")
        }
    }
}
