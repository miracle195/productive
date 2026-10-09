const fs = require('fs');

console.log('Writing updated styles.css with zero overlapping and multi-mode habit tracking...');

const updatedCss = `/* ==========================================================================
   PRODUCTIVE iOS 17 / 18 EXPERIENCE - IPHONE 15 PRO SIMULATOR
   Zero-Overlap Layout Architecture & Multi-Mode Habit Tracking
   ========================================================================== */

@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=SF+Pro+Display:wght@400;500;600;700&display=swap');

:root {
  /* Studio Environment */
  --studio-bg: #0A0D14;
  --studio-surface: rgba(18, 22, 33, 0.75);
  --studio-border: rgba(255, 255, 255, 0.08);
  --studio-text: #F0F4F8;
  --studio-muted: #828B9E;

  /* iPhone 15 Pro Dimensions */
  --device-width: 402px;
  --device-height: 852px;
  --device-radius: 54px;
  --screen-radius: 46px;

  /* Natural Titanium Default Finish */
  --frame-base: #9A958D;
  --frame-highlight: #C2BCB4;
  --frame-shadow: #5C5852;
  --frame-sheen: linear-gradient(135deg, #A8A39B 0%, #7A766F 50%, #B8B2A9 100%);
  --button-color: #8C877F;

  /* Productive Dark Palette */
  --app-bg: #121524;
  --app-card-bg: rgba(26, 30, 48, 0.88);
  --app-card-border: rgba(255, 255, 255, 0.08);
  --app-card-hover: rgba(36, 42, 68, 0.95);
  --app-text-primary: #FFFFFF;
  --app-text-secondary: #9099B0;
  --app-text-muted: #5F6880;
  --app-divider: rgba(255, 255, 255, 0.08);
  --app-tab-bg: rgba(18, 21, 36, 0.92);
  --app-sheet-bg: #181C2E;
  --app-input-bg: #22273D;
  --app-accent-blue: #007AFF;
  --app-accent-green: #0FC580;
  --app-accent-coral: #FF5A5F;
  --app-accent-purple: #923DFF;
  --app-accent-amber: #F8BD32;

  /* Dynamic Island Constants */
  --island-bg: #000000;
  --island-width: 124px;
  --island-height: 35px;
  --island-radius: 18px;
}

[data-app-theme="light"] {
  --app-bg: #F4F6FB;
  --app-card-bg: #FFFFFF;
  --app-card-border: rgba(0, 0, 0, 0.06);
  --app-card-hover: #F8FAFD;
  --app-text-primary: #0E1326;
  --app-text-secondary: #58637F;
  --app-text-muted: #8E99B0;
  --app-divider: rgba(0, 0, 0, 0.08);
  --app-tab-bg: rgba(255, 255, 255, 0.92);
  --app-sheet-bg: #FFFFFF;
  --app-input-bg: #EDF1F7;
}

[data-finish="blue"] {
  --frame-base: #3B4454;
  --frame-highlight: #5B667C;
  --frame-shadow: #212836;
  --frame-sheen: linear-gradient(135deg, #4A5468 0%, #262E3D 50%, #5E6980 100%);
  --button-color: #384152;
}
[data-finish="white"] {
  --frame-base: #E2E4E8;
  --frame-highlight: #FFFFFF;
  --frame-shadow: #AEB2B9;
  --frame-sheen: linear-gradient(135deg, #F0F2F5 0%, #CACDD3 50%, #FFFFFF 100%);
  --button-color: #D2D5DA;
}
[data-finish="black"] {
  --frame-base: #2B2C2E;
  --frame-highlight: #444649;
  --frame-shadow: #141517;
  --frame-sheen: linear-gradient(135deg, #37383B 0%, #1A1B1C 50%, #46484C 100%);
  --button-color: #27282A;
}

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
  -webkit-tap-highlight-color: transparent;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Plus Jakarta Sans', sans-serif;
  background-color: var(--studio-bg);
  color: var(--studio-text);
  min-height: 100vh;
  overflow-x: hidden;
  user-select: none;
  display: flex;
  flex-direction: column;
}

.studio-wrapper {
  flex: 1;
  display: flex;
  flex-direction: column;
  position: relative;
  align-items: center;
  justify-content: flex-start;
  min-height: 100vh;
  padding: 18px 24px 36px 24px;
}

.ambient-glow {
  position: absolute;
  border-radius: 50%;
  filter: blur(140px);
  pointer-events: none;
  z-index: 0;
  opacity: 0.35;
  transition: all 0.8s ease;
}
.glow-purple {
  top: 10%;
  left: 20%;
  width: 480px;
  height: 480px;
  background: radial-gradient(circle, #5700CB 0%, transparent 70%);
}
.glow-blue {
  bottom: 15%;
  right: 25%;
  width: 500px;
  height: 500px;
  background: radial-gradient(circle, #0062E4 0%, transparent 70%);
}
.glow-emerald {
  top: 40%;
  right: 15%;
  width: 420px;
  height: 420px;
  background: radial-gradient(circle, #0FC580 0%, transparent 70%);
}

.studio-header {
  width: 100%;
  max-width: 1200px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
  z-index: 10;
  gap: 16px;
  flex-wrap: wrap;
}

.brand-badge {
  display: flex;
  align-items: center;
  gap: 14px;
  text-decoration: none;
  color: inherit;
}
.brand-logo-icon {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  background: linear-gradient(135deg, #5700CB, #0062E4);
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 8px 24px rgba(87, 0, 203, 0.4);
  color: white;
  font-weight: 800;
  font-size: 22px;
}
.brand-info h1 {
  font-size: 19px;
  font-weight: 700;
  letter-spacing: -0.02em;
  display: flex;
  align-items: center;
  gap: 8px;
}
.badge-pill {
  font-size: 11px;
  font-weight: 600;
  padding: 3px 8px;
  border-radius: 20px;
  background: rgba(255, 255, 255, 0.12);
  color: #B5BED4;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}
.brand-info p {
  font-size: 12px;
  color: var(--studio-muted);
}

.studio-toolbar {
  display: flex;
  align-items: center;
  gap: 10px;
  background: var(--studio-surface);
  backdrop-filter: blur(20px);
  border: 1px solid var(--studio-border);
  padding: 6px 10px;
  border-radius: 16px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.4);
}

.tool-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  background: transparent;
  border: none;
  color: var(--studio-muted);
  font-size: 13px;
  font-weight: 500;
  padding: 6px 12px;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s;
}
.tool-btn:hover {
  background: rgba(255, 255, 255, 0.08);
  color: var(--studio-text);
}
.finish-dots {
  display: flex;
  gap: 6px;
  align-items: center;
  padding: 0 4px;
}
.finish-dot {
  width: 18px;
  height: 18px;
  border-radius: 50%;
  cursor: pointer;
  border: 2px solid transparent;
  transition: transform 0.2s, border-color 0.2s;
}
.finish-dot:hover {
  transform: scale(1.15);
}
.finish-dot.active {
  border-color: #FFFFFF;
  box-shadow: 0 0 10px rgba(255, 255, 255, 0.4);
}
.dot-natural { background: #9A958D; }
.dot-blue { background: #3B4454; }
.dot-white { background: #E2E4E8; }
.dot-black { background: #2B2C2E; }

.stage-container {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 5;
}

/* ==========================================================================
   IPHONE 15 PRO HARDWARE FRAME
   ========================================================================== */
.iphone-frame {
  width: var(--device-width);
  height: var(--device-height);
  border-radius: var(--device-radius);
  position: relative;
  background: var(--frame-sheen);
  padding: 3.5px;
  box-shadow:
    0 0 0 1px var(--frame-shadow),
    0 25px 60px -15px rgba(0, 0, 0, 0.8),
    0 50px 100px -20px rgba(0, 0, 0, 0.9),
    inset 0 0 3px rgba(255, 255, 255, 0.4);
  transition: all 0.4s ease;
}

.iphone-frame::before {
  content: '';
  position: absolute;
  inset: 0;
  border-radius: var(--device-radius);
  background: linear-gradient(125deg, rgba(255, 255, 255, 0.35) 0%, transparent 40%, rgba(255, 255, 255, 0.1) 60%, transparent 100%);
  pointer-events: none;
}

.hw-button {
  position: absolute;
  background: var(--button-color);
  border-radius: 3px;
  box-shadow: inset 0 1px 1px rgba(255, 255, 255, 0.3), 0 2px 4px rgba(0, 0, 0, 0.5);
  cursor: pointer;
  transition: transform 0.1s;
}
.hw-button:active {
  transform: scale(0.96);
}
.btn-action {
  left: -5.5px;
  top: 110px;
  width: 4px;
  height: 28px;
}
.btn-action::after {
  content: '';
  position: absolute;
  top: 50%;
  left: -2px;
  transform: translateY(-50%);
  width: 2px;
  height: 10px;
  background: #FF7450;
  border-radius: 1px;
}
.btn-volume-up {
  left: -5.5px;
  top: 156px;
  width: 4px;
  height: 52px;
}
.btn-volume-down {
  left: -5.5px;
  top: 220px;
  width: 4px;
  height: 52px;
}
.btn-power {
  right: -5.5px;
  top: 175px;
  width: 4px;
  height: 78px;
}

.screen-bezel {
  width: 100%;
  height: 100%;
  background: #000000;
  border-radius: calc(var(--device-radius) - 3.5px);
  padding: 3.5px;
  position: relative;
  overflow: hidden;
  box-shadow: inset 0 0 0 1.5px rgba(0, 0, 0, 0.9);
}

/* ==========================================================================
   DISPLAY CONTAINER: FLEXBOX WITHOUT OVERLAPS
   ========================================================================== */
.screen-display {
  width: 100%;
  height: 100%;
  border-radius: var(--screen-radius);
  background: var(--app-bg);
  position: relative;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  transition: background-color 0.3s;
}

/* Dynamic Island (Pill) */
.dynamic-island-container {
  position: absolute;
  top: 11px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 100;
  display: flex;
  align-items: center;
  justify-content: center;
}

.dynamic-island {
  width: var(--island-width);
  height: var(--island-height);
  border-radius: var(--island-radius);
  background: var(--island-bg);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 11px;
  position: relative;
  cursor: pointer;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.4);
  transition: width 0.35s cubic-bezier(0.16, 1, 0.3, 1),
              height 0.35s cubic-bezier(0.16, 1, 0.3, 1),
              border-radius 0.35s cubic-bezier(0.16, 1, 0.3, 1);
}

.island-camera {
  width: 11px;
  height: 11px;
  border-radius: 50%;
  background: radial-gradient(circle at 40% 40%, #1A2740 0%, #07090E 80%);
  box-shadow: inset 0 0 2px rgba(255, 255, 255, 0.25);
}
.island-sensor {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #080A0F;
}

.dynamic-island.expanded {
  width: 366px;
  height: 154px;
  border-radius: 38px;
  padding: 16px 20px;
  align-items: flex-start;
  flex-direction: column;
  justify-content: space-between;
  box-shadow: 0 20px 45px rgba(0, 0, 0, 0.8), 0 0 0 1px rgba(255, 255, 255, 0.1);
}

.island-compact-view {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
}
.dynamic-island.expanded .island-compact-view {
  display: none;
}

.island-expanded-view {
  display: none;
  width: 100%;
  height: 100%;
  flex-direction: column;
  justify-content: space-between;
}
.dynamic-island.expanded .island-expanded-view {
  display: flex;
  animation: fadeIn 0.2s ease forwards;
}

.island-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
}
.island-habit-info {
  display: flex;
  align-items: center;
  gap: 12px;
}
.island-habit-icon {
  width: 38px;
  height: 38px;
  border-radius: 12px;
  background: linear-gradient(135deg, #1B8FFF, #0056B3);
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}
.island-habit-title {
  font-size: 15px;
  font-weight: 700;
  color: #FFFFFF;
}
.island-habit-sub {
  font-size: 12px;
  color: #8E99B0;
}
.island-timer-badge {
  font-size: 18px;
  font-weight: 800;
  color: #0FC580;
  font-variant-numeric: tabular-nums;
}

.island-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  padding-top: 10px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
}
.island-quick-btn {
  background: #0FC580;
  color: #FFFFFF;
  border: none;
  border-radius: 20px;
  padding: 8px 18px;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
}

/* Dedicated iOS Status Bar (Flex Header) */
.ios-status-bar {
  height: 48px;
  flex-shrink: 0;
  width: 100%;
  padding: 12px 28px 0 28px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 14px;
  font-weight: 600;
  color: var(--app-text-primary);
  z-index: 30;
  background: transparent;
}
.status-time {
  font-weight: 600;
  letter-spacing: -0.02em;
}
.status-icons {
  display: flex;
  align-items: center;
  gap: 7px;
}
.battery-icon {
  display: flex;
  align-items: center;
  gap: 1.5px;
}
.battery-pill {
  width: 23px;
  height: 11.5px;
  border-radius: 4px;
  border: 1.2px solid currentColor;
  padding: 1.5px;
  display: flex;
  align-items: center;
}
.battery-level {
  width: 90%;
  height: 100%;
  background: currentColor;
  border-radius: 1.5px;
}
.battery-cap {
  width: 1.8px;
  height: 4.5px;
  background: currentColor;
  border-radius: 0 1px 1px 0;
}

/* App Screen Viewport Wrapper (Flex Middle) */
.app-screen-container {
  flex: 1;
  position: relative;
  width: 100%;
  min-height: 0;
  overflow: hidden;
}

.screen-view {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  padding: 10px 18px 84px 18px;
  overflow-y: auto;
  overflow-x: hidden;
  -webkit-overflow-scrolling: touch;
  opacity: 0;
  pointer-events: none;
  transform: scale(0.98);
  transition: opacity 0.25s ease, transform 0.25s ease;
}
.screen-view.active {
  opacity: 1;
  pointer-events: auto;
  transform: scale(1);
}
.screen-view::-webkit-scrollbar {
  display: none;
}

/* Dedicated iOS Tab Bar (Flex Footer) */
.ios-tab-bar {
  height: 74px;
  flex-shrink: 0;
  width: 100%;
  background: var(--app-tab-bg);
  backdrop-filter: blur(25px);
  border-top: 1px solid var(--app-divider);
  display: flex;
  align-items: center;
  justify-content: space-around;
  padding-bottom: 12px;
  z-index: 40;
}
.tab-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 3px;
  color: var(--app-text-muted);
  cursor: pointer;
  transition: color 0.2s;
  padding: 4px 12px;
}
.tab-item.active {
  color: var(--app-accent-blue);
}
.tab-item span {
  font-size: 10px;
  font-weight: 600;
}

.home-indicator-bar {
  position: absolute;
  bottom: 6px;
  left: 50%;
  transform: translateX(-50%);
  width: 134px;
  height: 4.5px;
  background: var(--app-text-primary);
  border-radius: 3px;
  opacity: 0.35;
  cursor: pointer;
  z-index: 50;
}

/* ==========================================================================
   TODAY SCREEN COMPONENTS
   ========================================================================== */
.app-nav-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: 2px;
  margin-bottom: 14px;
}
.nav-date-group h2 {
  font-size: 24px;
  font-weight: 800;
  letter-spacing: -0.02em;
  color: var(--app-text-primary);
}
.nav-date-group p {
  font-size: 12px;
  font-weight: 600;
  color: var(--app-text-secondary);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.round-action-btn {
  width: 38px;
  height: 38px;
  border-radius: 50%;
  background: var(--app-card-bg);
  border: 1px solid var(--app-card-border);
  color: var(--app-text-primary);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
}
.round-action-btn:active {
  transform: scale(0.92);
}

/* Viewing Past Date Banner */
.date-view-banner {
  background: rgba(248, 189, 50, 0.12);
  border: 1px solid rgba(248, 189, 50, 0.3);
  color: #F8BD32;
  font-size: 12px;
  font-weight: 700;
  padding: 8px 12px;
  border-radius: 14px;
  margin-bottom: 14px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.date-view-banner button {
  background: #F8BD32;
  color: #0E1326;
  border: none;
  font-size: 11px;
  font-weight: 700;
  padding: 4px 10px;
  border-radius: 10px;
  cursor: pointer;
}

/* Weekday Ribbon */
.week-ribbon {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: var(--app-card-bg);
  border: 1px solid var(--app-card-border);
  border-radius: 18px;
  padding: 8px 6px;
  margin-bottom: 16px;
}
.day-pill {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 5px;
  padding: 6px 8px;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s;
}
.day-pill .day-name {
  font-size: 11px;
  font-weight: 600;
  color: var(--app-text-muted);
}
.day-pill .day-num {
  font-size: 14px;
  font-weight: 700;
  color: var(--app-text-secondary);
}
.day-pill .day-dot {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: transparent;
}
.day-pill.completed .day-dot {
  background: var(--app-accent-green);
}
.day-pill.active {
  background: linear-gradient(135deg, #5700CB, #0062E4);
  box-shadow: 0 4px 12px rgba(87, 0, 203, 0.35);
}
.day-pill.active .day-name,
.day-pill.active .day-num {
  color: #FFFFFF;
}

/* Progress Hero Card */
.progress-hero-card {
  background: var(--app-card-bg);
  border: 1px solid var(--app-card-border);
  border-radius: 22px;
  padding: 16px 18px;
  margin-bottom: 18px;
  position: relative;
  overflow: hidden;
}
.hero-content {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
}
.hero-text h3 {
  font-size: 16px;
  font-weight: 800;
  color: var(--app-text-primary);
  margin-bottom: 3px;
}
.hero-text p {
  font-size: 12px;
  color: var(--app-text-secondary);
}
.streak-chip {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  background: rgba(255, 116, 80, 0.12);
  color: #FF7450;
  font-size: 11px;
  font-weight: 700;
  padding: 3px 8px;
  border-radius: 10px;
  margin-top: 6px;
}

.progress-gauge-box {
  width: 66px;
  height: 66px;
  position: relative;
  flex-shrink: 0;
}
.gauge-svg {
  transform: rotate(-90deg);
  width: 100%;
  height: 100%;
}
.gauge-bg {
  stroke: var(--app-divider);
  stroke-width: 6.5;
  fill: none;
}
.gauge-val {
  stroke: url(#gaugeGradient);
  stroke-width: 6.5;
  stroke-linecap: round;
  fill: none;
  stroke-dasharray: 220;
  stroke-dashoffset: 60;
  transition: stroke-dashoffset 0.6s ease;
}
.gauge-center-text {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  font-weight: 800;
  color: var(--app-text-primary);
}

.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin: 14px 0 8px 0;
}
.section-title {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 14px;
  font-weight: 700;
  color: var(--app-text-primary);
}
.section-count {
  font-size: 12px;
  font-weight: 600;
  color: var(--app-text-muted);
}

/* ==========================================================================
   MULTI-MODE HABIT CARDS (Amount, Reps, Timer, Strictness)
   ========================================================================== */
.habit-card {
  background: var(--app-card-bg);
  border: 1px solid var(--app-card-border);
  border-radius: 18px;
  padding: 13px 15px;
  margin-bottom: 10px;
  display: flex;
  flex-direction: column;
  gap: 10px;
  cursor: pointer;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.04);
  transition: all 0.25s ease;
}
.habit-card:hover {
  background: var(--app-card-hover);
}

.habit-card-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  width: 100%;
}
.habit-main {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
  min-width: 0;
}
.habit-icon-wrapper {
  width: 42px;
  height: 42px;
  border-radius: 13px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  color: #FFFFFF;
}
.habit-details {
  display: flex;
  flex-direction: column;
  gap: 3px;
  min-width: 0;
}
.habit-name {
  font-size: 15px;
  font-weight: 700;
  color: var(--app-text-primary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* Tag Badges (Strict vs Flexible, Recurrence) */
.habit-tags-row {
  display: flex;
  align-items: center;
  gap: 5px;
  flex-wrap: wrap;
}
.habit-tag {
  font-size: 10px;
  font-weight: 700;
  padding: 2px 7px;
  border-radius: 8px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}
.tag-strict {
  background: rgba(255, 90, 95, 0.15);
  color: #FF5A5F;
}
.tag-flexible {
  background: rgba(15, 197, 128, 0.15);
  color: #0FC580;
}
.tag-rollover {
  background: rgba(146, 61, 255, 0.15);
  color: #923DFF;
}
.tag-freq {
  background: rgba(255, 255, 255, 0.08);
  color: var(--app-text-secondary);
}

.habit-check-btn {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border: 2px solid var(--app-divider);
  background: transparent;
  color: transparent;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  cursor: pointer;
  transition: all 0.25s ease;
}
.habit-check-btn svg {
  width: 18px;
  height: 18px;
  stroke: currentColor;
  stroke-width: 2.5;
  stroke-linecap: round;
  stroke-linejoin: round;
  fill: none;
}

/* Completed Card State */
.habit-card.completed {
  opacity: 0.78;
}
.habit-card.completed .habit-name {
  text-decoration: line-through;
  color: var(--app-text-muted);
}
.habit-card.completed .habit-check-btn {
  background: var(--app-accent-green);
  border-color: var(--app-accent-green);
  color: #FFFFFF;
}

/* Fatal Missed Locked Card State */
.habit-card.fatal-missed {
  opacity: 0.65;
  border-color: rgba(255, 90, 95, 0.3);
  background: rgba(255, 90, 95, 0.04);
}
.habit-card.fatal-missed .habit-check-btn {
  background: rgba(255, 90, 95, 0.1);
  border-color: #FF5A5F;
  color: #FF5A5F;
  cursor: not-allowed;
}

/* Amount Progress Body */
.amount-progress-section {
  width: 100%;
  padding-top: 8px;
  border-top: 1px solid var(--app-divider);
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.amount-text-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12px;
  font-weight: 700;
  color: var(--app-text-secondary);
}
.amount-track {
  width: 100%;
  height: 7px;
  border-radius: 4px;
  background: var(--app-divider);
  overflow: hidden;
}
.amount-fill {
  height: 100%;
  border-radius: 4px;
  background: linear-gradient(90deg, #1B8FFF, #0FC580);
  transition: width 0.3s ease;
}
.amount-chip-buttons {
  display: flex;
  gap: 6px;
  align-items: center;
}
.amount-chip {
  background: rgba(255, 255, 255, 0.08);
  border: 1px solid var(--app-card-border);
  border-radius: 8px;
  padding: 4px 9px;
  font-size: 11px;
  font-weight: 700;
  color: var(--app-text-primary);
  cursor: pointer;
}
.amount-chip:hover {
  background: rgba(255, 255, 255, 0.15);
}

/* Reps Stepper Body */
.reps-progress-section {
  width: 100%;
  padding-top: 8px;
  border-top: 1px solid var(--app-divider);
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.reps-stepper {
  display: flex;
  align-items: center;
  gap: 8px;
}
.reps-btn {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.1);
  border: none;
  color: white;
  font-size: 15px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}
.reps-btn:active {
  transform: scale(0.92);
}
.reps-count-badge {
  font-size: 13px;
  font-weight: 800;
  color: var(--app-text-primary);
  min-width: 50px;
  text-align: center;
}
.reps-dots-box {
  display: flex;
  gap: 4px;
}
.rep-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--app-divider);
}
.rep-dot.filled {
  background: var(--app-accent-green);
}

/* ==========================================================================
   CUPERTINO BOTTOM SHEET MODAL (SEGMENTED PRESETS VS CUSTOM BUILDER)
   ========================================================================== */
.sheet-backdrop {
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.6);
  backdrop-filter: blur(12px);
  z-index: 50;
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.3s ease;
}
.sheet-backdrop.active {
  opacity: 1;
  pointer-events: auto;
}

.cupertino-sheet {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  max-height: 88%;
  background: var(--app-sheet-bg);
  border-radius: 36px 36px 0 0;
  padding: 12px 20px 36px 20px;
  z-index: 60;
  transform: translateY(105%);
  transition: transform 0.35s cubic-bezier(0.16, 1, 0.3, 1);
  display: flex;
  flex-direction: column;
  overflow-y: auto;
}
.sheet-backdrop.active .cupertino-sheet {
  transform: translateY(0);
}

.sheet-handle {
  width: 38px;
  height: 5px;
  background: var(--app-divider);
  border-radius: 4px;
  margin: 0 auto 12px auto;
  flex-shrink: 0;
}
.sheet-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 14px;
}
.sheet-header h3 {
  font-size: 18px;
  font-weight: 800;
  color: var(--app-text-primary);
}
.sheet-close-btn {
  background: var(--app-divider);
  border: none;
  width: 30px;
  height: 30px;
  border-radius: 50%;
  color: var(--app-text-secondary);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

/* Segmented Switcher */
.sheet-segmented-nav {
  display: flex;
  background: var(--app-input-bg);
  border-radius: 14px;
  padding: 3px;
  margin-bottom: 16px;
}
.sheet-nav-tab {
  flex: 1;
  padding: 8px 10px;
  text-align: center;
  border: none;
  background: transparent;
  color: var(--app-text-secondary);
  font-size: 13px;
  font-weight: 700;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s;
}
.sheet-nav-tab.active {
  background: var(--app-card-bg);
  color: var(--app-text-primary);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
}

.categories-tabs {
  display: flex;
  gap: 7px;
  overflow-x: auto;
  padding-bottom: 10px;
  margin-bottom: 14px;
}
.categories-tabs::-webkit-scrollbar {
  display: none;
}
.cat-tab-btn {
  padding: 7px 12px;
  border-radius: 12px;
  background: var(--app-input-bg);
  border: none;
  font-size: 12px;
  font-weight: 600;
  color: var(--app-text-secondary);
  white-space: nowrap;
  cursor: pointer;
}
.cat-tab-btn.active {
  background: var(--app-accent-blue);
  color: #FFFFFF;
}

.presets-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-bottom: 20px;
}
.preset-row-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: var(--app-card-bg);
  border: 1px solid var(--app-card-border);
  padding: 11px 13px;
  border-radius: 15px;
  cursor: pointer;
}
.preset-row-left {
  display: flex;
  align-items: center;
  gap: 10px;
}
.preset-row-left span {
  font-size: 14px;
  font-weight: 700;
  color: var(--app-text-primary);
}
.add-preset-btn {
  background: rgba(0, 122, 255, 0.12);
  color: var(--app-accent-blue);
  border: none;
  font-size: 12px;
  font-weight: 700;
  padding: 5px 11px;
  border-radius: 10px;
  cursor: pointer;
}

/* Custom Form Grid */
.form-group {
  margin-bottom: 14px;
}
.form-label {
  font-size: 11px;
  font-weight: 700;
  color: var(--app-text-muted);
  margin-bottom: 5px;
  display: block;
  letter-spacing: 0.04em;
}
.form-input {
  width: 100%;
  background: var(--app-input-bg);
  border: 1px solid var(--app-divider);
  border-radius: 13px;
  padding: 11px 13px;
  font-size: 14px;
  color: var(--app-text-primary);
  outline: none;
  font-family: inherit;
}
.form-input:focus {
  border-color: var(--app-accent-blue);
}

.submit-habit-btn {
  background: linear-gradient(135deg, #5700CB, #0062E4);
  color: #FFFFFF;
  border: none;
  border-radius: 16px;
  padding: 13px;
  font-size: 15px;
  font-weight: 700;
  cursor: pointer;
  box-shadow: 0 6px 16px rgba(87, 0, 203, 0.35);
}
.submit-habit-btn:active {
  transform: scale(0.98);
}

/* Details & Charts */
.details-nav-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 18px;
}
.back-btn {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 15px;
  font-weight: 600;
  color: var(--app-accent-blue);
  background: transparent;
  border: none;
  cursor: pointer;
}
.details-hero {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  margin-bottom: 20px;
}
.details-hero-icon {
  width: 72px;
  height: 72px;
  border-radius: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  margin-bottom: 12px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.25);
}
.details-title {
  font-size: 20px;
  font-weight: 800;
  color: var(--app-text-primary);
  margin-bottom: 4px;
}
.details-subtitle {
  font-size: 13px;
  color: var(--app-text-secondary);
}

.stats-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  margin-bottom: 18px;
}
.stat-box {
  background: var(--app-card-bg);
  border: 1px solid var(--app-card-border);
  border-radius: 16px;
  padding: 14px;
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.stat-box .stat-label {
  font-size: 11px;
  font-weight: 700;
  color: var(--app-text-muted);
}
.stat-box .stat-value {
  font-size: 22px;
  font-weight: 800;
  color: var(--app-text-primary);
}

.calendar-card {
  background: var(--app-card-bg);
  border: 1px solid var(--app-card-border);
  border-radius: 18px;
  padding: 16px;
  margin-bottom: 18px;
}
.calendar-title {
  font-size: 13px;
  font-weight: 700;
  color: var(--app-text-primary);
  margin-bottom: 12px;
}
.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 6px;
  text-align: center;
}
.cal-day-header {
  font-size: 11px;
  font-weight: 600;
  color: var(--app-text-muted);
}
.cal-cell {
  aspect-ratio: 1;
  border-radius: 7px;
  background: var(--app-divider);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 600;
  color: var(--app-text-secondary);
}
.cal-cell.completed {
  background: var(--app-accent-green);
  color: #FFFFFF;
}

.challenge-hero-banner {
  background: linear-gradient(135deg, #FF416C, #8A2387);
  border-radius: 22px;
  padding: 20px;
  color: white;
  margin-bottom: 18px;
}
.challenge-banner-tag {
  font-size: 10px;
  font-weight: 800;
  text-transform: uppercase;
  background: rgba(255, 255, 255, 0.2);
  padding: 3px 8px;
  border-radius: 14px;
  display: inline-block;
  margin-bottom: 8px;
}
.challenge-hero-banner h3 {
  font-size: 18px;
  font-weight: 800;
  margin-bottom: 4px;
}
.challenge-hero-banner p {
  font-size: 12px;
  opacity: 0.9;
  line-height: 1.4;
  margin-bottom: 14px;
}
.join-challenge-btn {
  background: #FFFFFF;
  color: #0E1326;
  border: none;
  font-size: 13px;
  font-weight: 700;
  padding: 8px 16px;
  border-radius: 14px;
  cursor: pointer;
}

.challenge-card {
  background: var(--app-card-bg);
  border: 1px solid var(--app-card-border);
  border-radius: 18px;
  padding: 14px;
  margin-bottom: 10px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}
.challenge-info h4 {
  font-size: 14px;
  font-weight: 700;
  color: var(--app-text-primary);
  margin-bottom: 2px;
}
.challenge-info p {
  font-size: 11px;
  color: var(--app-text-secondary);
}

.stats-banner {
  background: linear-gradient(135deg, #0062E4, #00C49F);
  border-radius: 22px;
  padding: 18px;
  color: white;
  margin-bottom: 18px;
}
.stats-banner h3 {
  font-size: 24px;
  font-weight: 800;
  margin-bottom: 3px;
}
.stats-banner p {
  font-size: 12px;
  opacity: 0.9;
}

.chart-card {
  background: var(--app-card-bg);
  border: 1px solid var(--app-card-border);
  border-radius: 18px;
  padding: 18px;
  margin-bottom: 18px;
}
.chart-bars {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  height: 110px;
  padding-top: 16px;
  gap: 8px;
}
.bar-col {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  flex: 1;
  height: 100%;
  justify-content: flex-end;
}
.bar-pill {
  width: 100%;
  max-width: 26px;
  background: linear-gradient(180deg, #5700CB, #0062E4);
  border-radius: 6px;
  transition: height 0.6s ease;
}
.bar-label {
  font-size: 11px;
  font-weight: 600;
  color: var(--app-text-muted);
}

#confetti-canvas {
  position: absolute;
  inset: 0;
  pointer-events: none;
  z-index: 150;
}

.ios-toast {
  position: absolute;
  top: 60px;
  left: 50%;
  transform: translateX(-50%) translateY(-20px);
  background: rgba(26, 30, 48, 0.95);
  backdrop-filter: blur(15px);
  color: #FFFFFF;
  padding: 8px 16px;
  border-radius: 18px;
  font-size: 12px;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 6px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
  opacity: 0;
  pointer-events: none;
  z-index: 120;
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}
.ios-toast.active {
  opacity: 1;
  transform: translateX(-50%) translateY(0);
}

@keyframes fadeIn {
  from { opacity: 0; transform: scale(0.96); }
  to { opacity: 1; transform: scale(1); }
}

/* Fullscreen on iPhone / Mobile Devices */
@media (max-width: 500px), (display-mode: standalone) {
  body {
    background-color: var(--app-bg);
  }
  .studio-wrapper {
    padding: 0;
    min-height: 100vh;
  }
  .studio-header,
  .ambient-glow {
    display: none;
  }
  .stage-container {
    width: 100vw;
    height: 100vh;
    height: 100dvh;
  }
  .iphone-frame {
    width: 100vw;
    height: 100vh;
    height: 100dvh;
    border-radius: 0;
    padding: 0;
    box-shadow: none;
    background: transparent;
  }
  .iphone-frame::before,
  .hw-button {
    display: none;
  }
  .screen-bezel {
    border-radius: 0;
    padding: 0;
  }
  .screen-display {
    border-radius: 0;
  }
  .ios-status-bar {
    padding-top: env(safe-area-inset-top, 10px);
    height: calc(48px + env(safe-area-inset-top, 0px));
  }
  .ios-tab-bar {
    padding-bottom: env(safe-area-inset-bottom, 12px);
    height: calc(72px + env(safe-area-inset-bottom, 0px));
  }
}
`;

fs.writeFileSync('styles.css', updatedCss, 'utf8');
console.log('Successfully written styles.css!');
