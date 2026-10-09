//
//  TodayView.swift
//  Today Screen View with Dynamic Real-World Calendar Ribbon,
//  Strict Per-Date Isolation, and Clean Start Empty State
//

import SwiftUI

public struct DayModel: Identifiable, Equatable {
    public let id: Int
    public let date: Date
    public let dayLetter: String
    public let dayNumber: String
    public let dateKey: String
    public let fullDateName: String
    public let isToday: Bool
}

public struct TodayView: View {
    @EnvironmentObject var habitStore: HabitStore
    @Binding var showingAddSheet: Bool
    @State private var selectedDateKey: String? = nil
    
    var timelineDays: [DayModel] {
        let calendar = Calendar.current
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        
        let dayLetterFormatter = DateFormatter()
        dayLetterFormatter.dateFormat = "EEE"
        dayLetterFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let dayNumberFormatter = DateFormatter()
        dayNumberFormatter.dateFormat = "d"
        dayNumberFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let fullFormatter = DateFormatter()
        fullFormatter.dateFormat = "EEEE, MMM d"
        fullFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        // 21 backed days in past (-21 to -1), Today (0), and 14 coming days in future (+1 to +14)
        return (-21...14).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: todayStart) else { return nil }
            let isToday = (offset == 0)
            return DayModel(
                id: offset,
                date: date,
                dayLetter: isToday ? "TODAY" : dayLetterFormatter.string(from: date).uppercased(),
                dayNumber: dayNumberFormatter.string(from: date),
                dateKey: HabitStore.dateFormatter.string(from: date),
                fullDateName: fullFormatter.string(from: date),
                isToday: isToday
            )
        }
    }
    
    var activeDateKey: String {
        selectedDateKey ?? habitStore.todayKey
    }
    
    var activeDay: DayModel? {
        timelineDays.first(where: { $0.dateKey == activeDateKey })
    }
    
    var isViewingToday: Bool {
        activeDateKey == habitStore.todayKey
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    
                    // Date & Active Screen Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text((activeDay?.fullDateName ?? "Today").uppercased())
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(isViewingToday ? "Today's Habits" : "\(activeDay?.dayLetter ?? "") \(activeDay?.dayNumber ?? "") Habits")
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 4)
                    
                    // Past/Future Date Inspection Banner
                    if !isViewingToday, let day = activeDay {
                        HStack {
                            let isPast = day.date < Date()
                            Text("🗓️ Viewing: \(day.fullDateName) (\(isPast ? "Past Day" : "Upcoming"))")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "#F8BD32"))
                            
                            Spacer()
                            
                            Button("Back to Today") {
                                selectedDateKey = habitStore.todayKey
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
                    
                    // Weekday Ribbon (Horizontally Scrollable Dynamic Timeline)
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(timelineDays) { day in
                                    let isSelected = (day.dateKey == activeDateKey)
                                    let isFuture = day.id > 0
                                    VStack(spacing: 5) {
                                        Text(day.dayLetter)
                                            .font(.system(size: 9, weight: .heavy))
                                            .foregroundColor(day.isToday ? Color(hex: "#007AFF") : (isFuture ? .secondary.opacity(0.65) : .secondary))
                                        
                                        Text(day.dayNumber)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(isSelected ? .white : (day.isToday ? Color(hex: "#007AFF") : (isFuture ? .primary.opacity(0.7) : .primary)))
                                        
                                        Circle()
                                            .fill(habitStore.completionPercentage(on: day.dateKey) > 0 ? Color(hex: "#0FC580") : Color.clear)
                                            .frame(width: 5, height: 5)
                                    }
                                    .frame(width: 48)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(isSelected ?
                                                  LinearGradient(colors: [Color(hex: "#5700CB"), Color(hex: "#0062E4")], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                                  LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom))
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedDateKey = day.dateKey
                                        habitStore.triggerHaptic(.light)
                                    }
                                    .id(day.dateKey)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                        }
                        .background(Color(hex: "#1A1E30"))
                        .cornerRadius(20)
                        .onAppear {
                            DispatchQueue.main.async {
                                proxy.scrollTo(habitStore.todayKey, anchor: .leading)
                            }
                        }
                        .onChange(of: activeDateKey) { newDateKey in
                            if newDateKey == habitStore.todayKey {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    proxy.scrollTo(habitStore.todayKey, anchor: .leading)
                                }
                            }
                        }
                    }
                    
                    // Motivational Progress Card
                    let completionPct = habitStore.completionPercentage(on: activeDateKey)
                    let completedCount = habitStore.habits.filter { $0.isCompleted(on: activeDateKey) }.count
                    let totalCount = habitStore.habits.count
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(completionPct == 100 && totalCount > 0 ? "All goals crushed! 🎉" :
                                 completionPct >= 70 ? "You're crushing it! 🔥" :
                                 completionPct > 0 ? "Keep momentum going! 👏" :
                                 totalCount == 0 ? "Ready to begin! ✨" : "Start your day strong! 🚀")
                                .font(.system(size: 18, weight: .heavy))
                                .foregroundColor(.white)
                            
                            Text(totalCount > 0 ? "\(completedCount) of \(totalCount) completed \(isViewingToday ? "today" : "on this date")" : "No habits added yet")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                Text(isViewingToday ? "Daily Focus" : "\(activeDay?.dayLetter ?? "") Routine")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "#FF7450"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#FF7450").opacity(0.15))
                            .cornerRadius(10)
                        }
                        
                        Spacer()
                        
                        // Circular Progress Gauge
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 7)
                                .frame(width: 72, height: 72)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(completionPct) / 100.0)
                                .stroke(
                                    LinearGradient(colors: [Color(hex: "#5700CB"), Color(hex: "#0062E4")], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                                )
                                .frame(width: 72, height: 72)
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(), value: completionPct)
                            
                            Text("\(completionPct)%")
                                .font(.system(size: 15, weight: .heavy))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(20)
                    .background(Color(hex: "#1A1E30"))
                    .cornerRadius(24)
                    
                    // Habits List or Clean Start Empty State
                    if habitStore.habits.isEmpty {
                        // Empty State: prompt user to create their first habit
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [Color(hex: "#5700CB").opacity(0.3), Color(hex: "#0062E4").opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "sparkles")
                                    .font(.system(size: 36))
                                    .foregroundColor(Color(hex: "#0062E4"))
                            }
                            .padding(.top, 16)
                            
                            VStack(spacing: 8) {
                                Text("No Habits Yet")
                                    .font(.system(size: 20, weight: .heavy))
                                    .foregroundColor(.white)
                                
                                Text("Your timeline is fresh! Choose from popular curated presets or build your custom routine.")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                            
                            Button {
                                showingAddSheet = true
                                habitStore.triggerHaptic(.medium)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 15, weight: .bold))
                                    Text("Add Your First Habit")
                                        .font(.system(size: 15, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .background(LinearGradient(colors: [Color(hex: "#5700CB"), Color(hex: "#0062E4")], startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(18)
                                .shadow(color: Color(hex: "#5700CB").opacity(0.4), radius: 10, y: 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.bottom, 16)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .background(Color(hex: "#1A1E30"))
                        .cornerRadius(24)
                    } else {
                        // Habits grouped by Time of Day
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
                                        let bucketCompleted = filteredHabits.filter { $0.isCompleted(on: activeDateKey) }.count
                                        Text("\(bucketCompleted)/\(filteredHabits.count)")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    ForEach(filteredHabits) { habit in
                                        HabitCardView(habit: habit, dateKey: activeDateKey)
                                    }
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
