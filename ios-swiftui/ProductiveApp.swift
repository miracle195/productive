//
//  ProductiveApp.swift
//  Productive - Daily Habit Tracker for iPhone 15 Pro
//  Created for iOS 17 / 18 with SwiftData and Dynamic Island
//  Supports First-Time Launch Initial Configuration Wizard
//

import SwiftUI

@main
struct ProductiveApp: App {
    @StateObject private var habitStore = HabitStore()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(habitStore)
                .preferredColorScheme(habitStore.appTheme == "Light" ? .light : .dark)
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var habitStore: HabitStore
    @AppStorage("productive_has_completed_onboarding") private var hasCompletedOnboarding: Bool = false
    @State private var selectedTab: TabItem = .today
    @State private var showingAddSheet: Bool = false
    
    enum TabItem {
        case today, settings
    }
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            } else {
                TabView(selection: $selectedTab) {
                    TodayView(showingAddSheet: $showingAddSheet)
                        .tabItem {
                            Label("Today", systemImage: "calendar")
                        }
                        .tag(TabItem.today)
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                        .tag(TabItem.settings)
                }
                .tint(Color(hex: "#007AFF"))
                .sheet(isPresented: $showingAddSheet) {
                    AddHabitSheet()
                        .environmentObject(habitStore)
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: hasCompletedOnboarding)
    }
}

//
//  OnboardingView.swift
//  First-Launch Initialization & Configuration Page
//  Allows user to set up Start Day of the Week, Theme, Strictness, and Haptics
//
struct OnboardingView: View {
    @EnvironmentObject var habitStore: HabitStore
    @Binding var hasCompletedOnboarding: Bool
    
    let weekDays = ["Monday", "Sunday", "Saturday"]
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    // Hero Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color(hex: "#5700CB"), Color(hex: "#0062E4")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 84, height: 84)
                                .shadow(color: Color(hex: "#5700CB").opacity(0.4), radius: 16, y: 8)
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 16)
                        
                        Text("Welcome to Productive")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundColor(.white)
                        
                        Text("Personalize your experience before starting. You can adjust these anytime in Settings.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    // Card 1: Start Day of the Week
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .foregroundColor(Color(hex: "#007AFF"))
                            Text("FIRST DAY OF THE WEEK")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 8) {
                            ForEach(weekDays, id: \.self) { day in
                                let isSelected = (habitStore.weekStartDay == day)
                                Button {
                                    habitStore.weekStartDay = day
                                    habitStore.triggerHaptic(.light)
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(day)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(isSelected ? .white : .primary)
                                        
                                        Text(day == "Monday" ? "Work week" : day == "Sunday" ? "Traditional" : "Weekend")
                                            .font(.system(size: 10))
                                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(isSelected ?
                                                  LinearGradient(colors: [Color(hex: "#5700CB"), Color(hex: "#0062E4")], startPoint: .leading, endPoint: .trailing) :
                                                  LinearGradient(colors: [Color.white.opacity(0.06)], startPoint: .top, endPoint: .bottom))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(18)
                    .background(Color(hex: "#1A1E30"))
                    .cornerRadius(20)
                    
                    // Card 2: App Theme
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Image(systemName: "paintpalette.fill")
                                .foregroundColor(Color(hex: "#923DFF"))
                            Text("APP THEME")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 12) {
                            ForEach(["Dark", "Light"], id: \.self) { theme in
                                let isSelected = (habitStore.appTheme == theme)
                                Button {
                                    habitStore.appTheme = theme
                                    habitStore.triggerHaptic(.light)
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: theme == "Dark" ? "moon.fill" : "sun.max.fill")
                                            .foregroundColor(theme == "Dark" ? Color(hex: "#923DFF") : Color(hex: "#F8BD32"))
                                        Text(theme)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(isSelected ? .white : .primary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(isSelected ?
                                                  LinearGradient(colors: [Color(hex: "#5700CB"), Color(hex: "#0062E4")], startPoint: .leading, endPoint: .trailing) :
                                                  LinearGradient(colors: [Color.white.opacity(0.06)], startPoint: .top, endPoint: .bottom))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(18)
                    .background(Color(hex: "#1A1E30"))
                    .cornerRadius(20)
                    
                    // Card 3: Default Habit Strictness
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(Color(hex: "#FF7450"))
                            Text("DEFAULT STRICTNESS MODE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 8) {
                            ForEach(HabitStrictness.allCases) { st in
                                let isSelected = (habitStore.defaultStrictnessRaw == st.rawValue)
                                Button {
                                    habitStore.defaultStrictnessRaw = st.rawValue
                                    habitStore.triggerHaptic(.light)
                                } label: {
                                    HStack {
                                        Text(st.badgeText)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(isSelected ? .white : .primary)
                                        Spacer()
                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(Color(hex: "#0FC580"))
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.04))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(18)
                    .background(Color(hex: "#1A1E30"))
                    .cornerRadius(20)
                    
                    // Card 4: Audio & Haptics Toggle
                    HStack {
                        HStack(spacing: 10) {
                            Image(systemName: "waveform")
                                .foregroundColor(Color(hex: "#0FC580"))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Tactile Haptics & Audio")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Feel every milestone and check-in")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Toggle("", isOn: $habitStore.soundHapticsEnabled)
                            .labelsHidden()
                            .tint(Color(hex: "#007AFF"))
                    }
                    .padding(18)
                    .background(Color(hex: "#1A1E30"))
                    .cornerRadius(20)
                    
                    // Floating Action Button: Get Started
                    Button {
                        habitStore.triggerHaptic(.success)
                        withAnimation(.easeInOut(duration: 0.35)) {
                            hasCompletedOnboarding = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("Get Started")
                                .font(.system(size: 16, weight: .heavy))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient(colors: [Color(hex: "#5700CB"), Color(hex: "#0062E4")], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(18)
                        .shadow(color: Color(hex: "#5700CB").opacity(0.5), radius: 14, y: 6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(hex: "#121524").ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
}
