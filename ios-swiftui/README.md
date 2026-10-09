# Productive for iPhone 15 Pro (iOS 17+)

This directory contains the native Swift / SwiftUI source code converted from the Android application package (`com.apalon.to.do.list`). It is specifically architected for **iPhone 15 Pro** with support for **Dynamic Island Live Activities**, **SwiftData / Observable state**, **iOS 17+ Haptics**, and **SF Symbols**.

---

## 📱 Project Architecture

```
ios-swiftui/
├── ProductiveApp.swift              # App Entry Point & Tab Navigation
├── Models/
│   └── Habit.swift                  # Habit, TimeOfDay, Category entities & Color extensions
├── ViewModels/
│   └── HabitStore.swift             # Observable state manager with streaks & haptics
├── Views/
│   ├── TodayView.swift              # Today habits, weekly ribbon & progress ring
│   ├── HabitCardView.swift          # Card component with completion animation
│   ├── HabitDetailView.swift        # Performance metrics, streaks, calendar heatmap
│   ├── AddHabitSheet.swift          # Cupertino sheet with presets and habit builder
│   └── ChallengesView.swift         # Challenges roadmap and weekly insights
├── Widgets/
│   └── DynamicIslandActivity.swift  # iPhone 15 Pro Dynamic Island ActivityKit widget
└── README.md                        # Documentation & setup guide
```

---

## 🚀 How to Run on iPhone 15 Pro

### Option 1: Run via Xcode (Mac)
1. Open **Xcode 15+** on your Mac.
2. Create a new iOS project: **File > New > Project > App** (named `Productive`, Interface: SwiftUI, Language: Swift).
3. Drag and drop all files from this `ios-swiftui/` folder into your Xcode project navigator.
4. Select target device: **iPhone 15 Pro** or **iPhone 15 Pro Simulator**.
5. Press `Cmd + R` to build and run.

### Option 2: Sideload to iPhone 15 Pro with Sideloadly (Windows)
1. Open **Sideloadly** (installed on your Windows Desktop).
2. Connect your iPhone 15 Pro via USB-C cable.
3. If you have an exported IPA, drag and drop the `.ipa` file into Sideloadly, enter your Apple ID, and click **Start**.

---

## 🌐 Instant Web Simulator (Runs right now on Windows!)
You can also run the high-fidelity interactive **iPhone 15 Pro Web Simulator** located in the root workspace directory:
- Open [`index.html`](../index.html) in any browser (Chrome, Edge, Safari).
- Or view via local server at `http://localhost:8888`.
- Experience the physical Natural Titanium chassis, clickable Action Button, expanding Dynamic Island, and audio effects directly on your screen!
