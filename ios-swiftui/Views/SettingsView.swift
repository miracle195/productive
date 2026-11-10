//
//  SettingsView.swift
//  Productive - Native Cupertino Settings, Notifications, HealthKit, Archive & ShareLink Backups
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsIconBadge: View {
    let icon: String
    let gradientColors: [Color]
    
    init(icon: String, color: Color) {
        self.icon = icon
        self.gradientColors = [color, color.opacity(0.85)]
    }
    
    init(icon: String, gradient: [Color]) {
        self.icon = icon
        self.gradientColors = gradient
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7.5, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 30, height: 30)
                .overlay(
                    RoundedRectangle(cornerRadius: 7.5, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
            
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var habitStore: HabitStore
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var healthManager = HealthKitManager.shared
    
    @AppStorage("productive_has_completed_onboarding") private var hasCompletedOnboarding: Bool = true
    @State private var showingFileImporter: Bool = false
    @State private var showingResetAlert: Bool = false
    @State private var showingWidgetGuide: Bool = false
    @State private var toastMessage: String? = nil
    
    let weekDays = ["Monday", "Sunday", "Saturday"]
    let themeOptions = ["System", "Dark", "Light"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Pinned Non-Scrolling Settings Header
                HStack {
                    Text("Settings")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 12)
                .background(Color(.systemGroupedBackground))
                
                Divider()
                    .opacity(0.45)
                
                Form {
                    // Appearance & Feedback
                    Section(header: Text("Appearance & Haptics")) {
                        HStack(spacing: 12) {
                            SettingsIconBadge(icon: "circle.lefthalf.filled", color: Color(hex: "#FF9500"))
                            Picker("Appearance", selection: $habitStore.appTheme) {
                                ForEach(themeOptions, id: \.self) { theme in
                                    Text(theme).tag(theme)
                                }
                            }
                        }
                        
                        HStack(spacing: 12) {
                            SettingsIconBadge(icon: "speaker.wave.2.fill", color: Color(hex: "#34C759"))
                            Toggle("Sounds & Tactile Haptics", isOn: $habitStore.soundHapticsEnabled)
                        }
                    }
                    
                    // Calendar & Strictness
                    Section(
                        header: Text("Calendar & Schedule"),
                        footer: Text("Strict locks missed past days; Rollover carries unfinished quotas into tomorrow.")
                    ) {
                        HStack(spacing: 12) {
                            SettingsIconBadge(icon: "calendar", color: Color(hex: "#007AFF"))
                            Picker("First Day of Week", selection: $habitStore.weekStartDay) {
                                ForEach(weekDays, id: \.self) { day in
                                    Text(day).tag(day)
                                }
                            }
                        }
                        
                        HStack(spacing: 12) {
                            SettingsIconBadge(icon: "bolt.fill", color: Color(hex: "#AF52DE"))
                            Picker("Default Strictness", selection: $habitStore.defaultStrictnessRaw) {
                                ForEach(HabitStrictness.allCases) { st in
                                    Label(st.badgeText, systemImage: st.symbolName).tag(st.rawValue)
                                }
                            }
                        }
                    }
                    
                    // Streak Protection & Vacation Mode
                    Section(
                        header: Text("Streak Protection"),
                        footer: Text("Earn +1 Streak Freeze Shield automatically every time any habit hits a 7-day streak milestone.")
                    ) {
                        HStack(spacing: 12) {
                            SettingsIconBadge(icon: "beach.umbrella.fill", color: Color(hex: "#FF9F0A"))
                            Toggle(isOn: $habitStore.vacationModeEnabled) {
                                Text("Vacation / Pause Mode")
                            }
                        }
                        
                        HStack(spacing: 12) {
                            SettingsIconBadge(icon: "snowflake", color: Color(hex: "#32ADE6"))
                            Text("Streak Freeze Shields")
                            Spacer()
                            Text("\(habitStore.streakFreezeShields) available")
                                .foregroundStyle(.cyan)
                                .fontWeight(.bold)
                        }
                    }
                    
                    // Notifications & Daily Digests
                    Section(
                        header: Text("Notifications & Lock Screen Actions"),
                        footer: Text("Supports interactive Lock Screen quick actions: Mark Completed & Snooze 15m.")
                    ) {
                        HStack(spacing: 12) {
                            SettingsIconBadge(icon: "bell.badge.fill", color: Color(hex: "#FF3B30"))
                            Text("Push Notifications")
                            Spacer()
                            if notificationManager.isAuthorized {
                                Button("Test Banner") {
                                    notificationManager.sendTestNotification()
                                    showToast("Notification sent (1s) 🔔")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            } else {
                                Button("Enable") {
                                    notificationManager.requestPermission()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            SettingsIconBadge(icon: "sunrise.fill", color: Color(hex: "#FF9500"))
                            Toggle("Morning Kickoff (8:00 AM)", isOn: $habitStore.morningDigestEnabled)
                                .onChange(of: habitStore.morningDigestEnabled) { _, _ in
                                    notificationManager.configureDailyDigests(
                                        morningEnabled: habitStore.morningDigestEnabled,
                                        eveningEnabled: habitStore.eveningDigestEnabled
                                    )
                                }
                        }
                        
                        HStack(spacing: 12) {
                            SettingsIconBadge(icon: "moon.stars.fill", color: Color(hex: "#5856D6"))
                            Toggle("Evening Wrap-Up (8:30 PM)", isOn: $habitStore.eveningDigestEnabled)
                                .onChange(of: habitStore.eveningDigestEnabled) { _, _ in
                                    notificationManager.configureDailyDigests(
                                        morningEnabled: habitStore.morningDigestEnabled,
                                        eveningEnabled: habitStore.eveningDigestEnabled
                                    )
                                }
                        }
                    }
                    
                    // Apple HealthKit & Siri Shortcuts
                    Section(
                        header: Text("Apple Ecosystem"),
                        footer: Text("Action Button & Siri Shortcuts are automatically registered via AppIntents.")
                    ) {
                        HStack(spacing: 12) {
                            SettingsIconBadge(icon: "heart.fill", color: Color(hex: "#FF2D55"))
                            Text("Apple Health Sync")
                            Spacer()
                            if healthManager.isSyncEnabled {
                                Text("Active")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.green)
                            } else {
                                Button("Connect") {
                                    healthManager.requestConnect { _, msg in
                                        showToast(msg)
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            SettingsIconBadge(icon: "button.vertical.left.press.fill", color: Color(hex: "#64D2FF"))
                            Text("Action Button & Siri")
                            Spacer()
                            Text("Ready")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Archived Habits Manager
                    if !habitStore.archivedHabits.isEmpty {
                        Section(header: Text("Archived Habits (\(habitStore.archivedHabits.count))")) {
                            ForEach(habitStore.archivedHabits) { archived in
                                HStack {
                                    Image(systemName: archived.icon)
                                        .foregroundStyle(Color(hex: archived.colorHex))
                                    Text(archived.name)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Button("Restore") {
                                        habitStore.toggleArchiveHabit(id: archived.id)
                                        showToast("Restored \(archived.name)")
                                    }
                                    .font(.caption.weight(.bold))
                                    .buttonStyle(.bordered)
                                    .controlSize(.mini)
                                }
                            }
                        }
                    }
                    
                    // Lock Screen & System Widgets
                    Section(
                        header: Text("Lock Screen & System Widgets"),
                        footer: Text("Add circular or rectangular gauges to your iPhone Lock Screen to check daily progress at a glance. Tap any widget to pop up your due tasks.")
                    ) {
                        Button {
                            showingWidgetGuide = true
                            habitStore.triggerHaptic(.light)
                        } label: {
                            HStack(spacing: 12) {
                                SettingsIconBadge(icon: "lock.circle.fill", color: Color(hex: "#5856D6"))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("How to Add to Lock Screen")
                                        .foregroundStyle(.primary)
                                    Text("Step-by-step setup guide")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Button {
                            habitStore.syncWidgetSnapshot()
                            showToast("Widgets synchronized! 🔄")
                            habitStore.triggerHaptic(.success)
                        } label: {
                            HStack(spacing: 12) {
                                SettingsIconBadge(icon: "arrow.triangle.2.circlepath.circle.fill", color: Color(hex: "#34C759"))
                                Text("Sync Widget Timelines Now")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text("Real-time")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // Native iOS ShareLink & Files Importer
                    Section(
                        header: Text("Backup & Data Recovery"),
                        footer: Text("Your habits and progress are also auto-backed up to Documents. You can restore your data right here or from the Setup Wizard welcome screen anytime.")
                    ) {
                        Button {
                            habitStore.saveAutoBackupToDocuments()
                            showToast("Auto-backup saved to Documents! 🛡️")
                            habitStore.triggerHaptic(.success)
                        } label: {
                            HStack(spacing: 12) {
                                SettingsIconBadge(icon: "externaldrive.fill.badge.checkmark", color: Color(hex: "#007AFF"))
                                Text("Save Local Backup Now")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text("Documents")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if let jsonBackup = habitStore.exportJSON() {
                            ShareLink(
                                item: jsonBackup,
                                subject: Text("Productive Full JSON Backup"),
                                message: Text("Productive Habit Tracker backup"),
                                preview: SharePreview("Productive_Backup.json", image: Image(systemName: "externaldrive.fill.badge.checkmark"))
                            ) {
                                HStack(spacing: 12) {
                                    SettingsIconBadge(icon: "square.and.arrow.up.fill", color: Color(hex: "#5856D6"))
                                    Text("Share / AirDrop Backup (.json)")
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                        
                        Button {
                            showingFileImporter = true
                        } label: {
                            HStack(spacing: 12) {
                                SettingsIconBadge(icon: "square.and.arrow.down.fill", color: Color(hex: "#0FC580"))
                                Text("Restore Backup from File (.json)")
                                    .foregroundStyle(.primary)
                            }
                        }
                        
                        ShareLink(
                            item: habitStore.exportCSV(),
                            subject: Text("Productive Habits CSV Export"),
                            preview: SharePreview("Productive_Habits.csv", image: Image(systemName: "tablecells.fill"))
                        ) {
                            HStack(spacing: 12) {
                                SettingsIconBadge(icon: "tablecells.fill", color: Color(hex: "#34C759"))
                                Text("Export Spreadsheet (.csv)")
                                    .foregroundStyle(.primary)
                            }
                        }
                        
                        Button(role: .destructive) {
                            showingResetAlert = true
                        } label: {
                            HStack(spacing: 12) {
                                SettingsIconBadge(icon: "trash.fill", color: Color(hex: "#FF3B30"))
                                Text("Reset All Data & Preferences")
                            }
                        }
                    }
                    
                    // Setup & Version
                    Section(header: Text("Demo & Setup")) {
                        Button {
                            habitStore.seedRichDemoData()
                            showToast("Loaded Rich Demo Habits!")
                        } label: {
                            HStack(spacing: 12) {
                                SettingsIconBadge(icon: "sparkles", color: Color(hex: "#AF52DE"))
                                Text("Load Rich Demo Habits")
                                    .foregroundStyle(.primary)
                            }
                        }
                        
                        Button {
                            hasCompletedOnboarding = false
                        } label: {
                            HStack(spacing: 12) {
                                SettingsIconBadge(icon: "arrow.counterclockwise", color: Color(hex: "#007AFF"))
                                Text("Re-run Setup Wizard (Recover Data)")
                                    .foregroundStyle(.primary)
                            }
                        }
                        
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("3.2.20 Native SwiftUI (Build 24)")
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Text("Active / Archived Habits")
                            Spacer()
                            Text("\(habitStore.activeHabits.count) active • \(habitStore.archivedHabits.count) archived")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listSectionSpacing(16)
                .contentMargins(.top, 12, for: .scrollContent)
                .scrollContentBackground(.hidden)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingWidgetGuide) {
                LockScreenWidgetGuideSheet()
                    .environmentObject(habitStore)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(24)
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.json, .plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    let secured = url.startAccessingSecurityScopedResource()
                    defer { if secured { url.stopAccessingSecurityScopedResource() } }
                    if let data = try? Data(contentsOf: url),
                       let str = String(data: data, encoding: .utf8),
                       habitStore.importJSON(str) {
                        showToast("Backup restored successfully! 🎉")
                        habitStore.triggerHaptic(.success)
                    } else {
                        showToast("Could not decode backup file")
                    }
                case .failure:
                    showToast("Import cancelled")
                }
            }
            .alert("Reset All Data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset Everything", role: .destructive) {
                    habitStore.resetDefaults()
                    hasCompletedOnboarding = false
                }
            } message: {
                Text("This permanently clears all habits, logs, and challenge progress.")
            }
            .overlay(alignment: .top) {
                if let msg = toastMessage {
                    Text(msg)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.regularMaterial, in: Capsule())
                        .shadow(radius: 6)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }
    
    private func showToast(_ msg: String) {
        withAnimation { toastMessage = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { toastMessage = nil }
        }
    }
}

// MARK: - Lock Screen & System Widget Setup Guide Sheet

struct LockScreenWidgetGuideSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var habitStore: HabitStore
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color(hex: "#5856D6"), Color(hex: "#007AFF")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 56, height: 56)
                            Image(systemName: "lock.circle.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(.white)
                        }
                        
                        Text("Lock Screen Widget")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                        
                        Text("Keep your daily progress circles right on your iPhone lock screen. Tap any circle to pop up your due tasks.")
                            .font(.system(size: 13.5, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 16)
                    
                    // Widget Visual Previews
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AVAILABLE WIDGETS")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                        
                        HStack(spacing: 12) {
                            // Circular Preview
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.primary.opacity(0.15), lineWidth: 4)
                                        .frame(width: 50, height: 50)
                                    Circle()
                                        .trim(from: 0, to: 0.67)
                                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                        .frame(width: 50, height: 50)
                                        .rotationEffect(.degrees(-90))
                                    VStack(spacing: -1) {
                                        Image(systemName: "flame.fill")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.orange)
                                        Text("4d")
                                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                                    }
                                }
                                Text("Circular")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                Text("Ring & Streak")
                                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                            
                            // Rectangular Preview
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .stroke(Color.primary.opacity(0.15), lineWidth: 3)
                                            .frame(width: 32, height: 32)
                                        Circle()
                                            .trim(from: 0, to: 0.67)
                                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                            .frame(width: 32, height: 32)
                                            .rotationEffect(.degrees(-90))
                                        Text("67%")
                                            .font(.system(size: 8, weight: .bold))
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Daily Focus • 🔥4d")
                                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                        Text("Drink water (2L)")
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    }
                                }
                                Text("Rectangular")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                Text("Progress & Next Due")
                                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(14)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Step-by-Step Instructions
                    VStack(alignment: .leading, spacing: 14) {
                        Text("HOW TO IMPORT TO LOCK SCREEN")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                        
                        stepRow(num: "1", title: "Lock your iPhone & wake the screen", desc: "Touch and hold the Lock Screen until Customize appears.")
                        stepRow(num: "2", title: "Tap Customize & choose Lock Screen", desc: "Select your current wallpaper.")
                        stepRow(num: "3", title: "Tap the widget box below the clock", desc: "The widget gallery will slide up.")
                        stepRow(num: "4", title: "Scroll down and tap Productive", desc: "Select the Circular Gauge or Rectangular Widget.")
                        stepRow(num: "5", title: "Tap Done in the top-right corner", desc: "You're all set! Tap the widget anytime to view due tasks.")
                    }
                    .padding(.horizontal, 16)
                    
                    Button {
                        habitStore.syncWidgetSnapshot()
                        habitStore.triggerHaptic(.success)
                        dismiss()
                    } label: {
                        Text("Sync Widgets & Done")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Lock Screen Widgets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .bold))
                }
            }
        }
    }
    
    private func stepRow(num: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 26, height: 26)
                Text(num)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.accentColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Text(desc)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}
