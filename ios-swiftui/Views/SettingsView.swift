//
//  SettingsView.swift
//  Productive - Daily Habit Tracker
//  Cupertino Grouped Settings Screen for iPhone 15 Pro
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var habitStore: HabitStore
    @AppStorage("productive_has_completed_onboarding") private var hasCompletedOnboarding: Bool = true
    @State private var showingExportSheet: Bool = false
    @State private var exportedJSON: String = ""
    @State private var showingImportSheet: Bool = false
    @State private var importText: String = ""
    @State private var showingResetAlert: Bool = false
    @State private var showingToast: Bool = false
    @State private var toastMessage: String = ""
    
    let weekDays = ["Monday", "Sunday", "Saturday"]
    let themeOptions = ["Dark", "Light", "System"]
    
    var body: some View {
        NavigationStack {
            Form {
                // Calendar Preferences
                Section(header: Text("CALENDAR PREFERENCES"), footer: Text("Changes the first column day in your weekly adherence ribbon.")) {
                    Picker("Start Day of Week", selection: $habitStore.weekStartDay) {
                        ForEach(weekDays, id: \.self) { day in
                            Text(day).tag(day)
                        }
                    }
                    
                    Picker("Default Habit Strictness", selection: $habitStore.defaultStrictnessRaw) {
                        ForEach(HabitStrictness.allCases) { st in
                            Text(st.badgeText).tag(st.rawValue)
                        }
                    }
                }
                
                // Appearance & Sound
                Section(header: Text("APPEARANCE & SOUND")) {
                    Picker("App Theme", selection: $habitStore.appTheme) {
                        ForEach(themeOptions, id: \.self) { theme in
                            Text(theme).tag(theme)
                        }
                    }
                    
                    Toggle("Audio & Haptics", isOn: $habitStore.soundHapticsEnabled)
                }
                
                // Data Management
                Section(header: Text("DATA MANAGEMENT & BACKUP")) {
                    Button(action: {
                        if let json = habitStore.exportJSON() {
                            exportedJSON = json
                            showingExportSheet = true
                        }
                    }) {
                        HStack {
                            Label("Export Data Backup (JSON)", systemImage: "arrow.down.doc.fill")
                                .foregroundColor(.blue)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                    }
                    
                    Button(action: {
                        importText = ""
                        showingImportSheet = true
                    }) {
                        HStack {
                            Label("Import Data Backup", systemImage: "arrow.up.doc.fill")
                                .foregroundColor(.green)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                    }
                    
                    Button(role: .destructive, action: {
                        showingResetAlert = true
                    }) {
                        Label("Reset All Data to Defaults", systemImage: "trash.fill")
                    }
                }
                
                // Setup Wizard
                Section(header: Text("SETUP & CONFIGURATION")) {
                    Button(action: {
                        hasCompletedOnboarding = false
                    }) {
                        Label("Re-run Initial Setup Wizard", systemImage: "sparkles")
                            .foregroundColor(.blue)
                    }
                }
                
                // App Information
                Section(header: Text("ABOUT PRODUCTIVE")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("2.4.0 (iOS 18 Native)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Stored Habits")
                        Spacer()
                        Text("\(habitStore.habits.count) active habits")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Titanium Experience")
                        Spacer()
                        Text("iPhone 15 Pro")
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset All Data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset Defaults", role: .destructive) {
                    habitStore.resetDefaults()
                    hasCompletedOnboarding = false
                    triggerToast("All habits reset to defaults")
                }
            } message: {
                Text("This will restore default settings and restart the setup wizard.")
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportSheetView(jsonText: exportedJSON)
            }
            .sheet(isPresented: $showingImportSheet) {
                ImportSheetView(
                    importText: $importText,
                    onImport: { json in
                        if habitStore.importJSON(json) {
                            showingImportSheet = false
                            triggerToast("Data restored successfully!")
                        } else {
                            triggerToast("Invalid JSON backup format")
                        }
                    }
                )
            }
            .overlay(alignment: .top) {
                if showingToast {
                    Text(toastMessage)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .shadow(radius: 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 10)
                }
            }
        }
    }
    
    private func triggerToast(_ msg: String) {
        toastMessage = msg
        withAnimation { showingToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showingToast = false }
        }
    }
}

struct ExportSheetView: View {
    let jsonText: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("Copy or share your JSON backup data:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top)
                
                TextEditor(text: .constant(jsonText))
                    .font(.system(size: 12, design: .monospaced))
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                
                HStack {
                    Button(action: {
                        UIPasteboard.general.string = jsonText
                        dismiss()
                    }) {
                        Label("Copy to Clipboard", systemImage: "doc.on.doc.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                }
                .padding()
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ImportSheetView: View {
    @Binding var importText: String
    var onImport: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("Paste your exported JSON backup data here to restore your habits:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top)
                
                TextEditor(text: $importText)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                
                Button(action: {
                    onImport(importText)
                }) {
                    Label("Restore Habits", systemImage: "arrow.up.arrow.down.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(importText.isEmpty ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .disabled(importText.isEmpty)
                .padding()
            }
            .navigationTitle("Import Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
