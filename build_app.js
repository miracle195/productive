const fs = require('fs');
const appData = JSON.parse(fs.readFileSync('app_data.json', 'utf8'));

const jsCode = `/**
 * PRODUCTIVE iOS 17/18 APPLICATION SIMULATOR (app.js)
 * High-fidelity interactive engine with Dynamic Island Live Activity, Audio Synthesizer, Confetti, and Data Persistence
 */

// Embedded Productive App Presets & Categories from SQLite bundled.db
const APP_DATA = ${JSON.stringify(appData)};

const DEFAULT_HABITS = [
  {
    id: 1,
    name: 'Drink water (2L)',
    icon: 'ic_drink',
    color: '#1B8FFF',
    timeOfDay: 'morning',
    repeat: 'Every day',
    completed: true,
    streak: 14,
    bestStreak: 28,
    totalLogs: 92,
    goal: '2.0 Liters',
    history: [1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 18, 19, 20, 21, 22, 23, 24]
  },
  {
    id: 2,
    name: 'Morning stretch & yoga',
    icon: 'ic_yoga',
    color: '#0FC580',
    timeOfDay: 'morning',
    repeat: 'Every day',
    completed: true,
    streak: 8,
    bestStreak: 19,
    totalLogs: 45,
    goal: '15 mins',
    history: [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24]
  },
  {
    id: 3,
    name: 'Go for a brisk walk',
    icon: 'ic_walking',
    color: '#0FC580',
    timeOfDay: 'afternoon',
    repeat: 'Weekdays',
    completed: false,
    streak: 6,
    bestStreak: 14,
    totalLogs: 38,
    goal: '30 mins',
    history: [1, 3, 5, 7, 8, 9, 10, 11, 15, 17, 21, 22]
  },
  {
    id: 4,
    name: 'Eat fruits & healthy lunch',
    icon: 'ic_fruit',
    color: '#0FC580',
    timeOfDay: 'afternoon',
    repeat: 'Every day',
    completed: true,
    streak: 12,
    bestStreak: 21,
    totalLogs: 64,
    goal: '1 meal',
    history: [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 20, 21, 22, 23, 24]
  },
  {
    id: 5,
    name: 'Read a book (20m)',
    icon: 'ic_read',
    color: '#FF7450',
    timeOfDay: 'evening',
    repeat: 'Every day',
    completed: false,
    streak: 21,
    bestStreak: 35,
    totalLogs: 110,
    goal: '20 pages',
    history: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22]
  },
  {
    id: 6,
    name: 'Meditate & relax',
    icon: 'ic_spa',
    color: '#FF7450',
    timeOfDay: 'evening',
    repeat: 'Every day',
    completed: false,
    streak: 5,
    bestStreak: 12,
    totalLogs: 29,
    goal: '10 mins',
    history: [2, 5, 8, 12, 15, 18, 20, 21, 22, 23]
  },
  {
    id: 7,
    name: 'Take daily vitamins',
    icon: 'ic_pills',
    color: '#F8BD32',
    timeOfDay: 'anytime',
    repeat: 'Every day',
    completed: true,
    streak: 30,
    bestStreak: 45,
    totalLogs: 140,
    goal: '1 dose',
    history: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
  }
];

class ProductiveState {
  constructor() {
    this.habits = this.loadHabits();
    this.activeScreen = 'today';
    this.selectedHabitId = 1;
    this.activeCategory = 1;
    this.soundEnabled = true;
    this.islandExpanded = false;
    this.theme = 'dark';
    this.finish = 'natural';
    this.selectedDayIndex = 3;
  }

  loadHabits() {
    try {
      const stored = localStorage.getItem('productive_habits');
      if (stored) return JSON.parse(stored);
    } catch(e) {}
    return JSON.parse(JSON.stringify(DEFAULT_HABITS));
  }

  saveHabits() {
    try {
      localStorage.setItem('productive_habits', JSON.stringify(this.habits));
    } catch(e) {}
  }

  toggleHabit(id) {
    const habit = this.habits.find(h => h.id === id);
    if (!habit) return false;
    habit.completed = !habit.completed;
    if (habit.completed) {
      habit.streak += 1;
      habit.totalLogs += 1;
      if (habit.streak > habit.bestStreak) habit.bestStreak = habit.streak;
      if (!habit.history.includes(24)) habit.history.push(24);
    } else {
      habit.streak = Math.max(0, habit.streak - 1);
      habit.totalLogs = Math.max(0, habit.totalLogs - 1);
    }
    this.saveHabits();
    return habit.completed;
  }

  addHabit(name, icon, color, timeOfDay, repeat = 'Every day') {
    const newId = Date.now();
    const habit = {
      id: newId,
      name,
      icon,
      color,
      timeOfDay,
      repeat,
      completed: false,
      streak: 0,
      bestStreak: 0,
      totalLogs: 0,
      goal: '1 time',
      history: []
    };
    this.habits.unshift(habit);
    this.saveHabits();
    return habit;
  }

  deleteHabit(id) {
    this.habits = this.habits.filter(h => h.id !== id);
    this.saveHabits();
  }

  resetAll() {
    this.habits = JSON.parse(JSON.stringify(DEFAULT_HABITS));
    this.saveHabits();
  }

  getCompletionRate() {
    if (this.habits.length === 0) return 0;
    const completed = this.habits.filter(h => h.completed).length;
    return Math.round((completed / this.habits.length) * 100);
  }
}

const state = new ProductiveState();

class SoundFX {
  constructor() {
    this.ctx = null;
  }

  init() {
    if (!this.ctx) {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (AudioCtx) this.ctx = new AudioCtx();
    }
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
  }

  playClick() {
    if (!state.soundEnabled) return;
    this.init();
    if (!this.ctx) return;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(800, this.ctx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(300, this.ctx.currentTime + 0.04);
    gain.gain.setValueAtTime(0.12, this.ctx.currentTime);
    gain.gain.linearRampToValueAtTime(0.01, this.ctx.currentTime + 0.04);
    osc.connect(gain);
    gain.connect(this.ctx.destination);
    osc.start();
    osc.stop(this.ctx.currentTime + 0.04);
  }

  playSuccess() {
    if (!state.soundEnabled) return;
    this.init();
    if (!this.ctx) return;
    const notes = [523.25, 659.25, 783.99, 1046.50];
    notes.forEach((freq, idx) => {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.value = freq;
      const startTime = this.ctx.currentTime + idx * 0.07;
      gain.gain.setValueAtTime(0, startTime);
      gain.gain.linearRampToValueAtTime(0.18, startTime + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.001, startTime + 0.35);
      osc.connect(gain);
      gain.connect(this.ctx.destination);
      osc.start(startTime);
      osc.stop(startTime + 0.36);
    });
  }

  playWhoosh() {
    if (!state.soundEnabled) return;
    this.init();
    if (!this.ctx) return;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(220, this.ctx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(580, this.ctx.currentTime + 0.12);
    gain.gain.setValueAtTime(0.15, this.ctx.currentTime);
    gain.gain.linearRampToValueAtTime(0.01, this.ctx.currentTime + 0.12);
    osc.connect(gain);
    gain.connect(this.ctx.destination);
    osc.start();
    osc.stop(this.ctx.currentTime + 0.12);
  }

  playHaptic() {
    if (!state.soundEnabled) return;
    this.init();
    if (!this.ctx) return;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(90, this.ctx.currentTime);
    gain.gain.setValueAtTime(0.3, this.ctx.currentTime);
    gain.gain.linearRampToValueAtTime(0.01, this.ctx.currentTime + 0.06);
    osc.connect(gain);
    gain.connect(this.ctx.destination);
    osc.start();
    osc.stop(this.ctx.currentTime + 0.06);
  }
}

const sound = new SoundFX();

class ConfettiEngine {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.particles = [];
    this.animationId = null;
    this.resize();
    window.addEventListener('resize', () => this.resize());
  }

  resize() {
    if (!this.canvas || !this.canvas.parentElement) return;
    this.canvas.width = this.canvas.parentElement.clientWidth;
    this.canvas.height = this.canvas.parentElement.clientHeight;
  }

  burst(x, y) {
    const colors = ['#5700CB', '#0062E4', '#0FC580', '#FF7450', '#F8BD32', '#F63566'];
    for (let i = 0; i < 40; i++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = 3 + Math.random() * 7;
      this.particles.push({
        x: x || this.canvas.width / 2,
        y: y || this.canvas.height / 2,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed - 2,
        color: colors[Math.floor(Math.random() * colors.length)],
        radius: 3 + Math.random() * 4,
        rotation: Math.random() * 360,
        vr: (Math.random() - 0.5) * 12,
        life: 1,
        decay: 0.02 + Math.random() * 0.02
      });
    }
    if (!this.animationId) this.loop();
  }

  loop() {
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    for (let i = this.particles.length - 1; i >= 0; i--) {
      const p = this.particles[i];
      p.x += p.vx;
      p.y += p.vy;
      p.vy += 0.22;
      p.rotation += p.vr;
      p.life -= p.decay;

      if (p.life <= 0) {
        this.particles.splice(i, 1);
        continue;
      }

      this.ctx.save();
      this.ctx.translate(p.x, p.y);
      this.ctx.rotate((p.rotation * Math.PI) / 180);
      this.ctx.fillStyle = p.color;
      this.ctx.globalAlpha = p.life;
      this.ctx.fillRect(-p.radius, -p.radius, p.radius * 2, p.radius * 1.4);
      this.ctx.restore();
    }

    if (this.particles.length > 0) {
      this.animationId = requestAnimationFrame(() => this.loop());
    } else {
      this.animationId = null;
    }
  }
}

let confetti;

function getIconSvg(iconName, color = 'currentColor', size = 22) {
  let paths = APP_DATA.iconPaths[iconName] || APP_DATA.iconPaths[iconName + '___'];
  if (!paths || paths.length === 0) {
    return '<svg width="' + size + '" height="' + size + '" viewBox="0 0 24 24" fill="' + color + '"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg>';
  }
  const pathElements = paths.map(d => '<path d="' + d + '" fill="' + color + '" />').join('');
  return '<svg width="' + size + '" height="' + size + '" viewBox="0 0 24 24">' + pathElements + '</svg>';
}

function updateLiveClock() {
  const clockEl = document.getElementById('status-time-clock');
  if (!clockEl) return;
  const now = new Date();
  let hours = now.getHours();
  let mins = now.getMinutes();
  mins = mins < 10 ? '0' + mins : mins;
  clockEl.textContent = hours + ':' + mins;
}

function renderTodayScreen() {
  const container = document.getElementById('today-habits-container');
  if (!container) return;

  const rate = state.getCompletionRate();
  const total = state.habits.length;
  const completed = state.habits.filter(h => h.completed).length;

  const gaugeVal = document.getElementById('hero-gauge-val');
  const gaugeText = document.getElementById('hero-gauge-text');
  const heroSubtitle = document.getElementById('hero-motivation-sub');
  const heroTitle = document.getElementById('hero-motivation-title');

  if (gaugeVal) {
    const offset = 220 - (220 * rate) / 100;
    gaugeVal.style.strokeDashoffset = offset;
  }
  if (gaugeText) gaugeText.textContent = rate + '%';
  if (heroSubtitle) heroSubtitle.textContent = completed + ' of ' + total + ' completed today';
  if (heroTitle) {
    if (rate === 100) heroTitle.textContent = 'All habits completed! 🎉';
    else if (rate >= 60) heroTitle.textContent = 'You are crushing it today! 🔥';
    else if (rate > 0) heroTitle.textContent = 'Keep your momentum going! 👏';
    else heroTitle.textContent = 'Ready to build habits today? 💪';
  }

  const timeBuckets = [
    { id: 'morning', label: 'Morning', icon: '🌅' },
    { id: 'afternoon', label: 'Afternoon', icon: '☀️' },
    { id: 'evening', label: 'Evening', icon: '🌙' },
    { id: 'anytime', label: 'Anytime', icon: '⏰' }
  ];

  let html = '';

  timeBuckets.forEach(bucket => {
    const habits = state.habits.filter(h => h.timeOfDay === bucket.id);
    if (habits.length === 0) return;

    html += '<div class="section-header">';
    html += '<div class="section-title"><span>' + bucket.icon + '</span><span>' + bucket.label + '</span></div>';
    html += '<span class="section-count">' + habits.filter(h => h.completed).length + '/' + habits.length + '</span>';
    html += '</div>';

    habits.forEach(habit => {
      const isCompleted = habit.completed;
      html += '<div class="habit-card ' + (isCompleted ? 'completed' : '') + '" data-id="' + habit.id + '" onclick="onHabitCardClick(event, ' + habit.id + ')">';
      html += '<div class="habit-main">';
      html += '<div class="habit-icon-wrapper" style="background: ' + habit.color + '">' + getIconSvg(habit.icon, '#FFFFFF', 22) + '</div>';
      html += '<div class="habit-details">';
      html += '<span class="habit-name">' + habit.name + '</span>';
      html += '<div class="habit-meta"><span>' + habit.repeat + '</span><span>•</span><span class="habit-streak-badge">🔥 ' + habit.streak + ' days</span></div>';
      html += '</div>';
      html += '</div>';
      html += '<button class="habit-check-btn" onclick="onHabitCheckClick(event, ' + habit.id + ')" aria-label="Toggle habit completion">';
      html += '<svg viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"></polyline></svg>';
      html += '</button>';
      html += '</div>';
    });
  });

  container.innerHTML = html;
}

function renderHabitDetails(id) {
  const habit = state.habits.find(h => h.id === id);
  if (!habit) return;
  state.selectedHabitId = id;

  const iconEl = document.getElementById('details-hero-icon');
  const titleEl = document.getElementById('details-title');
  const subEl = document.getElementById('details-subtitle');
  const curStreakEl = document.getElementById('details-cur-streak');
  const bestStreakEl = document.getElementById('details-best-streak');
  const totalLogsEl = document.getElementById('details-total-logs');
  const rateEl = document.getElementById('details-rate');
  const calendarEl = document.getElementById('details-cal-grid');

  if (iconEl) {
    iconEl.style.background = habit.color;
    iconEl.innerHTML = getIconSvg(habit.icon, '#FFFFFF', 38);
  }
  if (titleEl) titleEl.textContent = habit.name;
  if (subEl) subEl.textContent = habit.repeat + ' • ' + habit.timeOfDay.toUpperCase() + ' • Target: ' + habit.goal;
  if (curStreakEl) curStreakEl.textContent = habit.streak + 'd';
  if (bestStreakEl) bestStreakEl.textContent = habit.bestStreak + 'd';
  if (totalLogsEl) totalLogsEl.textContent = habit.totalLogs;
  if (rateEl) {
    const rate = Math.min(100, Math.round((habit.totalLogs / 30) * 100));
    rateEl.textContent = rate + '%';
  }

  if (calendarEl) {
    let daysHtml = '';
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    dayLabels.forEach(d => {
      daysHtml += '<div class="cal-day-header">' + d + '</div>';
    });
    for (let day = 1; day <= 28; day++) {
      const isDone = habit.history.includes(day);
      daysHtml += '<div class="cal-cell ' + (isDone ? 'completed' : '') + '">' + day + '</div>';
    }
    calendarEl.innerHTML = daysHtml;
  }
}

function renderChallengesScreen() {
  const container = document.getElementById('challenges-list-container');
  if (!container) return;

  const challenges = [
    { title: '21-Day Morning Miracle', desc: 'Wake up early, drink water, and do 15m stretch', days: 21, active: true, progress: 8 },
    { title: 'Hydration Hero Challenge', desc: 'Reach 2.5L daily hydration for 14 straight days', days: 14, active: false, progress: 0 },
    { title: 'Digital Detox & Sleep', desc: 'No screens in bed after 10 PM for 7 nights', days: 7, active: false, progress: 0 },
    { title: '30-Day Fitness Momentum', desc: 'Workout or walk 30 mins every single day', days: 30, active: false, progress: 0 }
  ];

  let html = '';
  challenges.forEach(ch => {
    html += '<div class="challenge-card">';
    html += '<div class="challenge-info"><h4>' + ch.title + '</h4><p>' + ch.desc + '</p></div>';
    html += '<button class="join-challenge-btn" onclick="onJoinChallengeClick(event, \\'' + ch.title + '\\')">';
    html += (ch.active ? 'Day ' + ch.progress + '/21' : 'Join');
    html += '</button>';
    html += '</div>';
  });
  container.innerHTML = html;
}

function renderSheetPresets() {
  const tabsContainer = document.getElementById('sheet-cat-tabs');
  const presetsContainer = document.getElementById('sheet-presets-list');
  if (!tabsContainer || !presetsContainer) return;

  let tabsHtml = '';
  APP_DATA.categories.forEach(cat => {
    tabsHtml += '<button class="cat-tab-btn ' + (cat.id === state.activeCategory ? 'active' : '') + '" onclick="onSelectSheetCategory(' + cat.id + ')">';
    tabsHtml += cat.name;
    tabsHtml += '</button>';
  });
  tabsContainer.innerHTML = tabsHtml;

  const filteredPresets = APP_DATA.presets.filter(p => p.categoryIds.includes(state.activeCategory)).slice(0, 14);
  let presetsHtml = '';
  filteredPresets.forEach(preset => {
    presetsHtml += '<div class="preset-row-item" onclick="onAddPresetDirectly(' + preset.id + ')">';
    presetsHtml += '<div class="preset-row-left">';
    presetsHtml += '<div class="habit-icon-wrapper" style="width: 36px; height: 36px; border-radius: 10px; background: ' + preset.color + '">';
    presetsHtml += getIconSvg(preset.icon, '#FFFFFF', 18);
    presetsHtml += '</div>';
    presetsHtml += '<span>' + preset.name + '</span>';
    presetsHtml += '</div>';
    presetsHtml += '<button class="add-preset-btn">+ Add</button>';
    presetsHtml += '</div>';
  });
  presetsContainer.innerHTML = presetsHtml;
}

function showToast(message) {
  const toast = document.getElementById('ios-toast');
  if (!toast) return;
  toast.querySelector('.toast-msg').textContent = message;
  toast.classList.add('active');
  setTimeout(() => {
    toast.classList.remove('active');
  }, 2200);
}

function onHabitCheckClick(e, id) {
  e.stopPropagation();
  sound.playClick();
  const completed = state.toggleHabit(id);
  if (completed) {
    sound.playSuccess();
    const rect = e.target.getBoundingClientRect();
    confetti.burst(rect.left + rect.width / 2, rect.top + rect.height / 2);
    showToast('Habit completed! Streak extended 🔥');
    pulseDynamicIsland('Completed! 🔥');
  }
  renderTodayScreen();
}

function onHabitCardClick(e, id) {
  sound.playClick();
  renderHabitDetails(id);
  switchScreen('details');
}

function switchScreen(screenName) {
  state.activeScreen = screenName;
  sound.playWhoosh();
  document.querySelectorAll('.screen-view').forEach(s => s.classList.remove('active'));
  const target = document.getElementById('screen-' + screenName);
  if (target) target.classList.add('active');

  document.querySelectorAll('.tab-item').forEach(t => {
    t.classList.toggle('active', t.dataset.screen === screenName);
  });
}

function pulseDynamicIsland(text) {
  const island = document.getElementById('dynamic-island');
  const title = document.getElementById('island-pulse-title');
  if (title) title.textContent = text;
  if (!island.classList.contains('expanded')) {
    island.style.width = '160px';
    setTimeout(() => {
      if (!island.classList.contains('expanded')) island.style.width = 'var(--island-width)';
    }, 1200);
  }
}

function toggleDynamicIsland() {
  sound.playWhoosh();
  const island = document.getElementById('dynamic-island');
  island.classList.toggle('expanded');
  state.islandExpanded = island.classList.contains('expanded');
}

function triggerActionButton() {
  sound.playHaptic();
  const pending = state.habits.find(h => !h.completed);
  if (pending) {
    state.toggleHabit(pending.id);
    sound.playSuccess();
    confetti.burst();
    showToast('Quick Logged: ' + pending.name + ' 🎉');
    pulseDynamicIsland('Logged: ' + pending.name);
    renderTodayScreen();
  } else {
    showToast('All habits already completed today! 🔥');
  }
}

function openAddHabitSheet() {
  sound.playWhoosh();
  renderSheetPresets();
  document.getElementById('sheet-backdrop').classList.add('active');
}

function closeAddHabitSheet() {
  sound.playClick();
  document.getElementById('sheet-backdrop').classList.remove('active');
}

function onSelectSheetCategory(catId) {
  sound.playClick();
  state.activeCategory = catId;
  renderSheetPresets();
}

function onAddPresetDirectly(presetId) {
  sound.playSuccess();
  const preset = APP_DATA.presets.find(p => p.id === presetId);
  if (preset) {
    state.addHabit(preset.name, preset.icon, preset.color, preset.timeOfDay);
    closeAddHabitSheet();
    renderTodayScreen();
    showToast('Added: ' + preset.name);
    confetti.burst();
  }
}

function onJoinChallengeClick(e, title) {
  e.stopPropagation();
  sound.playSuccess();
  confetti.burst();
  showToast('Joined Challenge: ' + title + '! 🎉');
}

function setDeviceFinish(finish) {
  state.finish = finish;
  document.documentElement.dataset.finish = finish;
  document.querySelectorAll('.finish-dot').forEach(d => {
    d.classList.toggle('active', d.dataset.finish === finish);
  });
  sound.playClick();
}

function toggleTheme() {
  state.theme = state.theme === 'dark' ? 'light' : 'dark';
  document.documentElement.dataset.appTheme = state.theme;
  const btn = document.getElementById('tool-theme-btn');
  if (btn) btn.innerHTML = state.theme === 'dark' ? '🌙 Dark' : '☀️ Light';
  sound.playClick();
}

function toggleSound() {
  state.soundEnabled = !state.soundEnabled;
  const btn = document.getElementById('tool-sound-btn');
  if (btn) btn.innerHTML = state.soundEnabled ? '🔊 Sound: ON' : '🔇 Sound: OFF';
  if (state.soundEnabled) sound.playClick();
}

window.addEventListener('DOMContentLoaded', () => {
  confetti = new ConfettiEngine(document.getElementById('confetti-canvas'));
  updateLiveClock();
  setInterval(updateLiveClock, 30000);

  renderTodayScreen();
  renderChallengesScreen();

  document.querySelectorAll('.tab-item').forEach(tab => {
    tab.addEventListener('click', () => {
      const scr = tab.dataset.screen;
      if (scr) switchScreen(scr);
    });
  });

  const island = document.getElementById('dynamic-island');
  island.addEventListener('click', (e) => {
    if (e.target.closest('.island-quick-btn')) {
      e.stopPropagation();
      triggerActionButton();
      return;
    }
    toggleDynamicIsland();
  });

  document.getElementById('hw-action-btn').addEventListener('click', triggerActionButton);

  window.addEventListener('keydown', (e) => {
    if (e.code === 'Space' && e.target.tagName !== 'INPUT') {
      e.preventDefault();
      triggerActionButton();
    }
    if (e.key === 'd' || e.key === 'D') toggleDynamicIsland();
    if (e.key === 't' || e.key === 'T') toggleTheme();
  });

  const customForm = document.getElementById('custom-habit-form');
  if (customForm) {
    customForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const name = document.getElementById('custom-name-input').value.trim();
      const timeOfDay = document.getElementById('custom-time-select').value;
      const color = document.getElementById('custom-color-select').value;
      const icon = document.getElementById('custom-icon-select').value;
      if (!name) return;
      state.addHabit(name, icon, color, timeOfDay);
      closeAddHabitSheet();
      renderTodayScreen();
      showToast('Created: ' + name + ' 🎉');
      confetti.burst();
    });
  }
});
`;

fs.writeFileSync('app.js', jsCode, 'utf8');
console.log('Successfully written app.js!');
