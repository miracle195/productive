//
//  ProductiveApp.swift
//  Productive - Native SwiftUI Daily Habit Coach for iOS 17 / 18
//  4-Tab Cupertino Navigation, Semantic System/Dark/Light Themes & First-Launch Setup
//

import SwiftUI

@main
struct ProductiveApp: App {
    @StateObject private var habitStore = HabitStore.shared
    @Environment(\.scenePhase) private var scenePhase
    
    private var resolvedColorScheme: ColorScheme? {
        switch habitStore.appTheme {
        case "Light": return .light
        case "Dark": return .dark
        default: return nil // Respects iOS System Appearance
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(habitStore)
                .preferredColorScheme(resolvedColorScheme)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                habitStore.activeViewingDateKey = habitStore.todayKey
                habitStore.syncWidgetSnapshot()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            habitStore.activeViewingDateKey = habitStore.todayKey
            habitStore.syncWidgetSnapshot()
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "productive" else { return }
        
        let host = url.host ?? url.path
        if host.contains("due-tasks") {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let filterParam = components?.queryItems?.first(where: { $0.name == "filter" })?.value ?? "all"
            
            let filter: DueTasksPopupFilter
            switch filterParam {
            case "routine_morning", "morning":
                filter = .routine(.morning)
            case "routine_afternoon", "afternoon":
                filter = .routine(.afternoon)
            case "routine_evening", "evening":
                filter = .routine(.evening)
            case "routine_anytime", "anytime":
                filter = .routine(.anytime)
            default:
                if filterParam.hasPrefix("habit_") {
                    let uuidStr = String(filterParam.dropFirst(6))
                    if let uuid = UUID(uuidString: uuidStr) {
                        filter = .singleHabit(uuid)
                    } else {
                        filter = .all
                    }
                } else {
                    filter = .all
                }
            }
            
            habitStore.requestedDueTasksPopupFilter = filter
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var habitStore: HabitStore
    @AppStorage("productive_has_completed_onboarding") private var hasCompletedOnboarding: Bool = false
    @State private var selectedTab: TabItem = .today
    @State private var showingAddSheet: Bool = false
    
    enum TabItem: Hashable {
        case today, insights, challenges, settings
    }
    
    private var tabSelectionBinding: Binding<TabItem> {
        Binding(
            get: { selectedTab },
            set: { newTab in
                if newTab == .today && selectedTab == .today {
                    habitStore.refocusTodayRequestCount += 1
                }
                selectedTab = newTab
            }
        )
    }
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            } else {
                TabView(selection: tabSelectionBinding) {
                    TodayView(showingAddSheet: $showingAddSheet)
                        .tabItem {
                            Label("Today", systemImage: "checklist")
                        }
                        .badge(habitStore.remainingDueTodayCount)
                        .tag(TabItem.today)
                    
                    InsightsView()
                        .tabItem {
                            Label("Insights", systemImage: "chart.bar.xaxis")
                        }
                        .tag(TabItem.insights)
                    
                    ChallengesView()
                        .tabItem {
                            Label("Challenges", systemImage: "trophy.fill")
                        }
                        .tag(TabItem.challenges)
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                        .tag(TabItem.settings)
                }
                .sheet(isPresented: $showingAddSheet) {
                    AddHabitSheet()
                        .environmentObject(habitStore)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(28)
                }
            }
        }
        .animation(.snappy(duration: 0.35), value: hasCompletedOnboarding)
    }
}

// MARK: - Native Cupertino Onboarding Setup Sheet / View

struct OnboardingView: View {
    @EnvironmentObject var habitStore: HabitStore
    @Binding var hasCompletedOnboarding: Bool
    
    @State private var showingRestorePicker: Bool = false
    @State private var restoreMessage: String? = nil
    
