const fs = require('fs');

console.log('Generating index.html with zero overlap layout and segmented custom habit builder...');

const indexHtml = `<!DOCTYPE html>
<html lang="en" data-app-theme="dark" data-finish="natural">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
  <title>Productive — iPhone 15 Pro (iOS 18) Experience</title>
  <meta name="description" content="High-fidelity simulation of Apalon's Productive Habit Tracker on iPhone 15 Pro running iOS 18 with multi-mode habit tracking, Dynamic Island Live Activity, and haptics.">

  <!-- Apple iOS Mobile Web App Fullscreen Support -->
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
  <meta name="apple-mobile-web-app-title" content="Productive">
  <link rel="apple-touch-icon" href="apple-touch-icon.png">
  <link rel="icon" type="image/png" href="icon.png">
  <link rel="manifest" href="manifest.json">

  <!-- Preconnect to Fonts -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>

  <!-- Stylesheet -->
  <link rel="stylesheet" href="styles.css">
</head>
<body>

  <!-- =========================================================================
       STUDIO PRESENTATION ENVIRONMENT
       ========================================================================= -->
  <div class="studio-wrapper">

    <!-- Ambient Dynamic Glows -->
    <div class="ambient-glow glow-purple"></div>
    <div class="ambient-glow glow-blue"></div>
    <div class="ambient-glow glow-emerald"></div>

    <!-- Studio Header & Controls -->
    <header class="studio-header">
      <div class="brand-badge">
        <div class="brand-logo-icon">P</div>
        <div class="brand-info">
          <h1>Productive <span class="badge-pill">iPhone 15 Pro • iOS 18</span></h1>
          <p>Multi-Mode Habit Tracker Engine & Native Architecture</p>
        </div>
      </div>

      <!-- Studio Floating Toolbar -->
      <div class="studio-toolbar" role="toolbar" aria-label="Simulator Controls">
        <!-- Titanium Finish Dots -->
        <div class="finish-dots" title="iPhone 15 Pro Titanium Finish">
          <div class="finish-dot dot-natural active" data-finish="natural" onclick="setDeviceFinish('natural')" title="Natural Titanium"></div>
          <div class="finish-dot dot-blue" data-finish="blue" onclick="setDeviceFinish('blue')" title="Blue Titanium"></div>
          <div class="finish-dot dot-white" data-finish="white" onclick="setDeviceFinish('white')" title="White Titanium"></div>
          <div class="finish-dot dot-black" data-finish="black" onclick="setDeviceFinish('black')" title="Black Titanium"></div>
        </div>

        <div style="width: 1px; height: 18px; background: rgba(255,255,255,0.15); margin: 0 4px;"></div>

        <!-- Theme Toggle -->
        <button class="tool-btn" id="tool-theme-btn" onclick="toggleTheme()" title="Toggle iOS Dark / Light Mode">
          🌙 Dark
        </button>

        <!-- Sound Toggle -->
        <button class="tool-btn" id="tool-sound-btn" onclick="toggleSound()" title="Toggle Synthesized iOS Audio">
          🔊 Sound: ON
        </button>

        <!-- Action Button Helper -->
        <button class="tool-btn" onclick="triggerActionButton()" title="Trigger Action Button / Spacebar">
          ⚡ Action
        </button>
      </div>
    </header>

    <!-- Main Stage Container -->
    <main class="stage-container">

      <!-- =====================================================================
           IPHONE 15 PRO HARDWARE CHASSIS
           ===================================================================== -->
      <div class="iphone-frame" id="iphone-chassis">

        <!-- Hardware Buttons -->
        <div class="hw-button btn-action" id="hw-action-btn" title="Titanium Action Button: Quick Log Next Habit (or press Space)"></div>
        <div class="hw-button btn-volume-up" title="Volume Up"></div>
        <div class="hw-button btn-volume-down" title="Volume Down"></div>
        <div class="hw-button btn-power" onclick="toggleDynamicIsland()" title="Side Button"></div>

        <!-- Inner Screen Bezel -->
        <div class="screen-bezel">

          <!-- OLED Screen Display (FLEX CONTAINER - ZERO OVERLAPS) -->
          <div class="screen-display" id="screen-display">

            <!-- Confetti Canvas -->
            <canvas id="confetti-canvas"></canvas>

            <!-- Toast Banner -->
            <div class="ios-toast" id="ios-toast">
              <span>✨</span>
              <span class="toast-msg">Habit logged!</span>
            </div>

            <!-- DYNAMIC ISLAND (TOP-LEVEL OVERLAY) -->
            <div class="dynamic-island-container">
              <div class="dynamic-island" id="dynamic-island" title="Dynamic Island: Click to Expand / Collapse Live Activity">
                
                <div class="island-compact-view">
                  <div class="island-camera"></div>
                  <div id="island-pulse-title" style="color: #0FC580; font-size: 11px; font-weight: 700; display: flex; align-items: center; gap: 4px;">
                    <span>🔥</span>
                    <span>Productive</span>
                  </div>
                  <div class="island-sensor"></div>
                </div>

                <div class="island-expanded-view">
                  <div class="island-header">
                    <div class="island-habit-info">
                      <div class="island-habit-icon">
                        <svg width="22" height="22" viewBox="0 0 24 24" fill="#FFFFFF">
                          <path d="M5.23 2C4.04 2 3.11 3.04 3.24 4.22l1.77 16.01C5.13 21.23 5.97 22 7 22h10c1.03 0 1.87-0.77 1.99-1.77l1.77-16.01C20.89 3.04 19.96 2 18.77 2H5.23zM12 19c-1.66 0-3-1.34-3-3 0-1.55 1.81-3.95 2.62-4.94 0.2-0.25 0.57-0.25 0.77 0 0.81 1 2.62 3.39 2.62 4.94-0.01 1.66-1.35 3-3.01 3z"/>
                        </svg>
                      </div>
                      <div>
                        <div class="island-habit-title">Drink water (2L)</div>
                        <div class="island-habit-sub">Live Activity • Morning Routine</div>
                      </div>
                    </div>
                    <div class="island-timer-badge">1.5 / 2.0L</div>
                  </div>

                  <div class="island-footer">
                    <span style="font-size: 11px; color: #8E99B0;">Tap Action Button or button below</span>
                    <button class="island-quick-btn">+ Quick Log</button>
                  </div>
                </div>

              </div>
            </div>

            <!-- iOS 18 STATUS BAR (FIXED TOP HEADER) -->
            <div class="ios-status-bar">
              <span class="status-time" id="status-time-clock">9:41</span>
              <div class="status-icons">
                <svg width="15" height="11" viewBox="0 0 17 11" fill="currentColor">
                  <rect x="0" y="8" width="3" height="3" rx="0.5"/>
                  <rect x="4.5" y="5.5" width="3" height="5.5" rx="0.5"/>
                  <rect x="9" y="3" width="3" height="8" rx="0.5"/>
                  <rect x="13.5" y="0" width="3" height="11" rx="0.5"/>
                </svg>
                <svg width="15" height="11" viewBox="0 0 16 12" fill="currentColor">
                  <path d="M8 9.5a1.5 1.5 0 100 3 1.5 1.5 0 000-3zm-4.24-2.83a6 6 0 018.48 0l1.42-1.42a8 8 0 00-11.32 0l1.42 1.42zm-2.83-2.83a10 10 0 0114.14 0l1.42-1.42a12 12 0 00-16.98 0l1.42 1.42z"/>
                </svg>
                <div class="battery-icon">
                  <div class="battery-pill">
                    <div class="battery-level"></div>
                  </div>
                  <div class="battery-cap"></div>
                </div>
              </div>
            </div>

            <!-- =================================================================
                 DEDICATED APP SCREEN VIEWPORT (MIDDLE FLEX ITEM)
                 ================================================================= -->
            <div class="app-screen-container" id="app-screen-container">

              <!-- SCREEN 1: TODAY SCREEN -->
              <div class="screen-view active" id="screen-today">

                <!-- Navigation Header -->
                <div class="app-nav-header">
                  <div class="nav-date-group">
                    <p id="today-day-name">Thursday, Oct 24</p>
                    <h2 id="today-date-title">Today's Habits</h2>
                  </div>
                  <div class="header-actions">
                    <button class="round-action-btn" onclick="openAddHabitSheet()" title="Add New Habit" aria-label="Add Habit">
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round">
                        <line x1="12" y1="5" x2="12" y2="19"></line>
                        <line x1="5" y1="12" x2="19" y2="12"></line>
                      </svg>
                    </button>
                  </div>
                </div>

                <!-- Viewing Past Date Banner -->
                <div class="date-view-banner" id="date-view-banner" style="display: none;"></div>

                <!-- Weekday Ribbon (Interactive Date Navigation) -->
                <div class="week-ribbon">
                  <div class="day-pill completed" data-day="21" onclick="selectDay(21)">
                    <span class="day-name">M</span>
                    <span class="day-num">21</span>
                    <span class="day-dot"></span>
                  </div>
                  <div class="day-pill completed" data-day="22" onclick="selectDay(22)">
                    <span class="day-name">T</span>
                    <span class="day-num">22</span>
                    <span class="day-dot"></span>
                  </div>
                  <div class="day-pill completed" data-day="23" onclick="selectDay(23)">
                    <span class="day-name">W</span>
                    <span class="day-num">23</span>
                    <span class="day-dot"></span>
                  </div>
                  <div class="day-pill active" data-day="24" onclick="selectDay(24)">
                    <span class="day-name">T</span>
                    <span class="day-num">24</span>
                    <span class="day-dot"></span>
                  </div>
                  <div class="day-pill" data-day="25" onclick="selectDay(25)">
                    <span class="day-name">F</span>
                    <span class="day-num">25</span>
                    <span class="day-dot"></span>
                  </div>
                  <div class="day-pill" data-day="26" onclick="selectDay(26)">
                    <span class="day-name">S</span>
                    <span class="day-num">26</span>
                    <span class="day-dot"></span>
                  </div>
                  <div class="day-pill" data-day="27" onclick="selectDay(27)">
                    <span class="day-name">S</span>
                    <span class="day-num">27</span>
                    <span class="day-dot"></span>
                  </div>
                </div>

                <!-- Motivational Hero Card with Circular Gauge -->
                <div class="progress-hero-card">
                  <div class="hero-content">
                    <div class="hero-text">
                      <h3 id="hero-motivation-title">Crushing your habits! 🔥</h3>
                      <p id="hero-motivation-sub">4 of 7 completed</p>
                      <div class="streak-chip">
                        <span>⚡ 14-Day Global Streak</span>
                      </div>
                    </div>

                    <div class="progress-gauge-box">
                      <svg class="gauge-svg" viewBox="0 0 80 80">
                        <defs>
                          <linearGradient id="gaugeGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                            <stop offset="0%" stop-color="#5700CB"/>
                            <stop offset="100%" stop-color="#0062E4"/>
                          </linearGradient>
                        </defs>
                        <circle class="gauge-bg" cx="40" cy="40" r="35"/>
                        <circle class="gauge-val" id="hero-gauge-val" cx="40" cy="40" r="35"/>
                      </svg>
                      <div class="gauge-center-text" id="hero-gauge-text">57%</div>
                    </div>
                  </div>
                </div>

                <!-- Habits Container -->
                <div id="today-habits-container"></div>

              </div>

              <!-- SCREEN 2: HABIT DETAILS SCREEN -->
              <div class="screen-view" id="screen-details">
                <div class="details-nav-bar">
                  <button class="back-btn" onclick="switchScreen('today')">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                      <polyline points="15 18 9 12 15 6"></polyline>
                    </svg>
                    <span>Today</span>
                  </button>
                  <span style="font-size: 15px; font-weight: 700; color: var(--app-text-primary);">Habit Overview</span>
                  <div style="width: 50px;"></div>
                </div>

                <div class="details-hero">
                  <div class="details-hero-icon" id="details-hero-icon"></div>
                  <h3 class="details-title" id="details-title">Drink water (2L)</h3>
                  <p class="details-subtitle" id="details-subtitle">Every day • MORNING</p>
                </div>

                <div class="stats-grid">
                  <div class="stat-box">
                    <span class="stat-label">CURRENT STREAK</span>
                    <span class="stat-value" id="details-cur-streak">14d</span>
                  </div>
                  <div class="stat-box">
                    <span class="stat-label">BEST STREAK</span>
                    <span class="stat-value" id="details-best-streak">28d</span>
                  </div>
                  <div class="stat-box">
                    <span class="stat-label">TOTAL LOGS</span>
                    <span class="stat-value" id="details-total-logs">92</span>
                  </div>
                  <div class="stat-box">
                    <span class="stat-label">CONSISTENCY</span>
                    <span class="stat-value" id="details-rate" style="color: #0FC580;">94%</span>
                  </div>
                </div>

                <div class="calendar-card">
                  <div class="calendar-title">Monthly Completion Heatmap</div>
                  <div class="calendar-grid" id="details-cal-grid"></div>
                </div>

                <button class="submit-habit-btn" onclick="triggerActionButton()" style="margin-top: 6px;">
                  ⚡ Log Quick Check-in
                </button>
              </div>

              <!-- SCREEN 3: CHALLENGES SCREEN -->
              <div class="screen-view" id="screen-challenges">
                <div class="app-nav-header">
                  <div class="nav-date-group">
                    <p>HABIT ACCELERATOR</p>
                    <h2>Challenges</h2>
                  </div>
                </div>

                <div class="challenge-hero-banner">
                  <span class="challenge-banner-tag">ACTIVE JOURNEY</span>
                  <h3>21-Day Morning Miracle</h3>
                  <p>Build the ultimate morning triad: hydration, sunlight, and mindfulness.</p>
                  <button class="join-challenge-btn" onclick="onJoinChallengeClick(event, '21-Day Morning Miracle')">
                    Day 8 of 21 • Keep Going 🔥
                  </button>
                </div>

                <h4 style="font-size: 14px; font-weight: 700; margin-bottom: 12px; color: var(--app-text-primary);">Explore Curated Challenges</h4>
                <div id="challenges-list-container"></div>
              </div>

              <!-- SCREEN 4: STATISTICS SCREEN -->
              <div class="screen-view" id="screen-stats">
                <div class="app-nav-header">
                  <div class="nav-date-group">
                    <p>YOUR PERFORMANCE</p>
                    <h2>Insights</h2>
                  </div>
                </div>

                <div class="stats-banner">
                  <h3>94.8%</h3>
                  <p>Overall Habit Consistency this month. You're in the top 5% of Productive users!</p>
                </div>

                <div class="chart-card">
                  <h4 style="font-size: 14px; font-weight: 700; color: var(--app-text-primary); margin-bottom: 4px;">Weekly Adherence</h4>
                  <p style="font-size: 11px; color: var(--app-text-secondary); margin-bottom: 14px;">Habits logged per day</p>
                  <div class="chart-bars">
                    <div class="bar-col">
                      <div class="bar-pill" style="height: 75%;"></div>
                      <span class="bar-label">Mon</span>
                    </div>
                    <div class="bar-col">
                      <div class="bar-pill" style="height: 90%;"></div>
                      <span class="bar-label">Tue</span>
                    </div>
                    <div class="bar-col">
                      <div class="bar-pill" style="height: 85%;"></div>
                      <span class="bar-label">Wed</span>
                    </div>
                    <div class="bar-col">
                      <div class="bar-pill" style="height: 100%;"></div>
                      <span class="bar-label">Thu</span>
                    </div>
                    <div class="bar-col">
                      <div class="bar-pill" style="height: 60%;"></div>
                      <span class="bar-label">Fri</span>
                    </div>
                    <div class="bar-col">
                      <div class="bar-pill" style="height: 70%;"></div>
                      <span class="bar-label">Sat</span>
                    </div>
                    <div class="bar-col">
                      <div class="bar-pill" style="height: 80%;"></div>
                      <span class="bar-label">Sun</span>
                    </div>
                  </div>
                </div>

                <div class="stats-grid">
                  <div class="stat-box">
                    <span class="stat-label">PERFECT DAYS</span>
                    <span class="stat-value" style="color: #F8BD32;">18</span>
                  </div>
                  <div class="stat-box">
                    <span class="stat-label">TOTAL LOGS</span>
                    <span class="stat-value" style="color: #0FC580;">429</span>
                  </div>
                </div>
              </div>

            </div>

            <!-- =================================================================
                 CUPERTINO BOTTOM SHEET (SEGMENTED PRESETS VS CUSTOM BUILDER)
                 ================================================================= -->
            <div class="sheet-backdrop" id="sheet-backdrop" onclick="closeAddHabitSheet()">
              <div class="cupertino-sheet" onclick="event.stopPropagation()">
                <div class="sheet-handle"></div>
                
                <div class="sheet-header">
                  <h3>New Habit</h3>
                  <button class="sheet-close-btn" onclick="closeAddHabitSheet()">✕</button>
                </div>

                <!-- Segmented Control Switch -->
                <div class="sheet-segmented-nav">
                  <button class="sheet-nav-tab active" id="sheet-tab-presets" onclick="setSheetTab('presets')">
                    ✨ Presets (14 Categories)
                  </button>
                  <button class="sheet-nav-tab" id="sheet-tab-custom" onclick="setSheetTab('custom')">
                    🛠️ Custom Habit Builder
                  </button>
                </div>

                <!-- TAB 1: PRESETS VIEW -->
                <div id="sheet-presets-view">
                  <div class="categories-tabs" id="sheet-cat-tabs"></div>
                  <div class="presets-list" id="sheet-presets-list"></div>
                </div>

                <!-- TAB 2: CUSTOM HABIT BUILDER -->
                <div id="sheet-custom-view" style="display: none;">
                  <form id="custom-habit-form">
                    
                    <div class="form-group">
                      <label class="form-label">HABIT NAME</label>
                      <input type="text" class="form-input" id="custom-name-input" placeholder="e.g. Drink 2.5L Water or Do 10 Pushups" required>
                    </div>

                    <!-- Tracking Mode Selection Chips -->
                    <div class="form-group">
                      <label class="form-label">TRACKING TYPE</label>
                      <div class="chips-selector" style="display: grid; grid-template-columns: 1fr 1fr; gap: 8px;">
                        <div class="chip-option mode-chip selected" data-mode="binary" onclick="onTrackingModeChange('binary')">
                          ☑️ Simple Check
                        </div>
                        <div class="chip-option mode-chip" data-mode="amount" onclick="onTrackingModeChange('amount')">
                          💧 Amount & Unit
                        </div>
                        <div class="chip-option mode-chip" data-mode="reps" onclick="onTrackingModeChange('reps')">
                          🔢 Multi-Reps
                        </div>
                        <div class="chip-option mode-chip" data-mode="timer" onclick="onTrackingModeChange('timer')">
                          ⏱️ Duration Timer
                        </div>
                      </div>
                    </div>

                    <!-- Mode 1: Amount Inputs -->
                    <div id="form-amount-group" style="display: none; background: rgba(255,255,255,0.04); padding: 12px; border-radius: 14px; margin-bottom: 14px;">
                      <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-bottom: 10px;">
                        <div>
                          <label class="form-label">DAILY TARGET</label>
                          <input type="number" class="form-input" id="custom-target-amount" value="2000" min="1">
                        </div>
                        <div>
                          <label class="form-label">MEASUREMENT UNIT</label>
                          <select class="form-input" id="custom-unit-select">
                            <option value="ml">ml (Milliliters)</option>
                            <option value="L">L (Liters)</option>
                            <option value="glasses">Glasses</option>
                            <option value="cups">Cups</option>
                            <option value="pages">Pages (Reading)</option>
                            <option value="km">km (Distance)</option>
                            <option value="mins">Minutes</option>
                          </select>
                        </div>
                      </div>
                      <div>
                        <label class="form-label">QUICK INCREMENT STEP</label>
                        <input type="number" class="form-input" id="custom-step-amount" value="250" min="1" placeholder="e.g. 250ml per tap">
                      </div>
                    </div>

                    <!-- Mode 2: Multi-Reps Inputs -->
                    <div id="form-reps-group" style="display: none; background: rgba(255,255,255,0.04); padding: 12px; border-radius: 14px; margin-bottom: 14px;">
                      <label class="form-label">REPETITIONS PER DAY</label>
                      <select class="form-input" id="custom-reps-count">
                        <option value="2">2 times a day</option>
                        <option value="3" selected>3 times a day</option>
                        <option value="4">4 times a day</option>
                        <option value="5">5 times a day</option>
                        <option value="10">10 times a day</option>
                      </select>
                    </div>

                    <!-- Mode 3: Timer Inputs -->
                    <div id="form-timer-group" style="display: none; background: rgba(255,255,255,0.04); padding: 12px; border-radius: 14px; margin-bottom: 14px;">
                      <label class="form-label">DURATION (MINUTES)</label>
                      <select class="form-input" id="custom-duration-minutes">
                        <option value="5">5 Minutes</option>
                        <option value="10">10 Minutes</option>
                        <option value="15" selected>15 Minutes</option>
                        <option value="25">25 Minutes (Pomodoro)</option>
                        <option value="30">30 Minutes</option>
                        <option value="45">45 Minutes</option>
                        <option value="60">60 Minutes</option>
                      </select>
                    </div>

                    <!-- Frequency / Recurrence -->
                    <div class="form-group">
                      <label class="form-label">HOW OFTEN (RECURRENCE)</label>
                      <select class="form-input" id="custom-frequency-select">
                        <option value="daily" selected>Every day (Daily)</option>
                        <option value="every_2_days">Every 2 days (Alternate)</option>
                        <option value="every_3_days">Every 3 days</option>
                        <option value="weekdays">Weekdays only (Mon - Fri)</option>
                        <option value="weekends">Weekends only (Sat - Sun)</option>
                        <option value="3_per_week">3 days a week</option>
                      </select>
                    </div>

                    <!-- Strictness / Fatal Mode -->
                    <div class="form-group">
                      <label class="form-label">HABIT STRICTNESS & EXPIRATION</label>
                      <select class="form-input" id="custom-strictness-select">
                        <option value="strict" selected>⚡ Strict / Fatal (Expires midnight, breaks streak, no backfill)</option>
                        <option value="flexible">🛡️ Flexible (Can backfill missed days within grace period)</option>
                        <option value="rollover">🔄 Rollover (Unfinished quota rolls over to next day)</option>
                      </select>
                    </div>

                    <!-- Time of Day & Color -->
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-bottom: 14px;">
                      <div>
                        <label class="form-label">TIME OF DAY</label>
                        <select class="form-input" id="custom-time-select">
                          <option value="morning">🌅 Morning</option>
                          <option value="afternoon">☀️ Afternoon</option>
                          <option value="evening">🌙 Evening</option>
                          <option value="anytime">⏰ Anytime</option>
                        </select>
                      </div>
                      <div>
                        <label class="form-label">ACCENT COLOR</label>
                        <select class="form-input" id="custom-color-select">
                          <option value="#5700CB">🟣 Royal Purple</option>
                          <option value="#0062E4">🔵 Ocean Blue</option>
                          <option value="#0FC580">🟢 Emerald Green</option>
                          <option value="#FF7450">🟠 Sunset Coral</option>
                          <option value="#F8BD32">🟡 Amber Gold</option>
                          <option value="#F63566">🔴 Rose Pink</option>
                        </select>
                      </div>
                    </div>

                    <div class="form-group">
                      <label class="form-label">ICON</label>
                      <select class="form-input" id="custom-icon-select">
                        <option value="ic_drink">💧 Water / Hydration</option>
                        <option value="ic_yoga">🧘 Yoga / Stretching</option>
                        <option value="ic_walking">🚶 Walking / Outdoors</option>
                        <option value="ic_run">🏃 Running / Cardio</option>
                        <option value="ic_gym">🏋️ Gym / Workout</option>
                        <option value="ic_fruit">🍎 Fruits & Nutrition</option>
                        <option value="ic_read">📖 Reading & Learning</option>
                        <option value="ic_sleep">🌙 Sleep & Bedtime</option>
                        <option value="ic_money">💰 Finance & Saving</option>
                        <option value="ic_pills">💊 Medicine & Vitamins</option>
                        <option value="ic_home">🏠 Home & Cleaning</option>
                      </select>
                    </div>

                    <button type="submit" class="submit-habit-btn" style="width: 100%;">
                      Create Habit
                    </button>
                  </form>
                </div>

              </div>
            </div>

            <!-- =================================================================
                 iOS BOTTOM TAB BAR (FIXED BOTTOM FOOTER)
                 ================================================================= -->
            <nav class="ios-tab-bar" aria-label="Main Navigation">
              <div class="tab-item active" data-screen="today" title="Today's Habits">
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
                  <rect x="3" y="4" width="18" height="18" rx="4"></rect>
                  <line x1="16" y1="2" x2="16" y2="6"></line>
                  <line x1="8" y1="2" x2="8" y2="6"></line>
                  <line x1="3" y1="10" x2="21" y2="10"></line>
                </svg>
                <span>Today</span>
              </div>

              <div class="tab-item" data-screen="challenges" title="Habit Challenges">
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
                  <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"></polygon>
                </svg>
                <span>Challenges</span>
              </div>

              <div class="tab-item" data-screen="stats" title="Insights & Statistics">
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
                  <line x1="18" y1="20" x2="18" y2="10"></line>
                  <line x1="12" y1="20" x2="12" y2="4"></line>
                  <line x1="6" y1="20" x2="6" y2="14"></line>
                </svg>
                <span>Insights</span>
              </div>

              <div class="tab-item" onclick="openAddHabitSheet()" title="New Habit">
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
                  <circle cx="12" cy="12" r="10"></circle>
                  <line x1="12" y1="8" x2="12" y2="16"></line>
                  <line x1="8" y1="12" x2="16" y2="12"></line>
                </svg>
                <span>New</span>
              </div>
            </nav>

            <div class="home-indicator-bar" onclick="switchScreen('today')" title="Home Indicator"></div>

          </div>
        </div>
      </div>
    </main>

  </div>

  <script src="app.js"></script>
</body>
</html>
`;

fs.writeFileSync('index.html', indexHtml, 'utf8');
console.log('Successfully written index.html!');
