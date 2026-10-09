//
//  TodayView.swift
//  Today Screen View with Weekday Ribbon, Past-Date Navigation, and Circular Adherence Gauge
//

import SwiftUI

public struct TodayView: View {
    @EnvironmentObject var habitStore: HabitStore
    @Binding var showingAddSheet: Bool
    @State private var selectedDayIndex = 3 // Thursday (Today)
    
    var days: [String] {
        if habitStore.weekStartDay == "Sunday" {
            return ["S", "M", "T", "W", "T", "F", "S"]
        } else if habitStore.weekStartDay == "Saturday" {
            return ["S", "S", "M", "T", "W", "T", "F"]
        } else {
            return ["M", "T", "W", "T", "F", "S", "S"]
        }
    }
    
    var dates: [String] {
        if habitStore.weekStartDay == "Sunday" {
            return ["20", "21", "22", "23", "24", "25", "26"]
        } else if habitStore.weekStartDay == "Saturday" {
            return ["19", "20", "21", "22", "23", "24", "25"]
        } else {
            return ["21", "22", "23", "24", "25", "26", "27"]
        }
    }
    
    var dayFullNames: [String] {
        if habitStore.weekStartDay == "Sunday" {
            return ["Sunday, Oct 20", "Monday, Oct 21", "Tuesday, Oct 22", "Wednesday, Oct 23", "Thursday, Oct 24", "Friday, Oct 25", "Saturday, Oct 26"]
        } else if habitStore.weekStartDay == "Saturday" {
            return ["Saturday, Oct 19", "Sunday, Oct 20", "Monday, Oct 21", "Tuesday, Oct 22", "Wednesday, Oct 23", "Thursday, Oct 24", "Friday, Oct 25"]
        } else {
            return ["Monday, Oct 21", "Tuesday, Oct 22", "Wednesday, Oct 23", "Thursday, Oct 24", "Friday, Oct 25", "Saturday, Oct 26", "Sunday, Oct 27"]
        }
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    
                    // Past Day Inspection Banner
                    if selectedDayIndex != 3 {
                        HStack {
                            Text("🗓️ Viewing: \(dayFullNames[selectedDayIndex]) (\(selectedDayIndex < 3 ? "Past Day" : "Upcoming"))")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "#F8BD32"))
                            
                            Spacer()
                            
                            Button("Back to Today") {
                                selectedDayIndex = 3
                                habitStore.triggerHaptic(.medium)
                            }
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(hex: "#F8BD32"))
                            .foregroundColor(Color(hex: "#121524"))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#F8BD32").opacity(0.12))
                        .cornerRadius(16)
                    }
                    
                    // Weekday Ribbon (Interactive Date Navigation)
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { index in
                            VStack(spacing: 6) {
                                Text(days[index])
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                Text(dates[index])
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(selectedDayIndex == index ? .white : .primary)
                                
                                Circle()
                                    .fill(index < 3 ? Color(hex: "#0FC580") : Color.clear)
                                    .frame(width: 5, height: 5)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(selectedDayIndex == index ?
                                          LinearGradient(colors: [Color(hex: "#5700CB"), Color(hex: "#0062E4")], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                          LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom))
                            )
                            .onTapGesture {
                                selectedDayIndex = index
                                habitStore.triggerHaptic(.light)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color(hex: "#1A1E30"))
                    .cornerRadius(20)
                    
                    // Motivational Progress Card
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(habitStore.completionPercentage >= 70 ? "You're crushing it! 🔥" : "Keep momentum going! 👏")
                                .font(.system(size: 18, weight: .heavy))
                                .foregroundColor(.white)
                            
                            Text("\(habitStore.habits.filter { $0.isCompleted }.count) of \(habitStore.habits.count) completed today")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                Text("14-Day Streak")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "#FF7450"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#FF7450").opacity(0.15))
                            .cornerRadius(10)
                        }
                        
                        Spacer()
                        
                        // Circular Gauge
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 7)
                                .frame(width: 72, height: 72)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(habitStore.completionPercentage) / 100.0)
                                .stroke(
                                    LinearGradient(colors: [Color(hex: "#5700CB"), Color(hex: "#0062E4")], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                                )
                                .frame(width: 72, height: 72)
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(), value: habitStore.completionPercentage)
                            
                            Text("\(habitStore.completionPercentage)%")
                                .font(.system(size: 15, weight: .heavy))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(20)
                    .background(Color(hex: "#1A1E30"))
                    .cornerRadius(24)
                    
                    // Habits by Day-Part
                    ForEach(TimeOfDay.allCases) { timeOfDay in
                        let filteredHabits = habitStore.habits.filter { $0.timeOfDay == timeOfDay }
                        if !filteredHabits.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: timeOfDay.icon)
                                        .foregroundColor(Color(hex: "#FF7450"))
                                    Text(timeOfDay.rawValue)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(filteredHabits.filter { $0.isCompleted }.count)/\(filteredHabits.count)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                
                                ForEach(filteredHabits) { habit in
                                    HabitCardView(habit: habit)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(Color(hex: "#121524").ignoresSafeArea())
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color(hex: "#1A1E30"))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
}