    let weekDays = ["Monday", "Sunday", "Saturday"]
    let themes = ["System", "Dark", "Light"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#5700CB"), Color(hex: "#007AFF")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 76, height: 76)
                                .shadow(color: Color.blue.opacity(0.28), radius: 14, y: 6)
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundStyle(.white)
                                .symbolEffect(.bounce, value: habitStore.appTheme)
                        }
                        
                        Text("Welcome to Productive")
                            .font(.system(.title2, design: .rounded).weight(.heavy))
                            .foregroundStyle(.primary)
                        
                        Text("Tailor your native iOS habit coach. You can change any of these anytime in Settings.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .listRowBackground(Color.clear)
                }
                
                // MARK: - Restore / Recover Backup in Setup Wizard
                Section(
                    header: Label("Data Recovery", systemImage: "arrow.clockwise.icloud.fill"),
                    footer: Text("Reinstalling or recovering? Restore all your habits, completions, subtask progress, and streaks instantly.")
                ) {
                    if habitStore.hasLocalAutoBackup() {
                        Button {
                            if habitStore.restoreFromAutoBackup() {
                                habitStore.triggerHaptic(.success)
                                withAnimation(.snappy) {
                                    hasCompletedOnboarding = true
                                }
                            }
                        } label: {
                            HStack {
                                Label("Restore Previous Device Backup", systemImage: "arrow.triangle.2.circlepath")
                                Spacer()
                                Text("Restore")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    
                    Button {
                        showingRestorePicker = true
                    } label: {
                        HStack {
                            Label("Restore from Backup (.json)", systemImage: "square.and.arrow.down.fill")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section(
                    header: Label("Appearance", systemImage: "paintbrush.pointed.fill"),
                    footer: Text("System automatically matches your iPhone's Light & Dark schedule.")
                ) {
                    Picker("Appearance", selection: $habitStore.appTheme) {
                        ForEach(themes, id: \.self) { theme in
                            Text(theme).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Label("Calendar & Schedule", systemImage: "calendar")) {
                    Picker("First Day of Week", selection: $habitStore.weekStartDay) {
                        ForEach(weekDays, id: \.self) { day in
                            Text(day).tag(day)
                        }
                    }
                    
                    Picker("Default Strictness", selection: $habitStore.defaultStrictnessRaw) {
                        ForEach(HabitStrictness.allCases) { st in
                            Label(st.badgeText, systemImage: st.symbolName).tag(st.rawValue)
                        }
                    }
                }
                
                Section(
                    header: Label("Feedback & Reminders", systemImage: "bell.badge.fill"),
                    footer: Text("Includes 2 complimentary Streak Freeze Shields to protect life days.")
                ) {
                    Toggle("Tactile Haptics & Sounds", isOn: $habitStore.soundHapticsEnabled)
                    
                    Button {
                        NotificationManager.shared.requestPermission()
                    } label: {
                        HStack {
                            Label("Enable Smart Reminders", systemImage: "app.badge.checkmark")
                            Spacer()
                            if NotificationManager.shared.isAuthorized {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Text("Allow")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                    }
                }
            }
            .listSectionSpacing(12)
            .contentMargins(.top, 6, for: .scrollContent)
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button {
                    habitStore.triggerHaptic(.success)
                    withAnimation(.snappy) {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("Continue to Today")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                        Image(systemName: "arrow.right")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .background(.bar)
            }
            .fileImporter(
                isPresented: $showingRestorePicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let fileURL = urls.first else { return }
                    if fileURL.startAccessingSecurityScopedResource() {
                        defer { fileURL.stopAccessingSecurityScopedResource() }
                        if let data = try? Data(contentsOf: fileURL),
                           let json = String(data: data, encoding: .utf8) {
                            if habitStore.importJSON(json) {
                                habitStore.triggerHaptic(.success)
                                withAnimation(.snappy) {
                                    hasCompletedOnboarding = true
                                }
                            }
                        }
                    }
                case .failure:
                    break
                }
            }
        }
    }
}
