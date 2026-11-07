//
//  SettingsView.swift
//  Productive - Native Cupertino Settings, Notifications, HealthKit, Archive & ShareLink Backups
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var habitStore: HabitStore
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var healthManager = HealthKitManager.shared
    
    @AppStorage("productive_has_completed_onboarding") private var hasCompletedOnboarding: Bool = true
    @State private var showingFileImporter: Bool = false
    @State private var showingResetAlert: Bool = false
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
                    Picker("Appearance", selection: $habitStore.appTheme) {
                        ForEach(themeOptions, id: \.self) { theme in
                            Text(theme).tag(theme)
                        }
                    }
                    
                    Toggle("Sounds & Tactile Haptics", isOn: $habitStore.soundHapticsEnabled)
                }
                
                // Calendar & Strictness
                Section(
                    header: Text("Calendar & Schedule"),
                    footer: Text("Strict locks missed past days; Rollover carries unfinished quotas into tomorrow.")
                ) {
                    Picker("First Day of Week", selection: $habitStore.weekStartDay) {
                        ForEach(weekDays, id: \.self) { day in
                            Text(day).tag(day)
                        }
                    }
                    
                    Picker("Default Habit Strictness", selection: $habitStore.defaultStrictnessRaw) {
                        ForEach(HabitStrictness.allCases) { st in
                            Label(st.badgeText, systemImage: st.symbolName).tag(st.rawValue)
                        }
                    }
                }
                
                // Streak Protection & Vacation Mode
                Section(
                    header: Text("Streak Protection"),
                    footer: Text("Earn +1 Streak Freeze Shield automatically every time any habit hits a 7-day streak milestone.")
                ) {
                    Toggle(isOn: $habitStore.vacationModeEnabled) {
                        Label("Vacation / Pause Mode", systemImage: "beach.umbrella.fill")
                    }
                    
                    HStack {
                        Label("Streak Freeze Shields", systemImage: "snowflake")
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
                    HStack {
                        Label("Push Notifications", systemImage: "bell.badge.fill")
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
                    
                    Toggle("Morning Kickoff (8:00 AM)", isOn: $habitStore.morningDigestEnabled)
                        .onChange(of: habitStore.morningDigestEnabled) { _, _ in
                            notificationManager.configureDailyDigests(
                                morningEnabled: habitStore.morningDigestEnabled,
                                eveningEnabled: habitStore.eveningDigestEnabled
                            )
                        }
                    
                    Toggle("Evening Wrap-Up (8:30 PM)", isOn: $habitStore.eveningDigestEnabled)
                        .onChange(of: habitStore.eveningDigestEnabled) { _, _ in
                            notificationManager.configureDailyDigests(
                                morningEnabled: habitStore.morningDigestEnabled,
                                eveningEnabled: habitStore.eveningDigestEnabled
                            )
                        }
                }
                
                // Apple HealthKit & Siri Shortcuts
                Section(
                    header: Text("Apple Ecosystem"),
                    footer: Text("Action Button & Siri Shortcuts are automatically registered via AppIntents.")
                ) {
                    HStack {
                        Label("Apple Health Sync", systemImage: "heart.text.square.fill")
                            .foregroundStyle(.pink)
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
                    
                    HStack {
                        Label("Action Button & Siri", systemImage: "button.vertical.left.press.fill")
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
                
                // Native iOS ShareLink & Files Importer
                Section(header: Text("Backup & Portability")) {
                    if let jsonBackup = habitStore.exportJSON() {
                        ShareLink(
                            item: jsonBackup,
                            subject: Text("Productive Full JSON Backup"),
                            message: Text("Productive Habit Tracker backup"),
                            preview: SharePreview("Productive_Backup.json", image: Image(systemName: "externaldrive.fill.badge.checkmark"))
                        ) {
                            Label("Share JSON Backup (Files / AirDrop)", systemImage: "square.and.arrow.up")
                        }
                    }
                    
                    ShareLink(
                        item: habitStore.exportCSV(),
                        subject: Text("Productive Habits CSV Export"),
                        preview: SharePreview("Productive_Habits.csv", image: Image(systemName: "tablecells.fill"))
                    ) {
                        Label("Export Spreadsheet (.CSV)", systemImage: "tablecells")
                    }
                    
                    Button {
                        showingFileImporter = true
                    } label: {
                        Label("Import Backup from Files", systemImage: "square.and.arrow.down")
                    }
                    
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        Label("Reset All Data & Preferences", systemImage: "trash")
                    }
                }
                
                // Setup & Version
                Section(header: Text("About")) {
                    Button {
                        hasCompletedOnboarding = false
                    } label: {
                        Label("Re-run Setup Wizard", systemImage: "sparkles")
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("3.2.2 Native SwiftUI")
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
                        showToast("Backup restored!")
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
