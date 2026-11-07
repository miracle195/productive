# Productive v3.0 for iPhone 15 Pro (100% Native Swift & SwiftUI)

This directory contains the **complete, 100% native Swift & SwiftUI habit tracker** (`com.apalon.productive.tracker`) architected for **iOS 17 and iOS 18** on **iPhone 15 Pro**, built with **SwiftUI**, **Swift Charts**, **ActivityKit Dynamic Island**, **AppIntents (Siri & Action Button)**, **UserNotifications**, **HealthKit**, and semantic Cupertino materials.

---

## 📱 Native SwiftUI v3.0 Architecture

```
ios-swiftui/
├── Productive.xcodeproj             # Xcode 15.4+ Project (all 17 Swift sources registered)
├── project.yml                      # Declarative XcodeGen specification (v3.0.0)
├── Info.plist                       # Bundle configuration, Live Activities & HealthKit usage keys
│
├── ProductiveApp.swift              # Entry point, System/Dark/Light scheme, 4-Tab Bar & Onboarding Form
│
├── Models/
│   ├── Habit.swift                  # Polarity (Build/Quit/Limit), Schedules, Subtasks, Moods, Challenges & Badges
│   └── PresetsData.swift            # 14 Curated Categories & 83 Native SF Symbol Presets
│
├── ViewModels/
│   └── HabitStore.swift             # File-persisted v3 Engine, Streaks, Rollover, Freeze Shields & Live Focus Timer
│
├── Services/
│   ├── NotificationManager.swift    # UNUserNotificationCenter reminders, Digests & Lock Screen Quick Actions
│   └── HealthKitManager.swift       # Entitlement-safe Apple HealthKit sync bridge
│
├── Intents/
│   └── HabitAppIntents.swift        # Siri, Shortcuts & iPhone 15 Pro Action Button AppIntents
│
├── Views/
│   ├── TodayView.swift              # InsetGrouped List, Swipe Actions, Context Menus, Search, Calendar & Mini-Player
│   ├── HabitCardView.swift          # Semantic row with SF Symbol bounce, numeric transitions, subtasks & steppers
│   ├── HabitDetailView.swift        # Real 28-day date-keyed interactive heatmap, reflection journal & Edit/Archive
│   ├── AddHabitSheet.swift          # Searchable 83 presets + Custom/Edit Form (Polarity, Weekdays, Subtasks, Alerts)
│   ├── FocusTimerSheet.swift        # Countdown / Pomodoro 25m / Stopwatch dial + Mood & Note JournalEntrySheet
│   ├── RoutinePlayerSheet.swift     # Guided step-by-step Morning/Afternoon/Evening Routine playlist player
│   ├── InsightsView.swift           # Native Swift Charts (BarMark + RuleMark, SectorMark Donut) & 84-day heatmap
│   ├── ChallengesView.swift         # Joinable 7/14/21/30d multi-day challenges & 8 Milestone Achievement Badges
│   └── SettingsView.swift           # Cupertino Form, Vacation Mode, Shields, Notifications, Archive, ShareLink JSON/CSV
│
└── Widgets/
    └── DynamicIslandActivity.swift  # ActivityKit Live Activity & LiveActivityManager synced with Focus Timers
```

---

## ✨ Key Capabilities in v3.0

1. **True Cupertino UX & System Integration**:
   - Semantic Apple colors (`Color(.systemGroupedBackground)`, `Color(.secondarySystemGroupedBackground)`, `.regularMaterial`) with `System` / `Dark` / `Light` appearance.
   - `.insetGrouped` `List` with leading/trailing `.swipeActions`, long-press `.contextMenu`, `.onMove` drag reordering, `.searchable` pull-down filter, and `.datePickerStyle(.graphical)` date jump.
   - iOS 17/18 `.symbolEffect(.bounce)`, `.contentTransition(.numericText())`, and sheet `.presentationDetents`.
   - 4-tab layout (`Today` with live remaining `.badge`, `Insights`, `Challenges`, `Settings`).

2. **Deep Habit Coach Engine**:
   - **Polarity Modes**: `Build Habit`, `Quit / Abstain` (clean-day streak + slip logging), and `Daily Limit` (stay at/under budget).
   - **Smart Scheduling & Quotas**: Daily, Weekdays, Weekends, Every 2/3 Days, 3x/Week, Specific Custom Weekdays, Strict past-day locks, Flexible backfill, and **Rollover** quota carry-forward.
   - **Streak Protection**: Skip / Rest days, global **Vacation Mode**, and earnable **Streak Freeze Shields** (`+1` every 7-day streak milestone).
   - **Interactive Focus Timer & Guided Routines**: Timestamp-accurate Countdown, Pomodoro 25m, and Stopwatch with floating mini-player + step-by-step `▶ Routine` playlist player and Sub-Checklists.
   - **Reflection Journal, Challenges & Analytics**: Per-day Mood tags & notes, joinable multi-day challenges, 8 dynamic Milestone Badges, native `Charts`, and `ShareLink` JSON/CSV export + `.fileImporter`.

---

## 🚀 How to Build & Simulate

### 1. Live HTML iPhone 15 Pro Simulator (Root Workspace)
Open `../index.html` in any browser to test the 1:1 interactive counterpart alongside Swift development:
- Click **`🌱 Demo`** in the top Studio Toolbar to populate realistic multi-day habits, streaks, notes, and challenges.
- Click **`🔔 Push`** to test Lock Screen interactive notification quick actions (`✓ Mark Completed`, `⏰ Snooze 15m`).
- Click **`⚡ Action`** (or the left hardware Action Button on the iPhone frame) to trigger `LogNextHabitIntent`.
- Regenerate `app.js` anytime after editing `build_full_app.js` via `node build_full_app.js`.

### 2. Xcode & GitHub Actions IPA Build
- Open `ios-swiftui/Productive.xcodeproj` in Xcode 15.4+ on macOS (`Cmd + R`), or push to `main` to trigger `../.github/workflows/build-ios.yml` to archive and package `Productive.ipa`.
