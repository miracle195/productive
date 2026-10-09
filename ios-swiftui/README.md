# Productive for iPhone 15 Pro (100% Native Swift & SwiftUI)

This directory contains the **complete, 100% native Swift & SwiftUI application** converted from Apalon's Productive Habit Tracker (`com.apalon.to.do.list`). Architected for **iOS 17 and iOS 18** on **iPhone 15 Pro**, featuring **SwiftUI**, **Combine/Observable**, **ActivityKit Dynamic Island**, **Cupertino Design System**, and **SF Symbols**.

---

## 📱 Complete Native Swift Architecture

```
ios-swiftui/
├── Productive.xcodeproj             # Fully configured Xcode Project ready to open & build
├── project.yml                      # Declarative XcodeGen specification
├── Info.plist                       # Target configuration, bundle identifier & capabilities
│
├── ProductiveApp.swift              # App Entry Point, Tab View & First-Launch Setup Wizard (OnboardingView)
│
├── Models/
│   ├── Habit.swift                  # Habit, Tracking Types, Strictness, Frequency & Per-Date Day Record
│   └── PresetsData.swift            # 14 Curated Categories & All 83 Curated Presets from Apalon Productive
│
├── ViewModels/
│   └── HabitStore.swift             # Observable Central State, Streaks, Isolation, Haptics & JSON Import/Export
│
├── Views/
│   ├── TodayView.swift              # Timeline Ribbon (Today on left, coming days on right, swipe right for backed days)
│   ├── HabitCardView.swift          # Card component: Checkmark, Progress Bar, Reps Steppers & Countdown Timer
│   ├── HabitDetailView.swift        # Performance metrics, streaks, 28-day completion heatmap, delete alert
│   ├── AddHabitSheet.swift          # Category-filtered presets explorer (83 presets), quick add & custom builder
│   ├── SettingsView.swift           # Calendar start day, strictness, theme, audio/haptics, JSON backup/restore
│   └── ChallengesView.swift         # Challenges roadmap and weekly insights
│
└── Widgets/
    └── DynamicIslandActivity.swift  # iPhone 15 Pro Dynamic Island ActivityKit Live Activity Widget
```

---

## ✨ Features Implemented in Full Swift

1. **Continuous Horizontally Scrollable Calendar Ribbon (`TodayView.swift`)**:
   - Anchored with **Today as the first pill on the left**.
   - **Coming days** (+1, +2, +3... +14 days ahead) extend directly to the right.
   - **Swipe right** to inspect backed (past) days (-1, -2, -3... -21 days ago) and check history.
   - Smooth animation returns to Today upon tapping "Back to Today".

2. **Complete 14 Categories & 83 Native Presets (`PresetsData.swift`, `AddHabitSheet.swift`)**:
   - Filter presets by 14 categories (`Must Have`, `Productive Morning`, `Better Sleep`, `Get Stuff Done`, `Healthy Eating`, `Stay Fit & Active`, etc.).
   - Tap `+ Add` to instantly add a preset to the timeline.
   - Tap the card to open it in the Custom Builder with all values pre-populated for full customization.

3. **Multi-Mode Habit Engine (`Habit.swift`, `HabitCardView.swift`)**:
   - **Simple Check**: 1-tap checkmark.
   - **Amount & Unit**: Target amount (e.g. 2000 ml, 30 mins, 20 pages), progress bar, and quick increment chips.
   - **Multiple Reps**: Visual rep dots with `[-]` and `[+]` steppers.
   - **Duration Timer**: Interactive Play/Pause countdown timer with remaining time and auto-completion.

4. **First-Launch Initialization Wizard (`ProductiveApp.swift`)**:
   - Automatically guides the user on first launch to configure First Day of Week, App Theme, Strictness Mode, and Sound/Haptics before entering the timeline.

5. **Strict Per-Date History Isolation (`HabitStore.swift`)**:
   - Every calendar date (`YYYY-MM-DD`) has independent logs, amount values, and completion statuses.

6. **Backup & Restore (`SettingsView.swift`)**:
   - 1-click JSON export and import with validation and haptic feedback.

---

## 🚀 How to Run & Build

### In Xcode (macOS):
1. Double-click `ios-swiftui/Productive.xcodeproj` to open directly in Xcode.
2. Select target device: **iPhone 15 Pro** (or any iOS 17+ device/simulator).
3. Press `Cmd + R` to run!

### Automated Cloud CI/CD (GitHub Actions):
- Every push to `main` automatically runs `.github/workflows/build-ios.yml` on macOS runners, building the signed/unsigned archive and producing `Productive.ipa`.
- The output is automatically copied to your Desktop: `C:\Users\JUSTME\Desktop\Productive.ipa`.
