//
//  ProductiveApp.swift
//  Productive - Daily Habit Tracker for iPhone 15 Pro
//  Created for iOS 17 / 18 with SwiftData and Dynamic Island
//

import SwiftUI

@main
struct ProductiveApp: App {
    @StateObject private var habitStore = HabitStore()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(habitStore)
                .preferredColorScheme(.dark)
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var habitStore: HabitStore
    @State private var selectedTab: TabItem = .today
    @State private var showingAddSheet: Bool = false
    
    enum TabItem {
        case today, settings
    }
    
    var body: some View {
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
