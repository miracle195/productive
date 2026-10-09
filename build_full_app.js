const fs = require('fs');
const appData = JSON.parse(fs.readFileSync('app_data.json', 'utf8'));

console.log('Generating multi-mode interactive app.js and index.html...');

const appJsCode = `/**
 * PRODUCTIVE iOS 17/18 - ADVANCED MULTI-MODE ENGINE (app.js)
 * Full support for Amount/Units, Multi-Reps, Timers, Strict/Fatal mode, and Past-Day Navigation
 */

const APP_DATA = ${JSON.stringify(appData)};

const DEFAULT_HABITS = [
  {
    id: 1,
    name: 'Drink water (2L)',
    icon: 'ic_drink',
    color: '#1B8FFF',
    timeOfDay: 'morning',
    type: 'amount',
    targetAmount: 2000,
    currentAmount: 1500,
    unit: 'ml',
    stepAmount: 250,
    frequency: 'daily',
    repeatLabel: 'Every day',
    strictness: 'strict', // 'strict' (Fatal) | 'flexible' | 'rollover'
    streak: 14,
    bestStreak: 28,
    totalLogs: 92,
    history: { 21: { done: true, amount: 2000 }, 22: { done: true, amount: 2000 }, 23: { done: true, amount: 2000 }, 24: { done: false, amount: 1500 } }
  },
  {
    id: 2,
    name: 'Morning stretch & yoga',
    icon: 'ic_yoga',
    color: '#0FC580',
    timeOfDay: 'morning',
    type: 'timer',
    targetDuration: 15, // mins
    timerSeconds: 15 * 60,
    isTimerRunning: false,
    frequency: 'daily',
    repeatLabel: 'Every day',
    strictness: 'flexible',
    streak: 8,
    bestStreak: 19,
    totalLogs: 45,
    history: { 21: { done: true }, 22: { done: true }, 23: { done: true }, 24: { done: true } }
  },
  {
    id: 3,
    name: 'Take daily vitamins',
    icon: 'ic_pills',
    color: '#F8BD32',
    timeOfDay: 'morning',
    type: 'reps',
    targetReps: 2,
    currentReps: 1,
    frequency: 'daily',
    repeatLabel: '2 times a day',
    strictness: 'strict',
    streak: 30,
    bestStreak: 45,
    totalLogs: 140,
    history: { 21: { done: true }, 22: { done: true }, 23: { done: true }, 24: { done: false, reps: 1 } }
  },
  {
    id: 4,
    name: 'Go for a brisk walk',
    icon: 'ic_walking',
    color: '#0FC580',
    timeOfDay: 'afternoon',
    type: 'amount',
    targetAmount: 30,
    currentAmount: 15,
    unit: 'mins',
    stepAmount: 10,
    frequency: 'every_2_days',
    repeatLabel: 'Every 2 days',
    strictness: 'flexible',
    streak: 6,
    bestStreak: 14,
    totalLogs: 38,
    history: { 21: { done: true, amount: 30 }, 22: { done: false }, 23: { done: true, amount: 30 }, 24: { done: false, amount: 15 } }
  },
  {
    id: 5,
    name: 'Eat fruits & veggies',
    icon: 'ic_fruit',
    color: '#0FC580',
    timeOfDay: 'afternoon',
    type: 'reps',
    targetReps: 3,
    currentReps: 3,
    frequency: 'daily',
    repeatLabel: '3 times a day',
    strictness: 'rollover',
    streak: 12,
    bestStreak: 21,
    totalLogs: 64,
    history: { 21: { done: true }, 22: { done: true }, 23: { done: true }, 24: { done: true, reps: 3 } }
  },
  {
    id: 6,
    name: 'Read a book (20m)',
    icon: 'ic_read',
    color: '#FF7450',
    timeOfDay: 'evening',
    type: 'amount',
    targetAmount: 20,
    currentAmount: 0,
    unit: 'pages',
    stepAmount: 5,
    frequency: 'daily',
    repeatLabel: 'Every day',
    strictness: 'strict',
    streak: 21,
    bestStreak: 35,
    totalLogs: 110,
    history: { 21: { done: true, amount: 20 }, 22: { done: true, amount: 20 }, 23: { done: true, amount: 20 }, 24: { done: false, amount: 0 } }
  },
  {
    id: 7,
    name: 'Meditate & relax',
    icon: 'ic_spa',
    color: '#FF7450',
    timeOfDay: 'evening',
    type: 'binary',
    frequency: 'weekdays',
    repeatLabel: 'Weekdays (Mon-Fri)',
    strictness: 'flexible',
    streak: 5,
    bestStreak: 12,
    totalLogs: 29,
    history: { 21: { done: true }, 22: { done: true }, 23: { done: true }, 24: { done: false } }
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
    this.selectedDay = 24; // Today is Thursday 24
    this.todayDay = 24;
    this.sheetTab = 'presets'; // 'presets' | 'custom'
    this.customTrackingMode = 'binary';
    this.activeTimerHabitId = null;
    this.timerInterval = null;
  }

  loadHabits() {
    try {
      const stored = localStorage.getItem('productive_habits_v2');
      if (stored) return JSON.parse(stored);
    } catch(e) {}
    return JSON.parse(JSON.stringify(DEFAULT_HABITS));
  }

  saveHabits() {
    try {
      localStorage.setItem('productive_habits_v2', JSON.stringify(this.habits));
    } catch(e) {}
  }

  isDayToday() {
    return this.selectedDay === this.todayDay;
  }

  isDayPast() {
    return this.selectedDay < this.todayDay;
  }

  getHabitStatusOnSelectedDay(habit) {
    const dayData = habit.history[this.selectedDay];
    if (dayData && dayData.done) return 'completed';
    if (this.isDayPast()) {
      if (habit.strictness === 'strict') return 'fatal_missed';
      return 'uncompleted_flexible';
    }
    return (dayData && dayData.done) ? 'completed' : 'pending';
  }

  toggleBinaryHabit(id) {
    const habit = this.habits.find(h => h.id === id);
    if (!habit) return false;
    const status = this.getHabitStatusOnSelectedDay(habit);
    if (status === 'fatal_missed') return false; // Locked!

    if (!habit.history[this.selectedDay]) habit.history[this.selectedDay] = {};
    const willBeDone = !habit.history[this.selectedDay].done;
    habit.history[this.selectedDay].done = willBeDone;

    if (this.isDayToday()) {
      if (willBeDone) {
        habit.streak += 1;
        habit.totalLogs += 1;
        if (habit.streak > habit.bestStreak) habit.bestStreak = habit.streak;
      } else {
        habit.streak = Math.max(0, habit.streak - 1);
        habit.totalLogs = Math.max(0, habit.totalLogs - 1);
      }
    }
    this.saveHabits();
    return willBeDone;
  }

  incrementAmount(id, step) {
    const habit = this.habits.find(h => h.id === id);
    if (!habit) return false;
    const status = this.getHabitStatusOnSelectedDay(habit);
    if (status === 'fatal_missed') return false;

    if (!habit.history[this.selectedDay]) habit.history[this.selectedDay] = { amount: 0, done: false };
    const cur = habit.history[this.selectedDay].amount || 0;
    const newAmt = Math.min(habit.targetAmount * 2, cur + step);
    habit.history[this.selectedDay].amount = newAmt;
    if (this.isDayToday()) habit.currentAmount = newAmt;

    const completed = newAmt >= habit.targetAmount;
    const wasCompleted = habit.history[this.selectedDay].done;
    habit.history[this.selectedDay].done = completed;

    if (completed && !wasCompleted && this.isDayToday()) {
      habit.streak += 1;
      habit.totalLogs += 1;
      if (habit.streak > habit.bestStreak) habit.bestStreak = habit.streak;
    }
    this.saveHabits();
    return completed;
  }

  stepReps(id, delta) {
    const habit = this.habits.find(h => h.id === id);
    if (!habit) return false;
    const status = this.getHabitStatusOnSelectedDay(habit);
    if (status === 'fatal_missed') return false;

    if (!habit.history[this.selectedDay]) habit.history[this.selectedDay] = { reps: 0, done: false };
    const cur = habit.history[this.selectedDay].reps || 0;
    const newReps = Math.max(0, Math.min(habit.targetReps, cur + delta));
    habit.history[this.selectedDay].reps = newReps;
    if (this.isDayToday()) habit.currentReps = newReps;

    const completed = newReps >= habit.targetReps;
    const wasCompleted = habit.history[this.selectedDay].done;
    habit.history[this.selectedDay].done = completed;

    if (completed && !wasCompleted && this.isDayToday()) {
      habit.streak += 1;
      habit.totalLogs += 1;
      if (habit.streak > habit.bestStreak) habit.bestStreak = habit.streak;
    }
    this.saveHabits();
    return completed;
  }

  addCustomHabit(data) {
    const newId = Date.now();
    const habit = {
      id: newId,
      name: data.name,
      icon: data.icon || 'ic_all_habits',
      color: data.color || '#5700CB',
      timeOfDay: data.timeOfDay || 'morning',
      type: data.type || 'binary',
      targetAmount: Number(data.targetAmount) || 2000,
      currentAmount: 0,
      unit: data.unit || 'ml',
      stepAmount: Number(data.stepAmount) || 250,
      targetReps: Number(data.targetReps) || 3,
      currentReps: 0,
      targetDuration: Number(data.targetDuration) || 15,
      timerSeconds: (Number(data.targetDuration) || 15) * 60,
      isTimerRunning: false,
      frequency: data.frequency || 'daily',
      repeatLabel: data.repeatLabel || 'Every day',
      strictness: data.strictness || 'strict',
      streak: 0,
      bestStreak: 0,
      totalLogs: 0,
      history: {}
    };
    this.habits.unshift(habit);
    this.saveHabits();
    return habit;
  }

  getCompletionRate() {
    if (this.habits.length === 0) return 0;
    let completed = 0;
    this.habits.forEach(h => {
      const dayData = h.history[this.selectedDay];
      if (dayData && dayData.done) completed++;
    });
    return Math.round((completed / this.habits.length) * 100);
  }
}

const state = new ProductiveState();

class SoundFX {
  constructor() { this.ctx = null; }
  init() {
    if (!this.ctx) {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (AudioCtx) this.ctx = new AudioCtx();
    }
    if (this.ctx && this.ctx.state === 'suspended') this.ctx.resume();
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

// Render Date Banner
function renderDateBanner() {
  const banner = document.getElementById('date-view-banner');
  if (!banner) return;
  if (state.selectedDay === state.todayDay) {
    banner.style.display = 'none';
  } else {
    banner.style.display = 'flex';
    const dayNames = { 21: 'Monday, Oct 21', 22: 'Tuesday, Oct 22', 23: 'Wednesday, Oct 23', 25: 'Friday, Oct 25', 26: 'Saturday, Oct 26', 27: 'Sunday, Oct 27' };
    const label = dayNames[state.selectedDay] || ('Day ' + state.selectedDay);
    banner.innerHTML = '<span>🗓️ Viewing: ' + label + ' (' + (state.isDayPast() ? 'Past' : 'Future') + ')</span><button onclick="selectDay(24)">Today</button>';
  }
}

// Render Today Screen
function renderTodayScreen() {
  const container = document.getElementById('today-habits-container');
  if (!container) return;

  renderDateBanner();

  const rate = state.getCompletionRate();
  const total = state.habits.length;
  let completed = 0;
  state.habits.forEach(h => {
    const dayData = h.history[state.selectedDay];
    if (dayData && dayData.done) completed++;
  });

  const gaugeVal = document.getElementById('hero-gauge-val');
  const gaugeText = document.getElementById('hero-gauge-text');
  const heroSubtitle = document.getElementById('hero-motivation-sub');
  const heroTitle = document.getElementById('hero-motivation-title');

  if (gaugeVal) {
    const offset = 220 - (220 * rate) / 100;
    gaugeVal.style.strokeDashoffset = offset;
  }
  if (gaugeText) gaugeText.textContent = rate + '%';
  if (heroSubtitle) heroSubtitle.textContent = completed + ' of ' + total + ' completed ' + (state.isDayToday() ? 'today' : 'on selected date');
  if (heroTitle) {
    if (rate === 100) heroTitle.textContent = 'All goals done! 🎉';
    else if (rate >= 60) heroTitle.textContent = 'Crushing your habits! 🔥';
    else if (rate > 0) heroTitle.textContent = 'Keep momentum going! 👏';
    else heroTitle.textContent = 'Build your daily streak! 💪';
  }

  // Update Week Ribbon
  document.querySelectorAll('.day-pill').forEach(pill => {
    const day = Number(pill.dataset.day);
    pill.classList.toggle('active', day === state.selectedDay);
  });

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

    let bucketCompleted = 0;
    habits.forEach(h => {
      const d = h.history[state.selectedDay];
      if (d && d.done) bucketCompleted++;
    });

    html += '<div class="section-header">';
    html += '<div class="section-title"><span>' + bucket.icon + '</span><span>' + bucket.label + '</span></div>';
    html += '<span class="section-count">' + bucketCompleted + '/' + habits.length + '</span>';
    html += '</div>';

    habits.forEach(habit => {
      const status = state.getHabitStatusOnSelectedDay(habit);
      const isCompleted = status === 'completed';
      const isFatalMissed = status === 'fatal_missed';

      html += '<div class="habit-card ' + (isCompleted ? 'completed' : '') + ' ' + (isFatalMissed ? 'fatal-missed' : '') + '" onclick="onHabitCardClick(event, ' + habit.id + ')">';
      
      // Top Row
      html += '<div class="habit-card-top">';
      html += '<div class="habit-main">';
      html += '<div class="habit-icon-wrapper" style="background: ' + habit.color + '">' + getIconSvg(habit.icon, '#FFFFFF', 22) + '</div>';
      html += '<div class="habit-details">';
      html += '<span class="habit-name">' + habit.name + '</span>';
      
      // Tag Badges
      html += '<div class="habit-tags-row">';
      html += '<span class="habit-tag tag-freq">' + habit.repeatLabel + '</span>';
      if (habit.strictness === 'strict') {
        html += '<span class="habit-tag tag-strict">⚡ Fatal Strict</span>';
      } else if (habit.strictness === 'flexible') {
        html += '<span class="habit-tag tag-flexible">🛡️ Flexible</span>';
      } else if (habit.strictness === 'rollover') {
        html += '<span class="habit-tag tag-rollover">🔄 Rollover</span>';
      }
      html += '<span style="color:#FF7450; font-size:11px; font-weight:700;">🔥 ' + habit.streak + 'd</span>';
      html += '</div>'; // tags-row

      html += '</div>'; // details
      html += '</div>'; // main

      // Check Button
      if (isFatalMissed) {
        html += '<button class="habit-check-btn" title="Missed! Fatal strictness resets streak" disabled>';
        html += '<span style="font-size:14px;">🔒</span>';
        html += '</button>';
      } else {
        html += '<button class="habit-check-btn" onclick="onHabitCheckClick(event, ' + habit.id + ')" aria-label="Toggle habit">';
        html += '<svg viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"></polyline></svg>';
        html += '</button>';
      }
      html += '</div>'; // habit-card-top

      // Multi-Mode Body Sections
      if (habit.type === 'amount') {
        const dayAmount = (habit.history[state.selectedDay] && habit.history[state.selectedDay].amount) || (state.isDayToday() ? habit.currentAmount : 0);
        const percent = Math.min(100, Math.round((dayAmount / habit.targetAmount) * 100));
        html += '<div class="amount-progress-section">';
        html += '<div class="amount-text-row">';
        html += '<span>' + dayAmount + ' / ' + habit.targetAmount + ' ' + habit.unit + '</span>';
        html += '<span>' + percent + '%</span>';
        html += '</div>';
        html += '<div class="amount-track"><div class="amount-fill" style="width: ' + percent + '%;"></div></div>';
        
        if (!isFatalMissed && !isCompleted) {
          html += '<div class="amount-chip-buttons" onclick="event.stopPropagation()">';
          html += '<button class="amount-chip" onclick="onAddAmount(event, ' + habit.id + ', ' + habit.stepAmount + ')">+' + habit.stepAmount + ' ' + habit.unit + '</button>';
          html += '<button class="amount-chip" onclick="onAddAmount(event, ' + habit.id + ', ' + (habit.stepAmount * 2) + ')">+' + (habit.stepAmount * 2) + ' ' + habit.unit + '</button>';
          html += '</div>';
        }
        html += '</div>'; // amount-progress-section
      } else if (habit.type === 'reps') {
        const dayReps = (habit.history[state.selectedDay] && habit.history[state.selectedDay].reps) || (state.isDayToday() ? habit.currentReps : 0);
        html += '<div class="reps-progress-section">';
        html += '<div class="reps-dots-box">';
        for (let r = 1; r <= habit.targetReps; r++) {
          html += '<div class="rep-dot ' + (r <= dayReps ? 'filled' : '') + '"></div>';
        }
        html += '</div>';
        
        if (!isFatalMissed) {
          html += '<div class="reps-stepper" onclick="event.stopPropagation()">';
          html += '<button class="reps-btn" onclick="onStepReps(event, ' + habit.id + ', -1)">-</button>';
          html += '<span class="reps-count-badge">' + dayReps + ' / ' + habit.targetReps + '</span>';
          html += '<button class="reps-btn" onclick="onStepReps(event, ' + habit.id + ', 1)">+</button>';
          html += '</div>';
        } else {
          html += '<span style="font-size:12px; color:#FF5A5F; font-weight:700;">Streak Missed</span>';
        }
        html += '</div>'; // reps-progress-section
      }

      html += '</div>'; // habit-card
    });
  });

  container.innerHTML = html;
}

function onHabitCheckClick(e, id) {
  e.stopPropagation();
  sound.playClick();
  const completed = state.toggleBinaryHabit(id);
  if (completed) {
    sound.playSuccess();
    const rect = e.target.getBoundingClientRect();
    confetti.burst(rect.left + rect.width / 2, rect.top + rect.height / 2);
    showToast('Goal completed! Streak extended 🔥');
    pulseDynamicIsland('Completed! 🔥');
  }
  renderTodayScreen();
}

function onAddAmount(e, id, step) {
  e.stopPropagation();
  sound.playClick();
  const completed = state.incrementAmount(id, step);
  if (completed) {
    sound.playSuccess();
    confetti.burst();
    showToast('Target reached! Awesome work 🎉');
    pulseDynamicIsland('Target reached! 🎉');
  }
  renderTodayScreen();
}

function onStepReps(e, id, delta) {
  e.stopPropagation();
  sound.playClick();
  const completed = state.stepReps(id, delta);
  if (completed) {
    sound.playSuccess();
    confetti.burst();
    showToast('All repetitions done! 🔥');
    pulseDynamicIsland('Reps finished! 🔥');
  }
  renderTodayScreen();
}

function selectDay(dayNum) {
  state.selectedDay = dayNum;
  sound.playClick();
  renderTodayScreen();
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
    iconEl.innerHTML = getIconSvg(habit.icon, '#FFFFFF', 36);
  }
  if (titleEl) titleEl.textContent = habit.name;
  if (subEl) {
    subEl.textContent = habit.repeatLabel + ' • ' + habit.timeOfDay.toUpperCase() + ' • ' + (habit.strictness === 'strict' ? '⚡ Fatal Strict' : '🛡️ Flexible');
  }
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
      const isDone = habit.history[day] && habit.history[day].done;
      daysHtml += '<div class="cal-cell ' + (isDone ? 'completed' : '') + '">' + day + '</div>';
    }
    calendarEl.innerHTML = daysHtml;
  }
}

function renderSheetView() {
  const presetsView = document.getElementById('sheet-presets-view');
  const customView = document.getElementById('sheet-custom-view');
  const tabPresets = document.getElementById('sheet-tab-presets');
  const tabCustom = document.getElementById('sheet-tab-custom');

  if (state.sheetTab === 'presets') {
    presetsView.style.display = 'block';
    customView.style.display = 'none';
    tabPresets.classList.add('active');
    tabCustom.classList.remove('active');
    renderSheetPresets();
  } else {
    presetsView.style.display = 'none';
    customView.style.display = 'block';
    tabPresets.classList.remove('active');
    tabCustom.classList.add('active');
  }
}

function setSheetTab(tabName) {
  state.sheetTab = tabName;
  sound.playClick();
  renderSheetView();
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

function onTrackingModeChange(mode) {
  state.customTrackingMode = mode;
  sound.playClick();
  document.getElementById('form-amount-group').style.display = mode === 'amount' ? 'block' : 'none';
  document.getElementById('form-reps-group').style.display = mode === 'reps' ? 'block' : 'none';
  document.getElementById('form-timer-group').style.display = mode === 'timer' ? 'block' : 'none';

  document.querySelectorAll('.mode-chip').forEach(c => {
    c.classList.toggle('selected', c.dataset.mode === mode);
  });
}

function onHabitCardClick(e, id) {
  sound.playClick();
  renderHabitDetails(id);
  switchScreen('details');
}

function switchScreen(screenName) {
  state.activeScreen = screenName;
  sound.playClick();
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
  sound.playClick();
  const island = document.getElementById('dynamic-island');
  island.classList.toggle('expanded');
  state.islandExpanded = island.classList.contains('expanded');
}

function triggerActionButton() {
  sound.playHaptic();
  const pending = state.habits.find(h => {
    const s = state.getHabitStatusOnSelectedDay(h);
    return s !== 'completed' && s !== 'fatal_missed';
  });
  if (pending) {
    if (pending.type === 'amount') {
      state.incrementAmount(pending.id, pending.stepAmount);
    } else if (pending.type === 'reps') {
      state.stepReps(pending.id, 1);
    } else {
      state.toggleBinaryHabit(pending.id);
    }
    sound.playSuccess();
    confetti.burst();
    showToast('Quick Logged: ' + pending.name + ' ⚡');
    pulseDynamicIsland('Logged: ' + pending.name);
    renderTodayScreen();
  } else {
    showToast('All habits completed for this date! 🔥');
  }
}

function openAddHabitSheet() {
  sound.playClick();
  renderSheetView();
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
    state.addCustomHabit({
      name: preset.name,
      icon: preset.icon,
      color: preset.color,
      timeOfDay: preset.timeOfDay,
      type: 'binary',
      frequency: 'daily',
      repeatLabel: 'Every day',
      strictness: 'strict'
    });
    closeAddHabitSheet();
    renderTodayScreen();
    showToast('Added: ' + preset.name + ' 🔥');
    confetti.burst();
  }
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

  // Custom Habit Form Submission
  const customForm = document.getElementById('custom-habit-form');
  if (customForm) {
    customForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const name = document.getElementById('custom-name-input').value.trim();
      const type = state.customTrackingMode;
      const targetAmount = document.getElementById('custom-target-amount').value;
      const unit = document.getElementById('custom-unit-select').value;
      const stepAmount = document.getElementById('custom-step-amount').value;
      const targetReps = document.getElementById('custom-reps-count').value;
      const targetDuration = document.getElementById('custom-duration-minutes').value;
      const frequency = document.getElementById('custom-frequency-select').value;
      const freqLabel = document.getElementById('custom-frequency-select').selectedOptions[0].text;
      const strictness = document.getElementById('custom-strictness-select').value;
      const timeOfDay = document.getElementById('custom-time-select').value;
      const color = document.getElementById('custom-color-select').value;
      const icon = document.getElementById('custom-icon-select').value;

      if (!name) return;

      state.addCustomHabit({
        name,
        type,
        targetAmount,
        unit,
        stepAmount,
        targetReps,
        targetDuration,
        frequency,
        repeatLabel: freqLabel,
        strictness,
        timeOfDay,
        color,
        icon
      });

      closeAddHabitSheet();
      renderTodayScreen();
      showToast('Created habit: ' + name + ' 🎉');
      confetti.burst();
    });
  }
});
`;

fs.writeFileSync('app.js', appJsCode, 'utf8');
console.log('Successfully written app.js!');
