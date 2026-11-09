const fs = require('fs');
const appData = JSON.parse(fs.readFileSync('app_data.json', 'utf8'));

console.log('Building Productive 3.0 Native SwiftUI Simulation Engine (app.js)...');

const engineTemplate = `/**
 * PRODUCTIVE 3.0 — NATIVE SWIFTUI SIMULATOR ENGINE (app.js)
 * 1:1 Interactive Browser Counterpart to ios-swiftui/ (All 16 Native & Habit Coach Upgrades)
 */

const APP_DATA = __APP_DATA_JSON__;

const DEFAULT_CHALLENGES = [
  {
    id: 'morning_miracle_21',
    title: '21-Day Morning Miracle',
    subtitle: 'Start every morning with 15m mindful movement & focus',
    durationDays: 21,
    icon: 'ic_sunny',
    emoji: '🌅',
    color: '#FF416C',
    isJoined: false,
    joinedDateKey: null,
    templateHabit: { name: 'Morning Miracle Focus', icon: 'ic_yoga', color: '#FF416C', timeOfDay: 'morning', polarity: 'build', type: 'timer', targetDuration: 15 }
  },
  {
    id: 'hydration_hero_14',
    title: '14-Day Hydration Hero',
    subtitle: 'Drink 2,000 ml of water every day for two weeks',
    durationDays: 14,
    icon: 'ic_drink',
    emoji: '💧',
    color: '#007AFF',
    isJoined: false,
    joinedDateKey: null,
    templateHabit: { name: 'Drink Water (2L)', icon: 'ic_drink', color: '#007AFF', timeOfDay: 'morning', polarity: 'build', type: 'amount', targetAmount: 2000, unit: 'ml', stepAmount: 250 }
  },
  {
    id: 'digital_detox_7',
    title: '7-Day Screen Detox',
    subtitle: 'Stay at or under 30 mins of late-night scrolling',
    durationDays: 7,
    icon: 'ic_phone',
    emoji: '📵',
    color: '#BF5AF2',
    isJoined: false,
    joinedDateKey: null,
    templateHabit: { name: 'Late-Night Social Media', icon: 'ic_phone', color: '#BF5AF2', timeOfDay: 'evening', polarity: 'limit', type: 'amount', targetAmount: 30, unit: 'mins', stepAmount: 10 }
  },
  {
    id: 'sugar_free_14',
    title: '14-Day Zero Sugar Quit',
    subtitle: 'Abstain from refined sweets & sugary drinks',
    durationDays: 14,
    icon: 'ic_cake',
    emoji: '✋',
    color: '#30D158',
    isJoined: false,
    joinedDateKey: null,
    templateHabit: { name: 'Zero Added Sugar', icon: 'ic_fruit', color: '#30D158', timeOfDay: 'anytime', polarity: 'quit', type: 'binary' }
  },
  {
    id: 'fitness_momentum_30',
    title: '30-Day Fitness Momentum',
    subtitle: 'Move your body for 30 minutes daily',
    durationDays: 30,
    icon: 'ic_run',
    emoji: '🏃',
    color: '#FF7450',
    isJoined: false,
    joinedDateKey: null,
    templateHabit: { name: 'Daily Active Workout', icon: 'ic_gym', color: '#FF7450', timeOfDay: 'afternoon', polarity: 'build', type: 'timer', targetDuration: 30 }
  }
];

const MOOD_META = {
  great:   { emoji: '😄', label: 'Energized' },
  good:    { emoji: '🙂', label: 'Smooth' },
  neutral: { emoji: '😐', label: 'Okay' },
  tough:   { emoji: '😓', label: 'Tough' }
};

function getISODateKey(d = new Date()) {
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  return yyyy + '-' + mm + '-' + dd;
}

function parseISODateKey(dateKey) {
  const parts = String(dateKey || '').split('-').map(Number);
  if (parts.length === 3 && !isNaN(parts[0])) {
    return new Date(parts[0], parts[1] - 1, parts[2], 0, 0, 0, 0);
  }
  const now = new Date();
  now.setHours(0, 0, 0, 0);
  return now;
}

function addDaysToKey(dateKey, deltaDays) {
  const d = parseISODateKey(dateKey);
  d.setDate(d.getDate() + deltaDays);
  return getISODateKey(d);
}

function isWeeklyPeriodic(freq) {
  return ['1_per_week', '2_per_week', '3_per_week', '4_per_week', '5_per_week', 'custom_times_per_week'].includes(freq);
}

function isMonthlyPeriodic(freq) {
  return ['1_per_month', '2_per_month', '3_per_month', '4_per_month', 'custom_times_per_month'].includes(freq);
}

function isPeriodicFrequency(freq) {
  return isWeeklyPeriodic(freq) || isMonthlyPeriodic(freq);
}

function getPeriodicTargetCount(habit) {
  switch (habit.frequency) {
    case '1_per_week': return 1;
    case '2_per_week': return 2;
    case '3_per_week': return 3;
    case '4_per_week': return 4;
    case '5_per_week': return 5;
    case 'custom_times_per_week': return Math.max(1, Number(habit.frequencyTargetTimes) || 3);
    case '1_per_month': return 1;
    case '2_per_month': return 2;
    case '3_per_month': return 3;
    case '4_per_month': return 4;
    case 'custom_times_per_month': return Math.max(1, Number(habit.frequencyTargetTimes) || 2);
    default: return 1;
  }
}

function getWeekDateKeys(dateKey) {
  const [y, m, d] = dateKey.split('-').map(Number);
  const date = new Date(y, m - 1, d);
  const day = date.getDay(); // 0 = Sun
  const sun = new Date(date);
  sun.setDate(date.getDate() - day);
  const keys = [];
  for (let i = 0; i < 7; i++) {
    const cur = new Date(sun);
    cur.setDate(sun.getDate() + i);
    keys.push(getISODateKey(cur));
  }
  return keys;
}

function getMonthDateKeys(dateKey) {
  const [y, m] = dateKey.split('-').map(Number);
  const daysInMonth = new Date(y, m, 0).getDate();
  const keys = [];
  for (let i = 1; i <= daysInMonth; i++) {
    const dayStr = String(i).padStart(2, '0');
    const monthStr = String(m).padStart(2, '0');
    keys.push(y + '-' + monthStr + '-' + dayStr);
  }
  return keys;
}

function getRepeatLabel(habit) {
  if (habit.polarity === 'quit') return 'Quit • Stay Clean';
  if (habit.polarity === 'limit') return 'Max ' + habit.targetAmount + ' ' + (habit.unit || 'units');
  switch (habit.frequency) {
    case 'daily': return 'Every day';
    case 'weekdays': return 'Weekdays';
    case 'weekends': return 'Weekends';
    case 'every_2_days': return 'Every 2 days';
    case 'every_3_days': return 'Every 3 days';
    case '1_per_week': return 'Once a week';
    case '2_per_week': return 'Twice a week';
    case '3_per_week': return '3x / week';
    case '4_per_week': return '4x / week';
    case '5_per_week': return '5x / week';
    case 'custom_times_per_week': return getPeriodicTargetCount(habit) + 'x / week';
    case '1_per_month': return 'Once a month';
    case '2_per_month': return 'Twice a month';
    case '3_per_month': return '3x / month';
    case '4_per_month': return '4x / month';
    case 'custom_times_per_month': return getPeriodicTargetCount(habit) + 'x / month';
    case 'custom_days':
      if (!Array.isArray(habit.customWeekdays) || habit.customWeekdays.length === 0 || habit.customWeekdays.length === 7) return 'Every day';
      const map = { 1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 0: 'Sun' };
      const names = [1, 2, 3, 4, 5, 6, 0].filter(d => habit.customWeekdays.includes(d)).map(d => map[d]);
      if (names.length === 5 && !habit.customWeekdays.includes(0) && !habit.customWeekdays.includes(6)) return 'Weekdays';
      if (names.length === 2 && habit.customWeekdays.includes(0) && habit.customWeekdays.includes(6)) return 'Weekends';
      return names.join(', ');
    default: return habit.repeatLabel || 'Every day';
  }
}

class ProductiveState {
  constructor() {
    this.todayKey = getISODateKey();
    this.selectedDay = this.todayKey;
    this.todayDay = this.todayKey;
    this.habits = this.loadHabits();
    this.challenges = this.loadChallenges();

    this.activeScreen = 'today';
    this.selectedHabitId = null;
    this.editingHabitId = null;
    this.activeCategory = 0; // 0 = All
    this.todayFilter = 'due'; // 'due' | 'all' | 'quit_limit'
    this.searchQuery = '';
    this.swipedHabitId = null;

    // Settings
    this.soundEnabled = this.loadSetting('soundEnabled', true);
    this.theme = this.loadSetting('theme', 'dark'); // 'system' | 'dark' | 'light'
    this.finish = this.loadSetting('finish', 'natural');
    this.weekStartDay = this.loadSetting('weekStartDay', 'monday');
    this.defaultStrictness = this.loadSetting('defaultStrictness', 'strict');
    this.hasCompletedOnboarding = this.loadSetting('hasCompletedOnboarding', false);
    this.vacationMode = this.loadSetting('vacationMode', false);
    this.streakFreezeShields = this.loadSetting('streakFreezeShields', 2);
    this.healthSyncEnabled = this.loadSetting('healthSyncEnabled', false);

    // Builder Sheet State
    this.sheetTab = 'presets';
    this.customPolarity = 'build';
    this.customTrackingMode = 'binary';
    this.customWeekdays = [1, 2, 3, 4, 5]; // JS getDay(): 0=Sun..6=Sat
    this.builderSubtasks = [];

    // Live Focus Timer Engine
    this.activeTimerHabitId = null;
    this.timerMode = 'countdown'; // 'countdown' | 'pomodoro' | 'stopwatch'
    this.timerTotalSeconds = 900;
    this.timerRemainingSeconds = 900;
    this.timerElapsedSeconds = 0;
    this.isTimerRunning = false;
    this.timerInterval = null;
    this.openModalType = null;

    // Routine Player State
    this.routineBucket = null;
    this.routineStepIndex = 0;

    // Push Banner Target
    this.pushHabitId = null;

    this.recalculateAllStreaks();
  }

  loadSetting(key, defaultValue) {
    try {
      const stored = localStorage.getItem('productive_settings');
      if (stored) {
        const parsed = JSON.parse(stored);
        if (parsed[key] !== undefined) return parsed[key];
      }
    } catch (e) {}
    return defaultValue;
  }

  saveSettings() {
    try {
      const settings = {
        theme: this.theme,
        finish: this.finish,
        weekStartDay: this.weekStartDay,
        defaultStrictness: this.defaultStrictness,
        soundEnabled: this.soundEnabled,
        hasCompletedOnboarding: this.hasCompletedOnboarding,
        vacationMode: this.vacationMode,
        streakFreezeShields: this.streakFreezeShields,
        healthSyncEnabled: this.healthSyncEnabled
      };
      localStorage.setItem('productive_settings', JSON.stringify(settings));
    } catch (e) {}
  }

  loadHabits() {
    try {
      const stored = localStorage.getItem('productive_habits_user_v1');
      if (stored) {
        const parsed = JSON.parse(stored);
        if (Array.isArray(parsed)) return parsed.map(h => this.normalizeHabit(h));
      }
    } catch (e) {}
    return [];
  }

  normalizeHabit(h) {
    return Object.assign({
      polarity: 'build',
      type: 'binary',
      targetAmount: 2000,
      currentAmount: 0,
      unit: 'ml',
      stepAmount: 250,
      targetReps: 3,
      currentReps: 0,
      targetDuration: 15,
      frequency: 'daily',
      customWeekdays: [1, 2, 3, 4, 5],
      repeatLabel: 'Every day',
      strictness: 'strict',
      subtasks: [],
      reminderTime: '09:00',
      isArchived: false,
      createdAtKey: this.todayKey || getISODateKey(),
      abstainedSinceKey: this.todayKey || getISODateKey(),
      streak: 0,
      bestStreak: 0,
      totalLogs: 0,
      history: {}
    }, h);
  }

  saveHabits() {
    try {
      localStorage.setItem('productive_habits_user_v1', JSON.stringify(this.habits));
      localStorage.setItem('productive_challenges_v1', JSON.stringify(this.challenges));
    } catch (e) {}
  }

  loadChallenges() {
    try {
      const stored = localStorage.getItem('productive_challenges_v1');
      if (stored) {
        const parsed = JSON.parse(stored);
        if (Array.isArray(parsed) && parsed.length > 0) return parsed;
      }
    } catch (e) {}
    return JSON.parse(JSON.stringify(DEFAULT_CHALLENGES));
  }

  isDayToday(dateKey = this.selectedDay) {
    return dateKey === this.todayKey;
  }

  isDayPast(dateKey = this.selectedDay) {
    return dateKey < this.todayKey;
  }

  get activeHabits() {
    return this.habits.filter(h => !h.isArchived);
  }

  get archivedHabits() {
    return this.habits.filter(h => h.isArchived);
  }

  getPeriodicCompletedCount(habit, dateKey = this.selectedDay) {
    if (!isPeriodicFrequency(habit.frequency)) {
      return (habit.history && habit.history[dateKey] && habit.history[dateKey].done) ? 1 : 0;
    }
    const isWk = isWeeklyPeriodic(habit.frequency);
    const keys = isWk ? getWeekDateKeys(dateKey) : getMonthDateKeys(dateKey);
    let count = 0;
    const history = habit.history || {};
    keys.forEach(k => {
      if (history[k] && history[k].done) count++;
    });
    return count;
  }

  isPeriodicAccomplished(habit, dateKey = this.selectedDay) {
    if (!isPeriodicFrequency(habit.frequency)) return false;
    const target = getPeriodicTargetCount(habit);
    const done = this.getPeriodicCompletedCount(habit, dateKey);
    return done >= target;
  }

  isHabitDueOnDate(habit, dateKey = this.selectedDay) {
    if (habit.isArchived) return false;

    // Never due on days prior to the habit's chosen start / creation date
    const createdKey = habit.createdAtKey || habit.startDateKey || this.todayKey;
    if (createdKey && dateKey < createdKey) {
      return false;
    }

    // Flexible Periodic frequency (weekly / monthly spread)
    if (isPeriodicFrequency(habit.frequency)) {
      const rec = habit.history && habit.history[dateKey];
      if (rec && (rec.done || rec.skipped || rec.usedShield)) {
        return true;
      }
      if (this.isPeriodicAccomplished(habit, dateKey)) {
        return false;
      }
      return true;
    }

    const d = parseISODateKey(dateKey);
    const dayOfWeek = d.getDay(); // 0=Sun, 1=Mon ... 6=Sat
    switch (habit.frequency) {
      case 'daily': return true;
      case 'weekdays': return dayOfWeek >= 1 && dayOfWeek <= 5;
      case 'weekends': return dayOfWeek === 0 || dayOfWeek === 6;
      case 'custom_days':
        return Array.isArray(habit.customWeekdays) && habit.customWeekdays.length > 0
          ? habit.customWeekdays.includes(dayOfWeek)
          : true;
      case 'every_2_days': {
        const anchor = parseISODateKey(habit.createdAtKey || this.todayKey);
        const diff = Math.round(Math.abs(d - anchor) / 86400000);
        return diff % 2 === 0;
      }
      case 'every_3_days': {
        const anchor = parseISODateKey(habit.createdAtKey || this.todayKey);
        const diff = Math.round(Math.abs(d - anchor) / 86400000);
        return diff % 3 === 0;
      }
      default: return true;
    }
  }

  effectiveTargetAmount(habit, dateKey = this.selectedDay) {
    const base = Number(habit.targetAmount) || 2000;
    if (habit.polarity !== 'build' || habit.type !== 'amount' || habit.strictness !== 'rollover') {
      return base;
    }
    const prevKey = addDaysToKey(dateKey, -1);
    if (!this.isHabitDueOnDate(habit, prevKey)) return base;
    const prevRec = habit.history[prevKey];
    if (prevRec && (prevRec.skipped || prevRec.usedShield)) return base;
    const prevAmt = (prevRec && prevRec.amount !== undefined) ? Number(prevRec.amount) : 0;
    if (prevAmt < base && prevKey < dateKey && habit.createdAtKey <= prevKey) {
      const carry = Math.min(base, base - prevAmt);
      return base + carry;
    }
    return base;
  }

  rolloverBonus(habit, dateKey = this.selectedDay) {
    return Math.max(0, this.effectiveTargetAmount(habit, dateKey) - (Number(habit.targetAmount) || 0));
  }

  getHabitStatusOnSelectedDay(habit, dateKey = this.selectedDay) {
    const dayData = habit.history && habit.history[dateKey];
    if (dayData && (dayData.skipped || dayData.usedShield)) return 'skipped';
    if (dayData && dayData.done) return 'completed';
    if (this.isDayPast(dateKey) && !this.vacationMode) {
      if (habit.strictness === 'strict' && this.isHabitDueOnDate(habit, dateKey)) {
        return 'fatal_missed';
      }
      return 'uncompleted_flexible';
    }
    return 'pending';
  }

  recalculateAllStreaks() {
    this.habits.forEach(h => this.recalculateHabitStats(h, false));
  }

  recalculateHabitStats(habit, awardShieldOnMilestone = true) {
    const history = habit.history || {};
    let totalLogs = 0;
    Object.values(history).forEach(r => {
      if (r && r.done) totalLogs++;
    });
    habit.totalLogs = totalLogs;

    let curStreak = 0;
    if (isWeeklyPeriodic(habit.frequency)) {
      const target = getPeriodicTargetCount(habit);
      for (let w = 0; w < 52; w++) {
        const checkKey = addDaysToKey(this.todayKey, -w * 7);
        const doneInWk = this.getPeriodicCompletedCount(habit, checkKey);
        if (doneInWk >= target) {
          curStreak++;
        } else if (w === 0) {
          continue;
        } else {
          break;
        }
      }
    } else if (isMonthlyPeriodic(habit.frequency)) {
      const target = getPeriodicTargetCount(habit);
      const [ty, tm] = this.todayKey.split('-').map(Number);
      for (let m = 0; m < 24; m++) {
        const monthDate = new Date(ty, tm - 1 - m, 15);
        const checkKey = getISODateKey(monthDate);
        const doneInMo = this.getPeriodicCompletedCount(habit, checkKey);
        if (doneInMo >= target) {
          curStreak++;
        } else if (m === 0) {
          continue;
        } else {
          break;
        }
      }
    } else {
      for (let offset = 0; offset < 365; offset++) {
        const key = addDaysToKey(this.todayKey, -offset);
        const rec = history[key];
        if (rec && rec.done) {
          curStreak++;
          continue;
        }
        if ((rec && (rec.skipped || rec.usedShield)) || this.vacationMode) {
          continue;
        }
        if (offset === 0) {
          continue;
        }
        if (!this.isHabitDueOnDate(habit, key)) {
          continue;
        }
        break;
      }
    }

    const prevStreak = habit.streak || 0;
    habit.streak = curStreak;
    if (curStreak > (habit.bestStreak || 0)) {
      habit.bestStreak = curStreak;
    }
    if (awardShieldOnMilestone && curStreak > prevStreak && curStreak > 0 && curStreak % 7 === 0) {
      this.streakFreezeShields += 1;
      this.saveSettings();
    }
  }

  ensureDayRecord(habit, dateKey = this.selectedDay) {
    if (!habit.history) habit.history = {};
    if (!habit.history[dateKey]) {
      habit.history[dateKey] = {
        done: false,
        amount: 0,
        reps: 0,
        durationSeconds: 0,
        skipped: false,
        usedShield: false,
        slips: 0,
        note: '',
        mood: null,
        completedSubtasks: []
      };
    }
    return habit.history[dateKey];
  }

  toggleBinaryHabit(id, dateKey = this.selectedDay) {
    const habit = this.habits.find(h => h.id === id);
    if (!habit) return false;
    if (this.getHabitStatusOnSelectedDay(habit, dateKey) === 'fatal_missed') return false;

    const rec = this.ensureDayRecord(habit, dateKey);
    rec.done = !rec.done;
    rec.skipped = false;

    if (rec.done) {
      if (habit.polarity === 'build' && habit.type === 'amount') {
        const tgt = this.effectiveTargetAmount(habit, dateKey);
        if ((rec.amount || 0) < tgt) rec.amount = tgt;
      } else if (habit.type === 'reps') {
        if ((rec.reps || 0) < habit.targetReps) rec.reps = habit.targetReps;
      }
      if (Array.isArray(habit.subtasks) && habit.subtasks.length > 0) {
        rec.completedSubtasks = habit.subtasks.map(s => s.id);
      }
    } else {
      rec.completedSubtasks = [];
      if (habit.polarity === 'build' && habit.type === 'amount') {
        rec.amount = 0;
      } else if (habit.type === 'reps') {
        rec.reps = 0;
      }
    }

    this.recalculateHabitStats(habit);
    this.saveHabits();
    return rec.done;
  }

  incrementAmount(id, step, dateKey = this.selectedDay) {
    const habit = this.habits.find(h => h.id === id);
    if (!habit) return false;
    if (this.getHabitStatusOnSelectedDay(habit, dateKey) === 'fatal_missed') return false;

    const rec = this.ensureDayRecord(habit, dateKey);
    const effTarget = this.effectiveTargetAmount(habit, dateKey);
    const cur = Number(rec.amount) || 0;
    const nextAmt = Math.max(0, Math.min(effTarget * 3, cur + Number(step)));
    rec.amount = nextAmt;
    if (this.isDayToday(dateKey)) habit.currentAmount = nextAmt;

    if (habit.polarity === 'limit') {
      rec.done = nextAmt <= habit.targetAmount;
    } else {
      rec.done = nextAmt >= effTarget;
    }

    this.recalculateHabitStats(habit);
    this.saveHabits();
    return rec.done;
  }

  stepReps(id, delta, dateKey = this.selectedDay) {
    const habit = this.habits.find(h => h.id === id);
    if (!habit) return false;
    if (this.getHabitStatusOnSelectedDay(habit, dateKey) === 'fatal_missed') return false;

    const rec = this.ensureDayRecord(habit, dateKey);
    const cur = Number(rec.reps) || 0;
    const nextReps = Math.max(0, Math.min(habit.targetReps * 2, cur + delta));
    rec.reps = nextReps;
    if (this.isDayToday(dateKey)) habit.currentReps = nextReps;
    rec.done = nextReps >= habit.targetReps;

    this.recalculateHabitStats(habit);
    this.saveHabits();
    return rec.done;
  }

  toggleSubtask(habitId, subtaskId, dateKey = this.selectedDay) {
    const habit = this.habits.find(h => h.id === habitId);
    if (!habit) return false;
    const rec = this.ensureDayRecord(habit, dateKey);
    if (!Array.isArray(rec.completedSubtasks)) rec.completedSubtasks = [];
    const idx = rec.completedSubtasks.indexOf(subtaskId);
    if (idx >= 0) rec.completedSubtasks.splice(idx, 1);
    else rec.completedSubtasks.push(subtaskId);

    if (Array.isArray(habit.subtasks) && habit.subtasks.length > 0) {
      rec.done = habit.subtasks.every(st => rec.completedSubtasks.includes(st.id));
    }
    this.recalculateHabitStats(habit);
    this.saveHabits();
    return rec.done;
  }

  logQuitSlip(id, dateKey = this.selectedDay) {
    const habit = this.habits.find(h => h.id === id);
    if (!habit) return;
    const rec = this.ensureDayRecord(habit, dateKey);
    rec.slips = (rec.slips || 0) + 1;
    rec.done = false;
    rec.mood = 'tough';
    habit.abstainedSinceKey = dateKey;
    habit.streak = 0;
    this.saveHabits();
  }

  toggleSkipHabit(id, dateKey = this.selectedDay) {
    const habit = this.habits.find(h => h.id === id);
    if (!habit) return;
    const rec = this.ensureDayRecord(habit, dateKey);
    rec.skipped = !rec.skipped;
    if (rec.skipped) rec.done = false;
    this.recalculateHabitStats(habit, false);
    this.saveHabits();
  }

  useFreezeShield(id, dateKey = this.selectedDay) {
    if (this.streakFreezeShields <= 0) return false;
    const habit = this.habits.find(h => h.id === id);
    if (!habit) return false;
    const rec = this.ensureDayRecord(habit, dateKey);
    if (rec.usedShield) return false;
    rec.usedShield = true;
    this.streakFreezeShields -= 1;
    this.recalculateHabitStats(habit, false);
    this.saveSettings();
    this.saveHabits();
    return true;
  }

  saveJournalEntry(id, dateKey, note, mood) {
    const habit = this.habits.find(h => h.id === id);
    if (!habit) return;
    const rec = this.ensureDayRecord(habit, dateKey);
    rec.note = note || '';
    rec.mood = mood || null;
    this.saveHabits();
  }

  addCustomHabit(data) {
    const newId = Date.now() + Math.floor(Math.random() * 1000);
    const polarity = data.polarity || 'build';
    const type = polarity === 'limit' ? 'amount' : (polarity === 'quit' ? 'binary' : (data.type || 'binary'));
    const habit = this.normalizeHabit({
      id: newId,
      name: data.name,
      icon: data.icon || 'ic_all_habits',
      color: data.color || '#007AFF',
      timeOfDay: data.timeOfDay || 'morning',
      polarity,
      type,
      targetAmount: Number(data.targetAmount) || 2000,
      currentAmount: 0,
      unit: data.unit || 'ml',
      stepAmount: Number(data.stepAmount) || 250,
      targetReps: Number(data.targetReps) || 3,
      currentReps: 0,
      targetDuration: Number(data.targetDuration) || 15,
      frequency: data.frequency || 'daily',
      customWeekdays: Array.isArray(data.customWeekdays) ? data.customWeekdays.slice() : [1, 2, 3, 4, 5],
      repeatLabel: data.repeatLabel || 'Every day',
      strictness: data.strictness || this.defaultStrictness || 'strict',
      subtasks: Array.isArray(data.subtasks) ? data.subtasks.slice() : [],
      reminderTime: data.reminderTime || '09:00',
      createdAtKey: data.createdAtKey || this.selectedDay || this.todayKey,
      abstainedSinceKey: data.abstainedSinceKey || this.selectedDay || this.todayKey,
      history: data.history || {}
    });

    if (polarity === 'limit' && !habit.history[this.todayKey]) {
      habit.history[this.todayKey] = { done: true, amount: 0, completedSubtasks: [] };
    }
    this.habits.unshift(habit);
    this.recalculateHabitStats(habit, false);
    this.saveHabits();
    return habit;
  }

  updateHabit(id, updates) {
    const idx = this.habits.findIndex(h => h.id === id);
    if (idx < 0) return null;
    const polarity = updates.polarity || this.habits[idx].polarity || 'build';
    const type = polarity === 'limit' ? 'amount' : (polarity === 'quit' ? 'binary' : (updates.type || this.habits[idx].type));
    this.habits[idx] = Object.assign({}, this.habits[idx], updates, { polarity, type });
    this.recalculateHabitStats(this.habits[idx], false);
    this.saveHabits();
    return this.habits[idx];
  }

  duplicateHabit(id) {
    const src = this.habits.find(h => h.id === id);
    if (!src) return null;
    return this.addCustomHabit(Object.assign({}, src, {
      name: src.name + ' (Copy)',
      history: {}
    }));
  }

  toggleArchiveHabit(id) {
    const h = this.habits.find(x => x.id === id);
    if (!h) return;
    h.isArchived = !h.isArchived;
    this.saveHabits();
  }

  deleteHabit(id) {
    if (this.activeTimerHabitId === id) stopFocusTimer();
    this.habits = this.habits.filter(h => h.id !== id);
    this.saveHabits();
  }

  moveHabitOrder(id, direction) {
    const idx = this.habits.findIndex(h => h.id === id);
    if (idx < 0) return;
    const bucket = this.habits[idx].timeOfDay;
    const sameBucketIndices = this.habits
      .map((h, i) => (!h.isArchived && h.timeOfDay === bucket) ? i : -1)
      .filter(i => i >= 0);
    const pos = sameBucketIndices.indexOf(idx);
    const swapPos = pos + direction;
    if (swapPos < 0 || swapPos >= sameBucketIndices.length) return;
    const targetIdx = sameBucketIndices[swapPos];
    const tmp = this.habits[idx];
    this.habits[idx] = this.habits[targetIdx];
    this.habits[targetIdx] = tmp;
    this.saveHabits();
  }

  getHabitProgressFraction(habit, dateKey = this.selectedDay) {
    const rec = habit.history && habit.history[dateKey];
    if (rec && (rec.done || rec.skipped || rec.usedShield)) return 1.0;

    // Sub-checklist fractional progress: divide by items count so percentage is based on number done
    if (Array.isArray(habit.subtasks) && habit.subtasks.length > 0) {
      const doneSubs = (rec && Array.isArray(rec.completedSubtasks)) ? rec.completedSubtasks.length : 0;
      return Math.min(1.0, Math.max(0.0, doneSubs / habit.subtasks.length));
    }

    // Amount fractional progress
    if (habit.type === 'amount' && habit.polarity !== 'quit' && habit.polarity !== 'limit') {
      const effTarget = this.effectiveTargetAmount(habit, dateKey);
      if (effTarget > 0 && rec && rec.amount) {
        return Math.min(1.0, Math.max(0.0, Number(rec.amount) / effTarget));
      }
    }
    return 0.0;
  }

  getCompletionRate(dateKey = this.selectedDay) {
    const due = this.activeHabits.filter(h => this.isHabitDueOnDate(h, dateKey));
    if (due.length === 0) return 0;
    let totalScore = 0;
    due.forEach(h => {
      totalScore += this.getHabitProgressFraction(h, dateKey);
    });
    return Math.round((totalScore / due.length) * 100);
  }

  getRemainingTodayCount() {
    const due = this.activeHabits.filter(h => this.isHabitDueOnDate(h, this.todayKey));
    return due.filter(h => {
      const rec = h.history && h.history[this.todayKey];
      return !(rec && (rec.done || rec.skipped || rec.usedShield));
    }).length;
  }

  joinChallenge(challengeId) {
    const ch = this.challenges.find(c => c.id === challengeId);
    if (!ch || ch.isJoined) return;
    let linked = this.habits.find(h => h.name.toLowerCase() === ch.templateHabit.name.toLowerCase());
    if (!linked) {
      linked = this.addCustomHabit(ch.templateHabit);
    }
    ch.isJoined = true;
    ch.joinedDateKey = this.todayKey;
    ch.linkedHabitId = linked.id;
    this.saveHabits();
  }

  leaveChallenge(challengeId) {
    const ch = this.challenges.find(c => c.id === challengeId);
    if (!ch) return;
    ch.isJoined = false;
    ch.joinedDateKey = null;
    this.saveHabits();
  }

  getChallengeProgress(ch) {
    if (!ch.isJoined) return 0;
    const linked = this.habits.find(h => h.id === ch.linkedHabitId);
    if (!linked || !linked.history) return 0;
    const startKey = ch.joinedDateKey || '0000-00-00';
    let days = 0;
    Object.keys(linked.history).forEach(k => {
      if (k >= startKey && linked.history[k] && linked.history[k].done) days++;
    });
    return Math.min(ch.durationDays, days);
  }

  getAchievementBadges() {
    const maxBest = this.habits.reduce((m, h) => Math.max(m, h.bestStreak || 0), 0);
    const totalLogs = this.habits.reduce((s, h) => s + (h.totalLogs || 0), 0);
    let notesCount = 0;
    this.habits.forEach(h => {
      Object.values(h.history || {}).forEach(r => {
        if (r && ((r.note && r.note.trim()) || r.mood)) notesCount++;
      });
    });
    const joinedAny = this.challenges.some(c => c.isJoined);

    return [
      { id: 'first', title: 'First Spark', sub: 'Create first habit', emoji: '✨', color: '#007AFF', unlocked: this.habits.length > 0 },
      { id: 's7', title: '7-Day Flame', sub: '7d streak milestone', emoji: '🔥', color: '#FF7450', unlocked: maxBest >= 7 },
      { id: 's21', title: '21-Day Builder', sub: '21d habit streak', emoji: '⚡', color: '#BF5AF2', unlocked: maxBest >= 21 },
      { id: 's30', title: 'Titanium 30', sub: '30d streak master', emoji: '👑', color: '#FF9F0A', unlocked: maxBest >= 30 },
      { id: 'l25', title: 'Momentum 25', sub: '25 check-ins logged', emoji: '✅', color: '#30D158', unlocked: totalLogs >= 25 },
      { id: 'l100', title: 'Centurion 100', sub: '100 total check-ins', emoji: '🏅', color: '#FF416C', unlocked: totalLogs >= 100 },
      { id: 'scribe', title: 'Reflective', sub: 'Log 3 mood/notes', emoji: '📖', color: '#32ADE6', unlocked: notesCount >= 3 },
      { id: 'champ', title: 'Challenger', sub: 'Join a program', emoji: '🏆', color: '#F63566', unlocked: joinedAny }
    ];
  }
}

const state = new ProductiveState();

// ============================================================================
// AUDIO / HAPTIC SYNTHESIZER & CONFETTI ENGINE
// ============================================================================

class SoundFX {
  constructor() { this.ctx = null; }
  init() {
    if (!this.ctx && typeof window !== 'undefined') {
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
    osc.frequency.setValueAtTime(820, this.ctx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(320, this.ctx.currentTime + 0.035);
    gain.gain.setValueAtTime(0.1, this.ctx.currentTime);
    gain.gain.linearRampToValueAtTime(0.01, this.ctx.currentTime + 0.035);
    osc.connect(gain);
    gain.connect(this.ctx.destination);
    osc.start();
    osc.stop(this.ctx.currentTime + 0.04);
  }
  playSuccess() {
    if (!state.soundEnabled) return;
    this.init();
    if (!this.ctx) return;
    [523.25, 659.25, 783.99, 1046.5].forEach((freq, idx) => {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.value = freq;
      const t = this.ctx.currentTime + idx * 0.065;
      gain.gain.setValueAtTime(0, t);
      gain.gain.linearRampToValueAtTime(0.16, t + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.001, t + 0.32);
      osc.connect(gain);
      gain.connect(this.ctx.destination);
      osc.start(t);
      osc.stop(t + 0.34);
    });
  }
  playHaptic() {
    if (!state.soundEnabled) return;
    this.init();
    if (!this.ctx) return;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(95, this.ctx.currentTime);
    gain.gain.setValueAtTime(0.25, this.ctx.currentTime);
    gain.gain.linearRampToValueAtTime(0.01, this.ctx.currentTime + 0.055);
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
    this.ctx = canvas && canvas.getContext ? canvas.getContext('2d') : null;
    this.particles = [];
    this.animationId = null;
    this.resize();
    if (typeof window !== 'undefined' && window.addEventListener) {
      window.addEventListener('resize', () => this.resize());
    }
  }
  resize() {
    if (!this.canvas || !this.canvas.parentElement) return;
    this.canvas.width = this.canvas.parentElement.clientWidth;
    this.canvas.height = this.canvas.parentElement.clientHeight;
  }
  burst(x, y) {
    if (!this.ctx || !this.canvas) return;
    const colors = ['#007AFF', '#5856D6', '#30D158', '#FF9F0A', '#FF2D55', '#32ADE6'];
    for (let i = 0; i < 36; i++) {
      const angle = Math.random() * Math.PI * 2;
      const speed = 3 + Math.random() * 6.5;
      this.particles.push({
        x: x || this.canvas.width / 2,
        y: y || this.canvas.height / 2,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed - 2,
        color: colors[Math.floor(Math.random() * colors.length)],
        radius: 3 + Math.random() * 3.5,
        rotation: Math.random() * 360,
        vr: (Math.random() - 0.5) * 12,
        life: 1,
        decay: 0.022 + Math.random() * 0.02
      });
    }
    if (!this.animationId) this.loop();
  }
  loop() {
    if (!this.ctx) return;
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

let confetti = { burst: () => {} };

const ICONS_MAP = {
  ic_drink: '<path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z" fill="COLOR"/>',
  ic_yoga: '<circle cx="12" cy="4" r="2" fill="COLOR"/><path d="M12 7c-2 0-3.5 1.5-3.5 3.5 0 1.2.6 2.3 1.5 2.9L7 17.5l1.5 1.5 3-4h1l3 4 1.5-1.5-3-4.1c.9-.6 1.5-1.7 1.5-2.9C15.5 8.5 14 7 12 7z" fill="COLOR"/>',
  ic_pills: '<path d="M10.5 20.5l10-10a4.95 4.95 0 1 0-7-7l-10 10a4.95 4.95 0 1 0 7 7zm-5.6-8.4l5-5 2.1 2.1-5 5-2.1-2.1z" fill="COLOR"/>',
  ic_walking: '<circle cx="13.5" cy="4" r="2" fill="COLOR"/><path d="M9 20l3-6 1.5 3 2.5 5h2l-3.5-7-1.5-3 2-2a2 2 0 0 0-.5-2.8L12 5.5A2 2 0 0 0 10 6L6.5 8 7.5 10l2.5-1.5 1 2-4 8h2z" fill="COLOR"/>',
  ic_fruit: '<path d="M12 2c-.5 2.5-2 4-4 4 0 0 2-3 4-4zm6 9c0-3.3-2.7-6-6-6s-6 2.7-6 6c0 4.5 3.5 9 6 9s6-4.5 6-9z" fill="COLOR"/>',
  ic_read: '<path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20v-14H6.5A2.5 2.5 0 0 0 4 5.5v14zm0 0A2.5 2.5 0 0 0 6.5 22H20v-3H6.5A2.5 2.5 0 0 1 4 19.5z" fill="COLOR"/>',
  ic_book: '<path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20v-14H6.5A2.5 2.5 0 0 0 4 5.5v14zm0 0A2.5 2.5 0 0 0 6.5 22H20v-3H6.5A2.5 2.5 0 0 1 4 19.5z" fill="COLOR"/>',
  ic_spa: '<path d="M12 3c-1.5 3-4 6-7 7 3 1 5.5 4 7 7 1.5-3 4-6 7-7-3-1-5.5-4-7-7z" fill="COLOR"/>',
  ic_gym: '<path d="M6 5v14M18 5v14M2 9v6M22 9v6M6 12h12M4 7v10M20 7v10" stroke="COLOR" stroke-width="2.3" stroke-linecap="round" fill="none"/>',
  ic_run: '<circle cx="13.5" cy="4" r="2" fill="COLOR"/><path d="M9.8 8.9L7.2 21.8c-.1.6.4 1.2 1 1.2h.1c.5 0 .9-.3 1-.8l1.6-7.2 2.1 2v5c0 .6.4 1 1 1s1-.4 1-1v-5.6c0-.6-.2-1.1-.6-1.5l-1.5-1.4.6-3c1.1 1.2 2.6 2.1 4.4 2.4.6.1 1.1-.4 1.1-1 0-.5-.4-.9-.9-1-1.5-.2-2.8-1.2-3.5-2.3l-1-1.6c-.6-.9-1.7-1.3-2.7-.8L7.2 7.8c-.7.3-1.2 1.1-1.2 1.9V12c0 .6.5 1 1 1s1-.4 1-1V9.6l1.8-.7" fill="COLOR"/>',
  ic_sleep: '<path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" fill="COLOR"/>',
  ic_sunny: '<circle cx="12" cy="12" r="5" fill="COLOR"/><path d="M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42" stroke="COLOR" stroke-width="2" stroke-linecap="round"/>',
  ic_money: '<circle cx="12" cy="12" r="9" stroke="COLOR" stroke-width="2" fill="none"/><path d="M12 6v12M15 9.5a2.5 2.5 0 0 0-5 0c0 3 5 2 5 5a2.5 2.5 0 0 1-5 0" stroke="COLOR" stroke-width="2" stroke-linecap="round"/>',
  ic_phone: '<rect x="5" y="2" width="14" height="20" rx="3" stroke="COLOR" stroke-width="2" fill="none"/><line x1="12" y1="18" x2="12.01" y2="18" stroke="COLOR" stroke-width="2.5" stroke-linecap="round"/>',
  ic_home: '<path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" stroke="COLOR" stroke-width="2" fill="none"/><polyline points="9 22 9 12 15 12 15 22" stroke="COLOR" stroke-width="2" fill="none"/>',
  ic_all_habits: '<rect x="3" y="3" width="7" height="7" rx="2" fill="COLOR"/><rect x="14" y="3" width="7" height="7" rx="2" fill="COLOR"/><rect x="14" y="14" width="7" height="7" rx="2" fill="COLOR"/><rect x="3" y="14" width="7" height="7" rx="2" fill="COLOR"/>'
};

function escapeHtml(s) {
  return String(s || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function getIconSvg(iconName, color = '#FFFFFF', size = 20) {
  if (ICONS_MAP[iconName]) {
    return '<svg width="' + size + '" height="' + size + '" viewBox="0 0 24 24">' + ICONS_MAP[iconName].replace(/COLOR/g, color) + '</svg>';
  }
  const paths = (APP_DATA.iconPaths && (APP_DATA.iconPaths[iconName] || APP_DATA.iconPaths[iconName + '___'])) || [];
  const validPaths = paths.filter(p => !p.includes('24,24') && !p.includes('24v24') && !p.includes('24V0z'));
  if (validPaths.length > 0) {
    return '<svg width="' + size + '" height="' + size + '" viewBox="0 0 24 24">' + validPaths.map(d => '<path d="' + d + '" fill="' + color + '"/>').join('') + '</svg>';
  }
  return '<svg width="' + size + '" height="' + size + '" viewBox="0 0 24 24" fill="' + color + '"><circle cx="12" cy="12" r="8"/></svg>';
}

// ============================================================================
// APPEARANCE: SYSTEM / DARK / LIGHT
// ============================================================================

function resolveEffectiveTheme(pref = state.theme) {
  if (pref === 'light') return 'light';
  if (pref === 'dark') return 'dark';
  if (typeof window !== 'undefined' && window.matchMedia && window.matchMedia('(prefers-color-scheme: light)').matches) {
    return 'light';
  }
  return 'dark';
}

function applyThemeToDOM() {
  const effective = resolveEffectiveTheme(state.theme);
  if (document.documentElement && document.documentElement.dataset) {
    document.documentElement.dataset.appTheme = effective;
  }
  const btn = document.getElementById('tool-theme-btn');
  if (btn) {
    btn.innerHTML = state.theme === 'system' ? '⚙️ System' : (state.theme === 'light' ? '☀️ Light' : '🌙 Dark');
  }
}

function setAppTheme(theme) {
  state.theme = theme;
  state.saveSettings();
  applyThemeToDOM();
  sound.playClick();
  renderSettingsScreen();
  showToast('Appearance: ' + theme.toUpperCase());
}

function cycleAppTheme() {
  const order = ['system', 'dark', 'light'];
  const next = order[(order.indexOf(state.theme) + 1) % order.length];
  setAppTheme(next);
}

function toggleTheme() {
  cycleAppTheme();
}

// ============================================================================
// TIMELINE RIBBON & TODAY SCREEN
// ============================================================================

function getTimelineDays() {
  const now = new Date();
  const dayLetters = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const fullDays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const days = [];
  for (let offset = -21; offset <= 14; offset++) {
    const d = new Date(now);
    d.setDate(now.getDate() + offset);
    d.setHours(0, 0, 0, 0);
    const dateKey = getISODateKey(d);
    days.push({
      offset,
      name: dayLetters[d.getDay()],
      day: d.getDate(),
      dateKey,
      fullDateName: fullDays[d.getDay()] + ', ' + months[d.getMonth()] + ' ' + d.getDate(),
      isToday: offset === 0,
      isPast: offset < 0,
      isFuture: offset > 0
    });
  }
  return days;
}

function getTodayLeadingScrollTarget(container) {
  if (!container || !container.querySelector) return 0;
  const todayEl = container.querySelector('.day-pill.today');
  if (!todayEl) return 0;
  return Math.max(0, todayEl.offsetLeft - 9);
}

function syncReturnTodayPillVisibility() {
  const pill = document.getElementById('return-today-pill');
  if (!pill || !pill.style) return;
  const container = document.getElementById('week-ribbon-container');
  let scrolledFromToday = false;
  if (container && container.dataset && container.dataset.initializedScroll === 'true') {
    const target = getTodayLeadingScrollTarget(container);
    scrolledFromToday = Math.abs((container.scrollLeft || 0) - target) > 24;
  }
  pill.style.display = (!state.isDayToday() || scrolledFromToday) ? 'inline-flex' : 'none';
}

function scrollRibbonToToday(smooth = true, withRefocusWave = false) {
  const container = document.getElementById('week-ribbon-container');
  if (!container || !container.querySelector) return;
  const todayEl = container.querySelector('.day-pill.today');
  if (todayEl) {
    const targetScroll = getTodayLeadingScrollTarget(container);
    if (container.scrollTo) {
      container.scrollTo({ left: targetScroll, behavior: smooth ? 'smooth' : 'auto' });
    } else {
      container.scrollLeft = targetScroll;
    }
    if (withRefocusWave && container.querySelectorAll) {
      const pills = Array.from(container.querySelectorAll('.day-pill'));
      const todayIdx = pills.indexOf(todayEl);
      pills.forEach((p, idx) => {
        p.classList.remove('refocus-leader', 'refocus-upcoming');
        p.style.animationDelay = '';
        if (idx === todayIdx) {
          void p.offsetWidth;
          p.classList.add('refocus-leader');
        } else if (todayIdx >= 0 && idx > todayIdx && idx <= todayIdx + 6) {
          void p.offsetWidth;
          p.style.animationDelay = ((idx - todayIdx) * 24) + 'ms';
          p.classList.add('refocus-upcoming');
        }
      });
    }
  }
  setTimeout(syncReturnTodayPillVisibility, smooth ? 420 : 20);
}

function renderWeekRibbon(autoScrollToToday = false) {
  const container = document.getElementById('week-ribbon-container');
  if (!container) return;
  const wasInitialized = Boolean(container.dataset && container.dataset.initializedScroll === 'true');
  const prevScroll = container.scrollLeft || 0;
  const days = getTimelineDays();
  let html = '';
  days.forEach(d => {
    const isActive = d.dateKey === state.selectedDay;
    const rate = state.getCompletionRate(d.dateKey);
    const dotColor = rate === 100 ? '#30D158' : (rate > 0 ? '#FF9F0A' : 'transparent');
    html += '<div class="day-pill ' + (isActive ? 'active ' : '') + (d.isToday ? 'today ' : '') + (d.isFuture ? 'future ' : '') + '" data-datekey="' + d.dateKey + '" onclick="selectDay(\\'' + d.dateKey + '\\')" title="' + d.fullDateName + '">';
    html += '<span class="day-name">' + (d.isToday ? 'TODAY' : d.name.toUpperCase()) + '</span>';
    html += '<span class="day-num">' + d.day + '</span>';
    html += '<span class="day-dot" style="background:' + dotColor + '; opacity:' + (rate > 0 ? 1 : 0) + ';"></span>';
    html += '</div>';
  });
  container.innerHTML = html;
  if (autoScrollToToday || !wasInitialized) {
    scrollRibbonToToday(false, false);
    if (container.dataset) container.dataset.initializedScroll = 'true';
  } else {
    container.scrollLeft = prevScroll;
  }
  syncReturnTodayPillVisibility();
}

function updateTabBadgeAndIsland() {
  const rem = state.getRemainingTodayCount();
  const badge = document.getElementById('today-tab-badge');
  if (badge && badge.classList) {
    badge.textContent = String(rem);
    badge.classList.toggle('visible', rem > 0);
  }
  const shieldTxt = document.getElementById('shield-count-text');
  if (shieldTxt) shieldTxt.textContent = String(state.streakFreezeShields);

  // Sync Expanded Dynamic Island Live Activity
  const expTitle = document.getElementById('island-exp-title');
  const expSub = document.getElementById('island-exp-sub');
  const expBadge = document.getElementById('island-exp-badge');
  const expIcon = document.getElementById('island-exp-icon');

  if (state.activeTimerHabitId) {
    const th = state.habits.find(h => h.id === state.activeTimerHabitId);
    if (th && expTitle) {
      const secs = state.timerMode === 'stopwatch' ? state.timerElapsedSeconds : state.timerRemainingSeconds;
      const tStr = formatSecondsMMSS(secs);
      expTitle.textContent = th.name;
      expSub.textContent = state.timerMode.toUpperCase() + ' • ' + (state.isTimerRunning ? 'Focusing Live' : 'Paused');
      expBadge.textContent = tStr;
      expIcon.style.background = th.color;
      expIcon.innerHTML = getIconSvg(th.icon, '#FFFFFF', 18);
      const pulse = document.getElementById('island-pulse-title');
      if (pulse) pulse.innerHTML = '<span>⏱️</span><span>' + tStr + '</span>';
      return;
    }
  }

  const due = state.activeHabits.filter(h => state.isHabitDueOnDate(h, state.todayKey));
  const rate = state.getCompletionRate(state.todayKey);
  const nextH = due.find(h => state.getHabitStatusOnSelectedDay(h, state.todayKey) === 'pending') || due[0];
  if (expTitle) {
    expTitle.textContent = nextH ? nextH.name : 'All Caught Up';
    expSub.textContent = due.length > 0 ? ('Daily Routine • ' + (due.length - rem) + '/' + due.length + ' done') : 'Tap + to add habits';
    expBadge.textContent = rate + '%';
    if (nextH && expIcon) {
      expIcon.style.background = nextH.color;
      expIcon.innerHTML = getIconSvg(nextH.icon, '#FFFFFF', 18);
    }
  }
}

function renderTodayScreen() {
  const container = document.getElementById('today-habits-container');
  if (!container) return;

  updateTabBadgeAndIsland();

  const vacBanner = document.getElementById('vacation-banner');
  if (vacBanner) vacBanner.style.display = state.vacationMode ? 'flex' : 'none';

  const dateBanner = document.getElementById('date-view-banner');
  const days = getTimelineDays();
  const activeDayObj = days.find(d => d.dateKey === state.selectedDay);
  if (dateBanner) {
    if (state.isDayToday()) {
      dateBanner.style.display = 'none';
    } else {
      dateBanner.style.display = 'flex';
      const lbl = activeDayObj ? activeDayObj.fullDateName : state.selectedDay;
      dateBanner.innerHTML = '<span>🗓️ Viewing ' + lbl + ' (' + (state.isDayPast() ? 'Past' : 'Upcoming') + ')</span><button onclick="refocusToToday()">↩ Today</button>';
    }
  }

  const headerDayName = document.getElementById('today-day-name');
  const headerDateTitle = document.getElementById('today-date-title');
  if (headerDayName) headerDayName.textContent = (activeDayObj ? activeDayObj.fullDateName : state.selectedDay).toUpperCase();
  if (headerDateTitle) headerDateTitle.textContent = state.isDayToday() ? 'Today' : (activeDayObj ? activeDayObj.name + ' ' + activeDayObj.day : 'Timeline');

  const dueHabits = state.activeHabits.filter(h => state.isHabitDueOnDate(h, state.selectedDay));
  const rate = state.getCompletionRate(state.selectedDay);
  const doneDue = dueHabits.filter(h => {
    const r = h.history && h.history[state.selectedDay];
    return r && (r.done || r.skipped || r.usedShield);
  }).length;
  const topStreak = state.activeHabits.reduce((m, h) => Math.max(m, h.streak || 0), 0);

  const gaugeVal = document.getElementById('hero-gauge-val');
  const gaugeText = document.getElementById('hero-gauge-text');
  const heroSub = document.getElementById('hero-motivation-sub');
  const heroTitle = document.getElementById('hero-motivation-title');
  const heroStreak = document.getElementById('hero-streak-chip');

  if (gaugeVal) gaugeVal.style.strokeDashoffset = 220 - (220 * rate) / 100;
  if (gaugeText) gaugeText.textContent = rate + '%';
  if (heroSub) {
    if (dueHabits.length === 0) {
      heroSub.textContent = 'Tap + to schedule your first habit';
    } else if (doneDue === dueHabits.length) {
      heroSub.textContent = 'All ' + dueHabits.length + ' scheduled habits done';
    } else if (rate > 0 && doneDue === 0) {
      heroSub.textContent = rate + '% progress • in progress';
    } else {
      heroSub.textContent = doneDue + ' of ' + dueHabits.length + ' scheduled habits done';
    }
  }
  if (heroStreak) heroStreak.innerHTML = '<span>🔥 ' + topStreak + 'd Top Streak</span>';
  if (heroTitle) {
    if (state.activeHabits.length === 0) heroTitle.textContent = 'Ready to Plan ✨';
    else if (rate === 100 && dueHabits.length > 0) heroTitle.textContent = 'All Goals Complete! 🎉';
    else if (rate >= 60) heroTitle.textContent = 'Strong Momentum 🔥';
    else heroTitle.textContent = 'Daily Focus';
  }

  renderHeroCirclesOrbit(dueHabits);
  updateLockScreenWidgets();

  renderWeekRibbon();

  if (document.querySelectorAll) {
    document.querySelectorAll('#today-filter-bar .ios-seg-btn').forEach(b => {
      b.classList.toggle('active', b.dataset.filter === state.todayFilter);
    });
  }

  if (state.activeHabits.length === 0) {
    container.innerHTML =
      '<div class="ios-grouped-list" style="padding:32px 20px; text-align:center;">' +
        '<div style="font-size:38px; margin-bottom:10px;">☑️</div>' +
        '<h3 style="font-size:18px; font-weight:800; color:var(--app-text-primary); margin-bottom:6px;">Build Your Daily Routine</h3>' +
        '<p style="font-size:12.5px; color:var(--app-text-muted); max-width:270px; margin:0 auto 16px; line-height:1.45;">Choose from 83 native presets, or click <b>🌱 Demo</b> in the top bar to test timers, rollovers, sub-checklists & quit-streaks.</p>' +
        '<div style="display:flex; gap:8px; justify-content:center;">' +
          '<button class="settings-btn-primary" onclick="openAddHabitSheet()">+ Add Habit</button>' +
          '<button class="mini-pill-btn" onclick="seedRichDemoData()">🌱 Load Demo</button>' +
        '</div>' +
      '</div>';
    return;
  }

  let visible = state.activeHabits.slice();
  if (state.todayFilter === 'due') {
    visible = visible.filter(h => state.isHabitDueOnDate(h, state.selectedDay));
  } else if (state.todayFilter === 'quit_limit') {
    visible = visible.filter(h => h.polarity !== 'build');
  }
  if (state.searchQuery.trim()) {
    const q = state.searchQuery.trim().toLowerCase();
    visible = visible.filter(h => {
      const note = (h.history && h.history[state.selectedDay] && h.history[state.selectedDay].note) || '';
      return h.name.toLowerCase().includes(q) || note.toLowerCase().includes(q);
    });
  }

  if (visible.length === 0) {
    container.innerHTML = '<div class="ios-grouped-list" style="padding:24px; text-align:center; color:var(--app-text-muted); font-size:13px;">No habits match this filter or search query.</div>';
    return;
  }

  const buckets = [
    { id: 'morning', label: 'Morning', icon: '🌅' },
    { id: 'afternoon', label: 'Afternoon', icon: '☀️' },
    { id: 'evening', label: 'Evening', icon: '🌙' },
    { id: 'anytime', label: 'Anytime', icon: '⏰' }
  ];

  let html = '';
  buckets.forEach(bucket => {
    const list = visible.filter(h => h.timeOfDay === bucket.id);
    if (list.length === 0) return;
    const doneCnt = list.filter(h => h.history && h.history[state.selectedDay] && h.history[state.selectedDay].done).length;

    html += '<div class="section-header" style="margin-top:8px; margin-bottom:6px;">';
    html += '<div class="section-title"><span>' + bucket.icon + '</span><span>' + bucket.label + '</span> <span style="font-size:11px; color:var(--app-text-muted); font-weight:600;">' + doneCnt + '/' + list.length + '</span></div>';
    html += '<button class="routine-play-pill" onclick="openRoutinePlayer(\\'' + bucket.id + '\\')">▶ Routine</button>';
    html += '</div>';

    html += '<div class="ios-grouped-list">';
    list.forEach(habit => {
      html += renderHabitRowHTML(habit);
    });
    html += '</div>';
  });

  container.innerHTML = html;
  attachRowSwipeHandlers();
}

function renderHabitRowHTML(habit) {
  const dateKey = state.selectedDay;
  const status = state.getHabitStatusOnSelectedDay(habit, dateKey);
  const isCompleted = status === 'completed';
  const isSkipped = status === 'skipped';
  const isFatalMissed = status === 'fatal_missed';
  const rec = (habit.history && habit.history[dateKey]) || {};
  const moodEmoji = rec.mood && MOOD_META[rec.mood] ? MOOD_META[rec.mood].emoji : '';
  const hasNote = Boolean(rec.note && rec.note.trim());
  const rolloverExtra = state.rolloverBonus(habit, dateKey);
  const isSwiped = state.swipedHabitId === habit.id;
  const isAmountQuickStep = (habit.polarity === 'build' && habit.type === 'amount' && !isCompleted);
  const leadingIcon = isAmountQuickStep ? '💧' : (isCompleted ? '↩️' : '✓');
  const leadingLabel = isAmountQuickStep ? ('+' + habit.stepAmount) : (isCompleted ? 'Undo' : 'Done');
  const leadingBtnClass = isAmountQuickStep ? 'swipe-step' : 'swipe-done';

  let html = '<div class="habit-swipe-wrapper' + (isSwiped ? ' is-swiped-open' : '') + '" data-wrapper-id="' + habit.id + '">';
  html += '<div class="habit-leading-actions">';
  html += '<button class="swipe-act-btn ' + leadingBtnClass + '" tabindex="-1"><span>' + leadingIcon + '</span><span>' + leadingLabel + '</span></button>';
  html += '</div>';
  html += '<div class="habit-swipe-actions">';
  html += '<button class="swipe-act-btn swipe-skip" onclick="event.stopPropagation(); onQuickSkip(' + habit.id + ')"><span>⏭️</span><span>' + (isSkipped ? 'Unskip' : 'Skip') + '</span></button>';
  html += '<button class="swipe-act-btn swipe-edit" onclick="event.stopPropagation(); openEditHabitSheet(' + habit.id + ')"><span>✏️</span><span>Edit</span></button>';
  html += '<button class="swipe-act-btn swipe-del" onclick="event.stopPropagation(); onQuickDelete(' + habit.id + ')"><span>🗑️</span><span>Delete</span></button>';
  html += '</div>';

  html += '<div class="habit-card native-row ' + (isCompleted ? 'completed ' : '') + (isFatalMissed ? 'fatal-missed ' : '') + (isSwiped ? 'swiped-left' : '') + '" data-habit-id="' + habit.id + '" onclick="onHabitCardClick(event, ' + habit.id + ')" oncontextmenu="openContextMenu(event, ' + habit.id + ')">';

  html += '<div class="habit-card-top">';
  html += '<div class="habit-main">';
  html += '<div class="habit-icon-wrapper" style="width:38px; height:38px; border-radius:11px; background:' + habit.color + ';">' + getIconSvg(habit.icon, '#FFFFFF', 19) + '</div>';
  html += '<div class="habit-details">';
  html += '<span class="habit-name">' + escapeHtml(habit.name) + (moodEmoji ? ' ' + moodEmoji : '') + (hasNote ? ' 📝' : '') + '</span>';

  html += '<div class="habit-tags-row">';
  if (habit.polarity === 'quit') {
    html += '<span class="habit-tag" style="background:rgba(255,45,85,0.15); color:#FF2D55;">✋ Quit</span>';
  } else if (habit.polarity === 'limit') {
    html += '<span class="habit-tag" style="background:rgba(191,90,242,0.15); color:#BF5AF2;">📉 Max ' + habit.targetAmount + ' ' + escapeHtml(habit.unit) + '</span>';
  } else if (isPeriodicFrequency(habit.frequency)) {
    const done = state.getPeriodicCompletedCount(habit, dateKey);
    const target = getPeriodicTargetCount(habit);
    const unitText = isWeeklyPeriodic(habit.frequency) ? 'this wk' : 'this mo';
    if (done >= target) {
      html += '<span class="habit-tag" style="background:rgba(48,209,88,0.16); color:#30D158; font-weight:700; white-space:nowrap;">✓ ' + done + '/' + target + ' ' + unitText + ' ✓</span>';
    } else {
      html += '<span class="habit-tag" style="background:rgba(10,132,255,0.15); color:' + (habit.color || '#0A84FF') + '; font-weight:700; white-space:nowrap;">📅 ' + done + '/' + target + ' ' + unitText + '</span>';
    }
  } else {
    html += '<span class="habit-tag tag-freq">' + escapeHtml(getRepeatLabel(habit)) + '</span>';
  }
  if (isSkipped) {
    html += '<span class="habit-tag" style="background:rgba(50,173,230,0.16); color:#32ADE6;">' + (rec.usedShield ? '❄️ Shielded' : '⏭️ Skipped') + '</span>';
  } else if (Array.isArray(habit.subtasks) && habit.subtasks.length > 0) {
    const doneSubsCount = (rec.completedSubtasks || []).length;
    const totalSubsCount = habit.subtasks.length;
    html += '<span class="habit-tag tag-subtasks" style="background:rgba(10,132,255,0.15); color:' + (isCompleted ? '#30D158' : (habit.color || '#0A84FF')) + '; font-weight:700; white-space:nowrap;">☑️ ' + doneSubsCount + '/' + totalSubsCount + '</span>';
  } else if (rolloverExtra > 0) {
    html += '<span class="habit-tag tag-rollover">🔄 +' + rolloverExtra + ' rollover</span>';
  }
  let streakUnit = 'd';
  if (isWeeklyPeriodic(habit.frequency)) streakUnit = 'w';
  else if (isMonthlyPeriodic(habit.frequency)) streakUnit = 'm';
  html += '<span style="color:#FF9F0A; font-size:11px; font-weight:800; white-space:nowrap;">🔥 ' + (habit.streak || 0) + streakUnit + '</span>';
  html += '</div>';
  html += '</div></div>';

  html += '<div style="display:flex; align-items:center; gap:6px;">';
  if (isFatalMissed) {
    if (state.streakFreezeShields > 0) {
      html += '<button class="mini-pill-btn" title="Unlock with Streak Freeze Shield" onclick="event.stopPropagation(); onApplyShield(' + habit.id + ')">❄️ Shield</button>';
    } else {
      html += '<button class="habit-check-btn" disabled title="Locked by Strict Mode"><span style="font-size:13px;">🔒</span></button>';
    }
  } else {
    html += '<button class="habit-check-btn" onclick="onHabitCheckClick(event, ' + habit.id + ')" aria-label="Toggle habit"><svg viewBox="0 0 24 24"><polyline points="20 6 9 17 4 12"></polyline></svg></button>';
  }
  html += '<span style="font-size:13px; font-weight:700; color:var(--app-text-muted); opacity:0.6; padding-right:2px;">›</span>';
  html += '</div></div>';

  // Subtasks Checklist with Live Proportional Progress Bar
  if (Array.isArray(habit.subtasks) && habit.subtasks.length > 0 && !isSkipped) {
    const doneSubs = rec.completedSubtasks || [];
    const totalSubs = habit.subtasks.length;
    const fraction = totalSubs > 0 ? Math.min(1.0, doneSubs.length / totalSubs) : 0;
    const pct = Math.round(fraction * 100);
    const progressColor = isCompleted ? '#30D158' : (habit.color || '#0A84FF');

    html += '<div class="subtasks-container" onclick="event.stopPropagation()">';
    html += '<div class="subtasks-progress-header">';
    html += '<span class="subtasks-progress-text" style="color:' + (isCompleted ? '#30D158' : 'var(--app-text-secondary)') + ';">' + doneSubs.length + ' of ' + totalSubs + ' steps done</span>';
    html += '<span class="subtasks-progress-pct" style="color:' + progressColor + ';">' + pct + '%</span>';
    html += '</div>';
    html += '<div class="subtasks-track"><div class="subtasks-fill" style="width:' + pct + '%; background:' + progressColor + ';"></div></div>';
    html += '<div class="subtasks-list">';
    habit.subtasks.forEach(st => {
      const stDone = doneSubs.includes(st.id);
      html += '<div class="subtask-item ' + (stDone ? 'done' : '') + '" onclick="onSubtaskToggle(event, ' + habit.id + ', \\'' + st.id + '\\')">';
      html += '<span class="subtask-box">' + (stDone ? '✓' : '') + '</span>';
      html += '<span>' + escapeHtml(st.title) + '</span>';
      html += '</div>';
    });
    html += '</div></div>';
  }

  // Polarity & Mode Controls
  if (habit.polarity === 'quit') {
    const slips = rec.slips || 0;
    html += '<div class="quit-Limit-row" onclick="event.stopPropagation()">';
    html += '<span style="color:' + (slips > 0 ? '#FF453A' : '#30D158') + ';">' + (slips > 0 ? ('Slipped ' + slips + 'x on this date') : ((habit.streak || 0) + 'd clean abstinence')) + '</span>';
    html += '<button class="mini-pill-btn danger" onclick="onLogQuitSlip(event, ' + habit.id + ')">Log Slip</button>';
    html += '</div>';
  } else if (habit.polarity === 'limit') {
    const dayAmt = Number(rec.amount) || 0;
    const pct = Math.min(100, Math.round((dayAmt / Math.max(1, habit.targetAmount)) * 100));
    const over = dayAmt > habit.targetAmount;
    html += '<div class="amount-progress-section" onclick="event.stopPropagation()">';
    html += '<div class="amount-text-row"><span style="color:' + (over ? '#FF453A' : 'inherit') + ';">' + dayAmt + ' / ' + habit.targetAmount + ' ' + escapeHtml(habit.unit) + ' cap</span>';
    html += '<button class="mini-pill-btn" onclick="onAddAmount(event, ' + habit.id + ', ' + Math.max(1, habit.stepAmount) + ')">+' + Math.max(1, habit.stepAmount) + ' ' + escapeHtml(habit.unit) + '</button></div>';
    html += '<div class="amount-track"><div class="amount-fill" style="width:' + pct + '%; background:' + (over ? '#FF453A' : '#30D158') + ';"></div></div>';
    html += '</div>';
  } else if (habit.type === 'amount') {
    const effTarget = state.effectiveTargetAmount(habit, dateKey);
    const dayAmt = Number(rec.amount) || 0;
    const pct = Math.min(100, Math.round((dayAmt / Math.max(1, effTarget)) * 100));
    html += '<div class="amount-progress-section">';
    html += '<div class="amount-text-row"><span>' + dayAmt + ' / ' + effTarget + ' ' + escapeHtml(habit.unit) + '</span><span>' + pct + '%</span></div>';
    html += '<div class="amount-track"><div class="amount-fill" style="width:' + pct + '%;"></div></div>';
    if (!isFatalMissed && !isCompleted) {
      html += '<div class="amount-chip-buttons" onclick="event.stopPropagation()">';
      html += '<button class="amount-chip" onclick="onAddAmount(event, ' + habit.id + ', ' + habit.stepAmount + ')">+' + habit.stepAmount + ' ' + escapeHtml(habit.unit) + '</button>';
      html += '<button class="amount-chip" onclick="onAddAmount(event, ' + habit.id + ', ' + (habit.stepAmount * 2) + ')">+' + (habit.stepAmount * 2) + ' ' + escapeHtml(habit.unit) + '</button>';
      html += '</div>';
    }
    html += '</div>';
  } else if (habit.type === 'reps') {
    const dayReps = Number(rec.reps) || 0;
    html += '<div class="reps-progress-section">';
    html += '<div class="reps-dots-box">';
    for (let r = 1; r <= Math.min(10, habit.targetReps); r++) {
      html += '<div class="rep-dot ' + (r <= dayReps ? 'filled' : '') + '"></div>';
    }
    html += '</div>';
    if (!isFatalMissed) {
      html += '<div class="reps-stepper" onclick="event.stopPropagation()">';
      html += '<button class="reps-btn" onclick="onStepReps(event, ' + habit.id + ', -1)">−</button>';
      html += '<span class="reps-count-badge">' + dayReps + '/' + habit.targetReps + '</span>';
      html += '<button class="reps-btn" onclick="onStepReps(event, ' + habit.id + ', 1)">+</button>';
      html += '</div>';
    }
    html += '</div>';
  } else if (habit.type === 'timer') {
    const isRunningThis = state.activeTimerHabitId === habit.id && state.isTimerRunning;
    html += '<div class="quit-Limit-row" onclick="event.stopPropagation()">';
    html += '<span style="color:var(--app-text-secondary);">⏱️ ' + habit.targetDuration + ' min focus session</span>';
    html += '<button class="mini-pill-btn primary" style="background:' + habit.color + ';" onclick="openFocusTimerModal(' + habit.id + ')">' + (isRunningThis ? '⚡ Focusing...' : (isCompleted ? '▶ Focus Again' : '▶ Start Timer')) + '</button>';
    html += '</div>';
  }

  html += '</div></div>';
  return html;
}

let suppressRowClickUntil = 0;
const SWIPE_TRAILING_WIDTH = 156;
const SWIPE_LEADING_THRESHOLD = 66;

function closeSwipedRowSmoothly(exceptId = null) {
  if (!document.querySelectorAll) return;
  document.querySelectorAll('.habit-swipe-wrapper.is-swiped-open').forEach(wrap => {
    const wid = Number(wrap.dataset.wrapperId);
    if (exceptId !== null && wid === exceptId) return;
    wrap.classList.remove('is-dragging', 'is-swiped-open');
    const r = wrap.querySelector('.habit-card.native-row');
    const tr = wrap.querySelector('.habit-swipe-actions');
    const ld = wrap.querySelector('.habit-leading-actions');
    if (r) { r.classList.remove('swiped-left'); r.style.transform = ''; }
    if (tr) tr.style.width = '';
    if (ld) ld.style.width = '';
  });
  if (exceptId === null) {
    state.swipedHabitId = null;
  }
}

function attachRowSwipeHandlers() {
  if (!document.querySelectorAll) return;
  document.querySelectorAll('.habit-card.native-row').forEach(row => {
    const id = Number(row.dataset.habitId);
    const wrapper = row.closest ? row.closest('.habit-swipe-wrapper') : row.parentElement;
    const trailingDrawer = wrapper && wrapper.querySelector ? wrapper.querySelector('.habit-swipe-actions') : null;
    const leadingDrawer = wrapper && wrapper.querySelector ? wrapper.querySelector('.habit-leading-actions') : null;
    if (!wrapper) return;

    let activePointerId = null;
    let startX = 0;
    let startY = 0;
    let startTime = 0;
    let baseOffset = 0;
    let currentDx = 0;
    let isHorizontalDrag = false;
    let directionDecided = false;
    let thresholdTicked = false;

    const onPointerDown = (e) => {
      if (e.pointerType === 'mouse' && e.button !== 0) return;
      if (e.target && e.target.closest && e.target.closest('button, .subtask-item, input, select, textarea, a')) {
        return;
      }
      activePointerId = e.pointerId;
      startX = e.clientX;
      startY = e.clientY;
      startTime = Date.now();
      baseOffset = (state.swipedHabitId === id) ? -SWIPE_TRAILING_WIDTH : 0;
      currentDx = baseOffset;
      isHorizontalDrag = false;
      directionDecided = false;
      thresholdTicked = false;

      if (state.swipedHabitId && state.swipedHabitId !== id) {
        closeSwipedRowSmoothly();
      }
    };

    const onPointerMove = (e) => {
      if (activePointerId === null || e.pointerId !== activePointerId) return;
      const rawDx = e.clientX - startX;
      const rawDy = e.clientY - startY;

      if (!directionDecided) {
        if (Math.abs(rawDx) < 5 && Math.abs(rawDy) < 5) return;
        directionDecided = true;
        if (Math.abs(rawDx) >= Math.abs(rawDy)) {
          isHorizontalDrag = true;
          wrapper.classList.add('is-dragging');
          if (row.setPointerCapture) {
            try { row.setPointerCapture(e.pointerId); } catch (_) {}
          }
        } else {
          activePointerId = null;
          return;
        }
      }

      if (!isHorizontalDrag) return;
      if (e.cancelable) e.preventDefault();

      let dx = baseOffset + rawDx;

      // Rubber-band physics beyond leading & trailing limits
      if (dx < -SWIPE_TRAILING_WIDTH) {
        const overswipe = dx + SWIPE_TRAILING_WIDTH;
        dx = -SWIPE_TRAILING_WIDTH + overswipe * 0.32;
      } else if (dx > 96) {
        const overswipe = dx - 96;
        dx = 96 + overswipe * 0.32;
      }

      currentDx = dx;
      row.style.transform = 'translate3d(' + dx.toFixed(1) + 'px, 0, 0)';

      if (dx < 0) {
        if (trailingDrawer) trailingDrawer.style.width = Math.max(0, -dx).toFixed(1) + 'px';
        if (leadingDrawer) leadingDrawer.style.width = '0px';
        if (!thresholdTicked && baseOffset === 0 && dx < -54) {
          thresholdTicked = true;
          sound.playHaptic();
        }
      } else if (dx > 0) {
        if (leadingDrawer) leadingDrawer.style.width = Math.max(0, dx).toFixed(1) + 'px';
        if (trailingDrawer) trailingDrawer.style.width = '0px';
        if (!thresholdTicked && dx > SWIPE_LEADING_THRESHOLD) {
          thresholdTicked = true;
          sound.playHaptic();
        }
      } else {
        if (trailingDrawer) trailingDrawer.style.width = '0px';
        if (leadingDrawer) leadingDrawer.style.width = '0px';
      }
    };

    const finishSwipe = (e) => {
      if (activePointerId === null || (e && e.pointerId !== undefined && e.pointerId !== activePointerId)) return;
      const wasDragging = isHorizontalDrag;
      const pid = activePointerId;
      activePointerId = null;
      isHorizontalDrag = false;
      directionDecided = false;

      if (row.releasePointerCapture && pid !== null) {
        try { row.releasePointerCapture(pid); } catch (_) {}
      }

      if (!wasDragging) return;

      suppressRowClickUntil = Date.now() + 280;
      const elapsed = Math.max(1, Date.now() - startTime);
      const velocityX = (currentDx - baseOffset) / elapsed; // px per ms

      // Re-enable smooth Cupertino spring transition before snapping to resting state
      wrapper.classList.remove('is-dragging');
      void wrapper.offsetWidth;

      // Case 1: Swiped right past leading threshold (from closed) -> Complete / +Step!
      if (baseOffset === 0 && (currentDx > SWIPE_LEADING_THRESHOLD || (currentDx > 30 && velocityX > 0.45))) {
        wrapper.classList.remove('is-swiped-open');
        row.classList.remove('swiped-left');
        row.style.transform = '';
        if (trailingDrawer) trailingDrawer.style.width = '';
        if (leadingDrawer) leadingDrawer.style.width = '';
        state.swipedHabitId = null;

        const habit = state.habits.find(h => h.id === id);
        if (habit && ! (state.getHabitStatusOnSelectedDay(habit, state.selectedDay) === 'fatal_missed')) {
          setTimeout(() => {
            if (habit.polarity === 'build' && habit.type === 'amount' && ! (habit.history && habit.history[state.selectedDay] && habit.history[state.selectedDay].done)) {
              const done = state.incrementAmount(id, habit.stepAmount);
              if (done) { confetti.burst(); sound.playSuccess(); showToast('Daily target reached! 🎉'); }
              else { sound.playClick(); showToast('+' + habit.stepAmount + ' ' + habit.unit + ' logged! 💧'); }
            } else {
              const done = state.toggleBinaryHabit(id);
              if (done) { confetti.burst(); sound.playSuccess(); showToast('Swiped Complete! ✓'); }
              else { sound.playClick(); showToast('Marked incomplete'); }
            }
            renderTodayScreen();
          }, 160);
        }
        return;
      }

      // Case 2: Swiped left enough (or flicked left) -> Snap open to reveal Skip / Edit / Delete
      const shouldOpenLeft = (baseOffset === 0)
        ? (currentDx < -50 || (currentDx < -22 && velocityX < -0.35))
        : !(currentDx > -SWIPE_TRAILING_WIDTH + 42 || velocityX > 0.35);

      if (shouldOpenLeft) {
        state.swipedHabitId = id;
        wrapper.classList.add('is-swiped-open');
        row.classList.add('swiped-left');
        row.style.transform = '';
        if (trailingDrawer) trailingDrawer.style.width = '';
        if (leadingDrawer) leadingDrawer.style.width = '';
      } else {
        state.swipedHabitId = null;
        wrapper.classList.remove('is-swiped-open');
        row.classList.remove('swiped-left');
        row.style.transform = '';
        if (trailingDrawer) trailingDrawer.style.width = '';
        if (leadingDrawer) leadingDrawer.style.width = '';
      }
    };

    row.addEventListener('pointerdown', onPointerDown);
    row.addEventListener('pointermove', onPointerMove);
    row.addEventListener('pointerup', finishSwipe);
    row.addEventListener('pointercancel', finishSwipe);
  });
}

function enableHorizontalDragScroll(el) {
  if (!el || !el.addEventListener) return;
  let isDown = false;
  let startX = 0;
  let startScrollLeft = 0;
  let moved = false;

  el.addEventListener('pointerdown', (e) => {
    if (e.pointerType === 'mouse' && e.button !== 0) return;
    isDown = true;
    moved = false;
    startX = e.clientX;
    startScrollLeft = el.scrollLeft;
  });

  el.addEventListener('pointermove', (e) => {
    if (!isDown) return;
    const dx = e.clientX - startX;
    if (Math.abs(dx) > 5) {
      if (!moved) {
        moved = true;
        if (el.setPointerCapture) {
          try { el.setPointerCapture(e.pointerId); } catch (_) {}
        }
      }
      el.scrollLeft = startScrollLeft - dx;
    }
  });

  const endDrag = (e) => {
    if (!isDown) return;
    isDown = false;
    if (moved) {
      suppressRowClickUntil = Date.now() + 220;
      if (el.releasePointerCapture && e && e.pointerId !== undefined) {
        try { el.releasePointerCapture(e.pointerId); } catch (_) {}
      }
    }
  };

  el.addEventListener('pointerup', endDrag);
  el.addEventListener('pointercancel', endDrag);
  el.addEventListener('click', (e) => {
    if (Date.now() < suppressRowClickUntil) {
      e.stopPropagation();
      e.preventDefault();
    }
  }, true);
}

// ============================================================================
// ROW INTERACTIONS & CONTEXT MENU
// ============================================================================

function onHabitCheckClick(e, id) {
  e.stopPropagation();
  sound.playClick();
  const completed = state.toggleBinaryHabit(id);
  if (completed) {
    sound.playSuccess();
    confetti.burst();
    showToast('Completed! Streak updated 🔥');
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
    showToast('Daily target reached! 🎉');
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
    showToast('All reps finished! 🔥');
  }
  renderTodayScreen();
}

function onSubtaskToggle(e, habitId, subId) {
  e.stopPropagation();
  sound.playClick();
  const allDone = state.toggleSubtask(habitId, subId);
  if (allDone) {
    sound.playSuccess();
    confetti.burst();
    showToast('All checklist steps complete! 🎉');
  }
  renderTodayScreen();
}

function onLogQuitSlip(e, id) {
  e.stopPropagation();
  sound.playHaptic();
  state.logQuitSlip(id);
  renderTodayScreen();
  showToast('Slip logged — timer reset, keep going 💪');
}

function onQuickSkip(id) {
  state.swipedHabitId = null;
  state.toggleSkipHabit(id);
  sound.playClick();
  renderTodayScreen();
  showToast('Day marked as Skipped (Streak Safe) ⏭️');
}

function onQuickDelete(id) {
  state.swipedHabitId = null;
  state.deleteHabit(id);
  sound.playClick();
  renderTodayScreen();
  showToast('Habit deleted 🗑️');
}

function onApplyShield(id) {
  if (state.useFreezeShield(id)) {
    sound.playSuccess();
    renderTodayScreen();
    showToast('Streak Freeze Shield applied! ❄️');
  }
}

function openContextMenu(e, habitId) {
  e.preventDefault();
  e.stopPropagation();
  sound.playHaptic();
  const habit = state.habits.find(h => h.id === habitId);
  if (!habit) return;
  const menu = document.getElementById('ios-context-menu');
  const backdrop = document.getElementById('context-menu-backdrop');
  if (!menu || !backdrop) return;

  const isDone = habit.history && habit.history[state.selectedDay] && habit.history[state.selectedDay].done;
  const isSkipped = habit.history && habit.history[state.selectedDay] && habit.history[state.selectedDay].skipped;

  let html = '<div class="ctx-header">' + escapeHtml(habit.name) + '</div>';
  html += '<button class="ctx-item" onclick="ctxAct(\\'toggle\\',' + habit.id + ')"><span>' + (isDone ? 'Mark Incomplete' : 'Mark Completed') + '</span><span>✓</span></button>';
  if (habit.type === 'timer') {
    html += '<button class="ctx-item" onclick="ctxAct(\\'timer\\',' + habit.id + ')"><span>Open Focus Timer</span><span>⏱️</span></button>';
  }
  html += '<button class="ctx-item" onclick="ctxAct(\\'journal\\',' + habit.id + ')"><span>Mood & Reflection Note</span><span>📝</span></button>';
  html += '<button class="ctx-item" onclick="ctxAct(\\'skip\\',' + habit.id + ')"><span>' + (isSkipped ? 'Remove Skip' : 'Skip / Rest Day') + '</span><span>⏭️</span></button>';
  html += '<button class="ctx-item" onclick="ctxAct(\\'up\\',' + habit.id + ')"><span>Move Up</span><span>↑</span></button>';
  html += '<button class="ctx-item" onclick="ctxAct(\\'down\\',' + habit.id + ')"><span>Move Down</span><span>↓</span></button>';
  html += '<button class="ctx-item" onclick="ctxAct(\\'edit\\',' + habit.id + ')"><span>Edit Habit</span><span>✏️</span></button>';
  html += '<button class="ctx-item" onclick="ctxAct(\\'dup\\',' + habit.id + ')"><span>Duplicate</span><span>📋</span></button>';
  html += '<button class="ctx-item" onclick="ctxAct(\\'archive\\',' + habit.id + ')"><span>Archive Habit</span><span>📦</span></button>';
  html += '<button class="ctx-item destructive" onclick="ctxAct(\\'delete\\',' + habit.id + ')"><span>Delete Habit</span><span>🗑️</span></button>';

  menu.innerHTML = html;
  backdrop.classList.add('active');
}

function closeContextMenu() {
  const backdrop = document.getElementById('context-menu-backdrop');
  if (backdrop) backdrop.classList.remove('active');
}

function ctxAct(action, id) {
  closeContextMenu();
  if (action === 'toggle') { state.toggleBinaryHabit(id); renderTodayScreen(); }
  else if (action === 'timer') { openFocusTimerModal(id); }
  else if (action === 'journal') { openJournalModal(id, state.selectedDay); }
  else if (action === 'skip') { onQuickSkip(id); }
  else if (action === 'up') { state.moveHabitOrder(id, -1); renderTodayScreen(); }
  else if (action === 'down') { state.moveHabitOrder(id, 1); renderTodayScreen(); }
  else if (action === 'edit') { openEditHabitSheet(id); }
  else if (action === 'dup') { state.duplicateHabit(id); renderTodayScreen(); showToast('Habit duplicated 📋'); }
  else if (action === 'archive') { state.toggleArchiveHabit(id); renderTodayScreen(); showToast('Habit archived 📦'); }
  else if (action === 'delete') { onQuickDelete(id); }
}

// ============================================================================
// REAL FOCUS TIMER, ROUTINE PLAYER, JOURNAL & CALENDAR MODALS
// ============================================================================

function formatSecondsMMSS(secs) {
  const m = Math.floor(Math.max(0, secs) / 60);
  const s = Math.floor(Math.max(0, secs) % 60);
  return String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
}

function openNativeModal(html, modalType) {
  state.openModalType = modalType;
  const sheet = document.getElementById('native-modal-sheet');
  const backdrop = document.getElementById('native-modal-backdrop');
  if (!sheet || !backdrop) return;
  sheet.innerHTML = '<div class="sheet-handle"></div>' + html;
  backdrop.classList.add('active');
}

function closeNativeModal() {
  state.openModalType = null;
  const backdrop = document.getElementById('native-modal-backdrop');
  if (backdrop) backdrop.classList.remove('active');
  updateFloatingTimerBar();
}

function openFocusTimerModal(habitId) {
  const habit = state.habits.find(h => h.id === habitId);
  if (!habit) return;
  sound.playClick();
  if (state.activeTimerHabitId !== habitId) {
    stopFocusTimer();
    state.activeTimerHabitId = habitId;
    state.timerMode = 'countdown';
    state.timerTotalSeconds = (habit.targetDuration || 15) * 60;
    state.timerRemainingSeconds = state.timerTotalSeconds;
    state.timerElapsedSeconds = 0;
  }
  renderFocusTimerModalContent();
}

function reopenActiveTimerModal() {
  if (state.activeTimerHabitId) openFocusTimerModal(state.activeTimerHabitId);
}

function renderFocusTimerModalContent() {
  const habit = state.habits.find(h => h.id === state.activeTimerHabitId);
  if (!habit) return;
  const secs = state.timerMode === 'stopwatch' ? state.timerElapsedSeconds : state.timerRemainingSeconds;
  const timeStr = formatSecondsMMSS(secs);

  let html = '<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">';
  html += '<strong style="font-size:16px; color:var(--app-text-primary);">' + escapeHtml(habit.name) + '</strong>';
  html += '<button class="mini-pill-btn" onclick="closeNativeModal()">Minimize</button></div>';

  html += '<div class="ios-segmented">';
  ['countdown', 'pomodoro', 'stopwatch'].forEach(m => {
    const lbl = m === 'countdown' ? 'Countdown' : (m === 'pomodoro' ? 'Pomodoro 25m' : 'Stopwatch');
    html += '<button class="ios-seg-btn ' + (state.timerMode === m ? 'active' : '') + '" onclick="switchTimerMode(\\'' + m + '\\')">' + lbl + '</button>';
  });
  html += '</div>';

  html += '<div style="text-align:center; padding:22px 0;">';
  html += '<div id="modal-live-time" style="font-size:52px; font-weight:800; font-variant-numeric:tabular-nums; color:var(--app-text-primary); letter-spacing:-1px;">' + timeStr + '</div>';
  html += '<div style="font-size:12px; color:var(--app-text-secondary); margin-top:4px;">' + (state.isTimerRunning ? '🔥 Synced with Dynamic Island' : 'Ready to focus') + '</div>';
  if (state.timerMode !== 'stopwatch') {
    html += '<div style="display:flex; gap:8px; justify-content:center; margin-top:12px;">';
    html += '<button class="mini-pill-btn" onclick="adjustTimerSeconds(-60)">−1m</button>';
    html += '<button class="mini-pill-btn" onclick="adjustTimerSeconds(300)">+5m</button>';
    html += '</div>';
  }
  html += '</div>';

  html += '<div style="display:grid; grid-template-columns:auto 1fr auto; gap:10px;">';
  html += '<button class="mini-pill-btn danger" onclick="stopFocusTimer(); closeNativeModal();">✕ Stop</button>';
  html += '<button class="submit-habit-btn" style="margin:0; background:' + habit.color + ';" onclick="toggleTimerRunning()">' + (state.isTimerRunning ? '⏸ Pause' : '▶ Start Focus') + '</button>';
  html += '<button class="mini-pill-btn primary" style="background:#30D158; color:#000;" onclick="completeActiveTimer()">✓ Done</button>';
  html += '</div>';

  openNativeModal(html, 'timer');
}

function switchTimerMode(mode) {
  const habit = state.habits.find(h => h.id === state.activeTimerHabitId);
  if (!habit) return;
  pauseFocusTimer();
  state.timerMode = mode;
  const mins = mode === 'pomodoro' ? 25 : (habit.targetDuration || 15);
  state.timerTotalSeconds = mins * 60;
  state.timerRemainingSeconds = mins * 60;
  state.timerElapsedSeconds = 0;
  renderFocusTimerModalContent();
  updateFloatingTimerBar();
}

function adjustTimerSeconds(delta) {
  state.timerTotalSeconds = Math.max(60, state.timerTotalSeconds + delta);
  state.timerRemainingSeconds = Math.max(10, state.timerRemainingSeconds + delta);
  sound.playClick();
  if (state.openModalType === 'timer') renderFocusTimerModalContent();
  updateFloatingTimerBar();
}

function toggleTimerRunning() {
  if (state.isTimerRunning) {
    pauseFocusTimer();
  } else {
    state.isTimerRunning = true;
    sound.playClick();
    if (state.timerInterval) clearInterval(state.timerInterval);
    state.timerInterval = setInterval(() => {
      if (!state.isTimerRunning) return;
      if (state.timerMode === 'stopwatch') {
        state.timerElapsedSeconds += 1;
      } else {
        state.timerRemainingSeconds = Math.max(0, state.timerRemainingSeconds - 1);
        if (state.timerRemainingSeconds <= 0) {
          completeActiveTimer();
          return;
        }
      }
      const liveEl = document.getElementById('modal-live-time');
      if (liveEl) {
        const s = state.timerMode === 'stopwatch' ? state.timerElapsedSeconds : state.timerRemainingSeconds;
        liveEl.textContent = formatSecondsMMSS(s);
      }
      updateFloatingTimerBar();
      updateTabBadgeAndIsland();
    }, 1000);
  }
  if (state.openModalType === 'timer') renderFocusTimerModalContent();
  updateFloatingTimerBar();
  updateTabBadgeAndIsland();
}

function pauseFocusTimer() {
  state.isTimerRunning = false;
  if (state.timerInterval) {
    clearInterval(state.timerInterval);
    state.timerInterval = null;
  }
}

function stopFocusTimer() {
  pauseFocusTimer();
  state.activeTimerHabitId = null;
  updateFloatingTimerBar();
  updateTabBadgeAndIsland();
  renderTodayScreen();
}

function completeActiveTimer() {
  const id = state.activeTimerHabitId;
  const habit = state.habits.find(h => h.id === id);
  if (habit) {
    const rec = state.ensureDayRecord(habit, state.todayKey);
    rec.done = true;
    rec.durationSeconds = (rec.durationSeconds || 0) + (state.timerMode === 'stopwatch' ? Math.max(60, state.timerElapsedSeconds) : state.timerTotalSeconds);
    state.recalculateHabitStats(habit);
    state.saveHabits();
    sound.playSuccess();
    confetti.burst();
    showToast('Focus session completed! 🎉');
  }
  stopFocusTimer();
  closeNativeModal();
}

function updateFloatingTimerBar() {
  const bar = document.getElementById('floating-timer-bar');
  const island = document.getElementById('dynamic-island');
  const pulseTitle = document.getElementById('island-pulse-title');
  const pulseText = document.getElementById('island-pulse-text');
  const expTitle = document.getElementById('island-exp-title');
  const expSub = document.getElementById('island-exp-sub');
  const expBadge = document.getElementById('island-exp-badge');
  const expIcon = document.getElementById('island-exp-icon');

  const habit = state.habits.find(h => h.id === state.activeTimerHabitId);
  if (!habit) {
    if (bar) bar.classList.remove('active');
    if (island) island.classList.remove('expanded', 'active-timer');
    if (pulseTitle) pulseTitle.style.display = 'none';
    return;
  }
  
  const secs = state.timerMode === 'stopwatch' ? state.timerElapsedSeconds : state.timerRemainingSeconds;
  const timeFormatted = formatSecondsMMSS(secs);

  if (bar) bar.classList.add('active');
  if (island) island.classList.add('active-timer');
  if (pulseTitle) pulseTitle.style.display = 'flex';
  if (pulseText) pulseText.textContent = timeFormatted;
  if (expTitle) expTitle.textContent = habit.name;
  if (expSub) expSub.textContent = state.timerMode.toUpperCase() + ' Session';
  if (expBadge) expBadge.textContent = timeFormatted;
  if (expIcon) expIcon.style.background = habit.color;

  const ftTitle = document.getElementById('ft-title');
  const ftSub = document.getElementById('ft-sub');
  const ftBtn = document.getElementById('ft-toggle-btn');
  const ftIcon = document.getElementById('ft-icon');
  if (ftTitle) ftTitle.textContent = habit.name;
  if (ftSub) ftSub.textContent = state.timerMode.toUpperCase() + ' • ' + timeFormatted;
  if (ftBtn) ftBtn.textContent = state.isTimerRunning ? 'Pause' : 'Resume';
  if (ftIcon) ftIcon.style.background = habit.color;
}

// Guided Step-by-Step Routine Player
function openRoutinePlayer(bucket) {
  state.routineBucket = bucket;
  const list = state.activeHabits.filter(h => h.timeOfDay === bucket);
  const firstPending = list.findIndex(h => state.getHabitStatusOnSelectedDay(h, state.selectedDay) === 'pending');
  state.routineStepIndex = firstPending >= 0 ? firstPending : 0;
  sound.playClick();
  renderRoutinePlayerModal();
}

function renderRoutinePlayerModal() {
  const list = state.activeHabits.filter(h => h.timeOfDay === state.routineBucket);
  if (list.length === 0) {
    closeNativeModal();
    return;
  }
  if (state.routineStepIndex >= list.length) {
    sound.playSuccess();
    confetti.burst();
    const html =
      '<div style="text-align:center; padding:24px 10px;">' +
        '<div style="font-size:48px; margin-bottom:10px;">🎉</div>' +
        '<h3 style="font-size:20px; font-weight:800; color:var(--app-text-primary); margin-bottom:6px;">Routine Complete!</h3>' +
        '<p style="font-size:13px; color:var(--app-text-secondary); margin-bottom:18px;">You stepped through all ' + list.length + ' habits in your ' + state.routineBucket + ' playlist.</p>' +
        '<button class="submit-habit-btn" style="width:100%;" onclick="closeNativeModal(); renderTodayScreen();">Done</button>' +
      '</div>';
    openNativeModal(html, 'routine');
    return;
  }

  const h = list[state.routineStepIndex];
  let html = '<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">';
  html += '<span style="font-size:11.5px; font-weight:800; color:var(--app-accent-blue); text-transform:uppercase;">▶ ' + state.routineBucket + ' Routine • Step ' + (state.routineStepIndex + 1) + ' of ' + list.length + '</span>';
  html += '<button class="mini-pill-btn" onclick="closeNativeModal()">Close</button></div>';

  html += '<div style="background:var(--app-card-bg); border:1px solid var(--app-card-border); border-radius:20px; padding:22px 16px; text-align:center; margin-bottom:14px;">';
  html += '<div style="width:64px; height:64px; border-radius:18px; background:' + h.color + '; margin:0 auto 12px; display:flex; align-items:center; justify-content:center;">' + getIconSvg(h.icon, '#FFFFFF', 30) + '</div>';
  html += '<h3 style="font-size:19px; font-weight:800; color:var(--app-text-primary); margin-bottom:4px;">' + escapeHtml(h.name) + '</h3>';
  html += '<p style="font-size:12.5px; color:var(--app-text-secondary);">' + escapeHtml(h.repeatLabel) + ' • 🔥 ' + (h.streak || 0) + 'd streak</p>';
  html += '</div>';

  html += '<div style="display:grid; grid-template-columns:1fr 2fr; gap:10px;">';
  html += '<button class="mini-pill-btn" style="padding:12px;" onclick="routineSkipStep()">⏭️ Skip</button>';
  html += '<button class="submit-habit-btn" style="margin:0; background:' + h.color + ';" onclick="routineCompleteStep()">✓ Complete & Next</button>';
  html += '</div>';

  openNativeModal(html, 'routine');
}

function routineCompleteStep() {
  const list = state.activeHabits.filter(h => h.timeOfDay === state.routineBucket);
  const h = list[state.routineStepIndex];
  if (h) {
    const rec = state.ensureDayRecord(h, state.selectedDay);
    if (!rec.done) state.toggleBinaryHabit(h.id, state.selectedDay);
  }
  sound.playClick();
  state.routineStepIndex += 1;
  renderTodayScreen();
  renderRoutinePlayerModal();
}

function routineSkipStep() {
  const list = state.activeHabits.filter(h => h.timeOfDay === state.routineBucket);
  const h = list[state.routineStepIndex];
  if (h) state.toggleSkipHabit(h.id, state.selectedDay);
  sound.playClick();
  state.routineStepIndex += 1;
  renderTodayScreen();
  renderRoutinePlayerModal();
}

// Mood & Reflection Journal Modal
let activeJournalHabitId = null;
let activeJournalDateKey = null;
let activeJournalMood = null;

function openJournalModal(habitId, dateKey) {
  const habit = state.habits.find(h => h.id === habitId);
  if (!habit) return;
  activeJournalHabitId = habitId;
  activeJournalDateKey = dateKey;
  const rec = (habit.history && habit.history[dateKey]) || {};
  activeJournalMood = rec.mood || null;
  renderJournalModalContent(rec.note || '');
}

function renderJournalModalContent(existingNote) {
  const habit = state.habits.find(h => h.id === activeJournalHabitId);
  if (!habit) return;
  let html = '<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;">';
  html += '<strong style="font-size:15px; color:var(--app-text-primary);">Reflection • ' + activeJournalDateKey + '</strong>';
  html += '<button class="mini-pill-btn" onclick="closeNativeModal()">Cancel</button></div>';

  html += '<div style="font-size:11.5px; font-weight:700; color:var(--app-text-secondary);">HOW DID IT FEEL?</div>';
  html += '<div class="mood-grid">';
  Object.keys(MOOD_META).forEach(k => {
    const m = MOOD_META[k];
    html += '<div class="mood-pill ' + (activeJournalMood === k ? 'selected' : '') + '" onclick="selectJournalMood(\\'' + k + '\\')">';
    html += '<div style="font-size:20px;">' + m.emoji + '</div><div>' + m.label + '</div></div>';
  });
  html += '</div>';

  html += '<textarea id="journal-note-textarea" class="form-input" rows="4" placeholder="What helped or got in the way on this day?" style="width:100%; resize:none; margin-bottom:12px;">' + escapeHtml(existingNote) + '</textarea>';
  html += '<button class="submit-habit-btn" style="width:100%; margin:0;" onclick="commitJournalModal()">Save Reflection</button>';
  openNativeModal(html, 'journal');
}

function selectJournalMood(m) {
  const ta = document.getElementById('journal-note-textarea');
  const note = ta ? ta.value : '';
  activeJournalMood = (activeJournalMood === m) ? null : m;
  sound.playClick();
  renderJournalModalContent(note);
}

function commitJournalModal() {
  const ta = document.getElementById('journal-note-textarea');
  const note = ta ? ta.value.trim() : '';
  state.saveJournalEntry(activeJournalHabitId, activeJournalDateKey, note, activeJournalMood);
  sound.playSuccess();
  closeNativeModal();
  renderTodayScreen();
  if (state.activeScreen === 'details' && state.selectedHabitId === activeJournalHabitId) {
    renderHabitDetails(activeJournalHabitId);
  }
  showToast('Reflection saved 📖');
}

// Graphical Calendar Jump Modal
function openCalendarJumpModal() {
  sound.playClick();
  const base = parseISODateKey(state.selectedDay);
  const year = base.getFullYear();
  const month = base.getMonth();
  const monthNames = ['January','February','March','April','May','June','July','August','September','October','November','December'];
  const daysInMonth = new Date(year, month + 1, 0).getDate();

  let html = '<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">';
  html += '<strong style="font-size:16px; color:var(--app-text-primary);">🗓️ ' + monthNames[month] + ' ' + year + '</strong>';
  html += '<button class="mini-pill-btn primary" onclick="closeNativeModal(); refocusToToday();">↩ Today</button></div>';

  html += '<div style="display:grid; grid-template-columns:repeat(7,1fr); gap:6px; text-align:center;">';
  ['S','M','T','W','T','F','S'].forEach(l => {
    html += '<div style="font-size:10px; font-weight:800; color:var(--app-text-muted);">' + l + '</div>';
  });
  const firstDow = new Date(year, month, 1).getDay();
  for (let i = 0; i < firstDow; i++) html += '<div></div>';
  for (let d = 1; d <= daysInMonth; d++) {
    const key = year + '-' + String(month + 1).padStart(2, '0') + '-' + String(d).padStart(2, '0');
    const isSel = key === state.selectedDay;
    const pct = state.getCompletionRate(key);
    const bg = isSel ? '#007AFF' : (pct === 100 ? 'rgba(48,209,88,0.28)' : 'var(--app-input-bg)');
    const fg = isSel ? '#FFFFFF' : 'var(--app-text-primary)';
    html += '<button style="border:none; border-radius:10px; height:36px; font-size:12.5px; font-weight:700; cursor:pointer; background:' + bg + '; color:' + fg + ';" onclick="selectDay(\\'' + key + '\\'); closeNativeModal();">' + d + '</button>';
  }
  html += '</div>';
  openNativeModal(html, 'calendar');
}

// ============================================================================
// RESPONSIVE DUE TASKS SCREEN WIDGET & CIRCLES ORBIT
// ============================================================================

function renderHeroCirclesOrbit(dueHabits) {
  const container = document.getElementById('hero-circles-orbit');
  if (!container) return;

  if (!dueHabits || dueHabits.length === 0) {
    container.style.display = 'none';
    return;
  }
  container.style.display = 'flex';

  const routines = [
    { key: 'morning', label: 'Morning', icon: '☀️', color: '#FF9500' },
    { key: 'afternoon', label: 'Afternoon', icon: '🌤️', color: '#FF7450' },
    { key: 'evening', label: 'Evening', icon: '🌙', color: '#5856D6' },
    { key: 'anytime', label: 'Anytime', icon: '⏰', color: '#007AFF' }
  ];

  let html = '';

  // 1. Routine Circles
  routines.forEach(rt => {
    const list = dueHabits.filter(h => h.timeOfDay === rt.key);
    if (list.length === 0) return;
    const done = list.filter(h => {
      const rec = h.history && h.history[state.selectedDay];
      return rec && (rec.done || rec.skipped || rec.usedShield);
    }).length;
    const pct = Math.round((done / list.length) * 100);
    const circ = 2 * Math.PI * 18; // ~113.1
    const offset = circ - (circ * pct) / 100;
    const isAllDone = done === list.length;

    html +=
      '<button type="button" class="orbit-circle-btn" onclick="event.stopPropagation(); openDueTasksPopup(&apos;' + rt.key + '&apos;)" title="' + rt.label + ' Routine (' + done + '/' + list.length + ')">' +
        '<div class="orbit-ring-box">' +
          '<svg class="orbit-svg" viewBox="0 0 44 44">' +
            '<circle class="orbit-ring-bg" cx="22" cy="22" r="18"/>' +
            '<circle class="orbit-ring-val" cx="22" cy="22" r="18" style="stroke:' + (isAllDone ? '#34C759' : rt.color) + '; stroke-dasharray:' + circ + '; stroke-dashoffset:' + offset + ';"/>' +
          '</svg>' +
          '<span class="orbit-icon-center">' + (isAllDone ? '✓' : rt.icon) + '</span>' +
        '</div>' +
        '<span class="orbit-circle-title">' + rt.label + '</span>' +
        '<span class="orbit-circle-sub" style="color:' + (isAllDone ? '#34C759' : 'inherit') + ';">' + done + '/' + list.length + '</span>' +
      '</button>';
  });

  html += '<div class="orbit-divider"></div>';

  // 2. Individual Due Habit Circle Avatars
  dueHabits.forEach(habit => {
    const rec = habit.history && habit.history[state.selectedDay];
    const isDone = !!(rec && rec.done);
    const isSkipped = !!(rec && rec.skipped);
    const circ = 2 * Math.PI * 18;
    const progress = isDone ? 1.0 : (isSkipped ? 1.0 : (habit.type === 'amount' && habit.targetAmount > 0 ? Math.min(1.0, (rec ? (rec.amount || 0) : 0) / habit.targetAmount) : 0.0));
    const offset = circ - (circ * progress);

    html +=
      '<button type="button" class="orbit-circle-btn" onclick="event.stopPropagation(); openDueTasksPopup(' + habit.id + ')" title="' + escapeHtml(habit.name) + '">' +
        '<div class="orbit-ring-box">' +
          '<svg class="orbit-svg" viewBox="0 0 44 44">' +
            '<circle class="orbit-ring-bg" cx="22" cy="22" r="18"/>' +
            '<circle class="orbit-ring-val" cx="22" cy="22" r="18" style="stroke:' + (isDone ? '#34C759' : (habit.color || '#007AFF')) + '; stroke-dasharray:' + circ + '; stroke-dashoffset:' + offset + ';"/>' +
          '</svg>' +
          '<span class="orbit-icon-center" style="font-size:12px;">' + (isDone ? '✓' : getIconSvg(habit.icon, habit.color || '#007AFF', 16)) + '</span>' +
        '</div>' +
        '<span class="orbit-circle-title">' + escapeHtml(habit.name) + '</span>' +
        '<span class="orbit-circle-sub" style="color:' + (isDone ? '#34C759' : (isSkipped ? '#32ADE6' : 'inherit')) + ';">' + (isDone ? 'Done' : (isSkipped ? 'Skip' : (habit.repeatLabel || 'Due'))) + '</span>' +
      '</button>';
  });

  container.innerHTML = html;
}

function openDueTasksPopup(filterTarget) {
  sound.playClick();
  const due = state.activeHabits.filter(h => state.isHabitDueOnDate(h, state.selectedDay));
  let list = due;
  let title = "Today's Due Tasks";
  let icon = '📋';
  let badgeColor = '#007AFF';

  if (filterTarget === 'morning') {
    list = due.filter(h => h.timeOfDay === 'morning');
    title = 'Morning Routine Tasks';
    icon = '☀️';
    badgeColor = '#FF9500';
  } else if (filterTarget === 'afternoon') {
    list = due.filter(h => h.timeOfDay === 'afternoon');
    title = 'Afternoon Routine Tasks';
    icon = '🌤️';
    badgeColor = '#FF7450';
  } else if (filterTarget === 'evening') {
    list = due.filter(h => h.timeOfDay === 'evening');
    title = 'Evening Routine Tasks';
    icon = '🌙';
    badgeColor = '#5856D6';
  } else if (filterTarget === 'anytime') {
    list = due.filter(h => h.timeOfDay === 'anytime');
    title = 'Anytime Tasks';
    icon = '⏰';
    badgeColor = '#007AFF';
  } else if (typeof filterTarget === 'number') {
    const single = state.habits.find(h => h.id === filterTarget);
    if (single) {
      list = [single];
      title = single.name;
      icon = '✨';
      badgeColor = single.color || '#007AFF';
    }
  }

  const doneCount = list.filter(h => {
    const rec = h.history && h.history[state.selectedDay];
    return rec && (rec.done || rec.skipped || rec.usedShield);
  }).length;
  const pct = list.length > 0 ? Math.round((doneCount / list.length) * 100) : 0;

  let html = '<div class="due-popup-container">';
  html += '<div class="due-popup-header-card">' +
    '<div class="due-popup-icon" style="background:' + badgeColor + ';">' + icon + '</div>' +
    '<div class="due-popup-header-info">' +
      '<h4>' + escapeHtml(title) + '</h4>' +
      '<p>' + doneCount + ' of ' + list.length + ' completed • ' + pct + '%</p>' +
      '<div class="due-popup-bar-track">' +
        '<div class="due-popup-bar-fill" style="width:' + pct + '%; background:' + (pct === 100 ? '#34C759' : badgeColor) + ';"></div>' +
      '</div>' +
    '</div>' +
  '</div>';

  html += '<div class="due-popup-list">';
  if (list.length === 0) {
    html += '<p style="text-align:center; color:var(--app-text-muted); padding:20px;">No scheduled tasks for this filter.</p>';
  } else {
    list.forEach(h => {
      const rec = h.history && h.history[state.selectedDay];
      const isDone = !!(rec && rec.done);
      html +=
        '<div class="due-popup-row">' +
          '<div class="due-popup-row-left">' +
            '<div class="due-popup-row-icon" style="background:' + (h.color || '#007AFF') + ';">' + getIconSvg(h.icon, '#FFFFFF', 16) + '</div>' +
            '<div class="due-popup-row-info">' +
              '<h5 style="' + (isDone ? 'text-decoration:line-through; opacity:0.6;' : '') + '">' + escapeHtml(h.name) + '</h5>' +
              '<span>' + escapeHtml(h.timeOfDay || 'anytime') + ' • ' + (h.repeatLabel || 'Every day') + '</span>' +
            '</div>' +
          '</div>' +
          '<button type="button" class="due-popup-check-btn ' + (isDone ? 'done' : '') + '" onclick="toggleHabitFromPopup(' + h.id + ', &apos;' + (typeof filterTarget === 'string' ? filterTarget : 'all') + '&apos;)">' +
            (isDone ? '✓' : '') +
          '</button>' +
        '</div>';
    });
  }
  html += '</div>';

  html += '<div class="due-popup-actions">';
  if (doneCount < list.length) {
    html += '<button type="button" class="due-popup-btn-complete" onclick="completeAllFromPopup(&apos;' + (typeof filterTarget === 'string' ? filterTarget : 'all') + '&apos;)">Complete All</button>';
  }
  html += '<button type="button" class="due-popup-btn-close" onclick="closeNativeModal()">Done</button>';
  html += '</div>';
  html += '</div>';

  openNativeModal(html, 'due_popup');
}

function toggleHabitFromPopup(habitId, filterTarget) {
  state.toggleHabit(habitId, state.selectedDay);
  sound.playClick();
  renderTodayScreen();
  openDueTasksPopup(filterTarget);
}

function completeAllFromPopup(filterTarget) {
  const due = state.activeHabits.filter(h => state.isHabitDueOnDate(h, state.selectedDay));
  let list = due;
  if (['morning', 'afternoon', 'evening', 'anytime'].includes(filterTarget)) {
    list = due.filter(h => h.timeOfDay === filterTarget);
  }
  list.forEach(h => {
    const rec = h.history && h.history[state.selectedDay];
    if (!rec || !rec.done) {
      state.toggleHabit(h.id, state.selectedDay);
    }
  });
  sound.playSuccess();
  confetti.burst();
  renderTodayScreen();
  openDueTasksPopup(filterTarget);
}

// ============================================================================
// iOS LOCK SCREEN SYSTEM WIDGETS ENGINE (SIMPLIFIED DAILY FOCUS & POPUP)
// ============================================================================

function updateLockScreenWidgets() {
  const overlay = document.getElementById('ios-lockscreen-overlay');
  if (!overlay) return;

  const due = state.activeHabits.filter(h => state.isHabitDueOnDate(h, state.selectedDay));
  const doneHabits = due.filter(h => {
    const rec = h.history && h.history[state.selectedDay];
    return rec && (rec.done || rec.skipped || rec.usedShield);
  });
  const total = due.length;
  const done = doneHabits.length;
  const pct = total > 0 ? Math.round((done / total) * 100) : 0;
  const streak = state.activeHabits.reduce((max, h) => Math.max(max, h.streak || 0), 0);

  // 1. Clock & Date
  const now = new Date();
  const hrs = String(now.getHours()).padStart(2, '0');
  const mins = String(now.getMinutes()).padStart(2, '0');
  const clockEl = document.getElementById('lockscreen-clock');
  if (clockEl) clockEl.textContent = hrs + ':' + mins;

  const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const dateEl = document.getElementById('lockscreen-date');
  if (dateEl) dateEl.textContent = days[now.getDay()] + ', ' + months[now.getMonth()] + ' ' + now.getDate();

  // 2. Inline Widget (.accessoryInline)
  const inlineEl = document.getElementById('lockscreen-inline-widget');
  if (inlineEl) {
    inlineEl.textContent = '🔥 ' + streak + 'd • ' + done + ' of ' + total + ' habits done (' + pct + '%)';
  }

  // 3. Period Circles Card Row (Fills area like a card, showing only periods containing tasks today)
  const circlesRow = document.getElementById('ls-focus-circles-row');
  if (circlesRow) {
    const circ = 2 * Math.PI * 20; // ~125.66 for r=20 in 48x48 box

    const routines = [
      { key: 'morning', label: 'Morning', icon: '🌅', color: '#FF9500' },
      { key: 'afternoon', label: 'Afternoon', icon: '☀️', color: '#FF7450' },
      { key: 'evening', label: 'Evening', icon: '🌙', color: '#5856D6' },
      { key: 'anytime', label: 'Anytime', icon: '⏰', color: '#007AFF' }
    ];

    // ONLY show the periods chosen that contain tasks on this day!
    const activeRoutines = routines.filter(rt => {
      return due.some(h => (h.timeOfDay || 'anytime') === rt.key);
    });

    let circlesHtml = '';

    if (activeRoutines.length === 0) {
      circlesHtml = '<div style="color:rgba(255,255,255,0.7); font-size:12px; font-weight:600; padding:12px; text-align:center;">No scheduled tasks for this day</div>';
    } else {
      activeRoutines.forEach(rt => {
        const list = due.filter(h => (h.timeOfDay || 'anytime') === rt.key);
        const rtDone = list.filter(h => {
          const rec = h.history && h.history[state.selectedDay];
          return rec && (rec.done || rec.skipped || rec.usedShield);
        }).length;
        const rtPct = Math.round((rtDone / list.length) * 100);
        const rtOffset = circ - (circ * rtPct) / 100;
        const rtAllDone = rtDone === list.length;

        circlesHtml +=
          '<button type="button" class="ls-circle-item" onclick="showCircleDetailPopup(&apos;' + rt.key + '&apos;, event)" title="' + rt.label + ' (' + rtDone + '/' + list.length + ')">' +
            '<div class="ls-circle-ring-box">' +
              '<svg class="ls-circle-svg" viewBox="0 0 48 48">' +
                '<circle class="ls-circle-bg" cx="24" cy="24" r="20"/>' +
                '<circle class="ls-circle-val" cx="24" cy="24" r="20" style="stroke:' + (rtAllDone ? '#34C759' : rt.color) + '; stroke-dasharray:' + circ + '; stroke-dashoffset:' + rtOffset + ';"/>' +
              '</svg>' +
              '<span class="ls-circle-center">' + (rtAllDone ? '✓' : rt.icon) + '</span>' +
            '</div>' +
            '<span class="ls-circle-label">' + rt.label + '</span>' +
            '<span class="ls-circle-sub" style="color:' + (rtAllDone ? '#34C759' : 'inherit') + ';">' + rtDone + '/' + list.length + '</span>' +
          '</button>';
      });
    }

    circlesRow.innerHTML = circlesHtml;
  }
}

// MARK: - Lock Screen Circle Details Elaboration Modal Popup

function showCircleDetailPopup(filterTarget, event) {
  if (event) event.stopPropagation();
  sound.playClick();

  const backdrop = document.getElementById('ls-detail-popup-backdrop');
  const card = document.getElementById('ls-detail-popup-card');
  if (!backdrop || !card) return;

  const due = state.activeHabits.filter(h => state.isHabitDueOnDate(h, state.selectedDay));
  let list = due;
  let title = "Daily Focus Details";
  let icon = "📋";
  let themeColor = "#007AFF";
  let desc = "";

  if (filterTarget === 'morning') {
    list = due.filter(h => h.timeOfDay === 'morning');
    title = 'Morning Routine Details';
    icon = '🌅';
    themeColor = '#FF9500';
  } else if (filterTarget === 'afternoon') {
    list = due.filter(h => h.timeOfDay === 'afternoon');
    title = 'Afternoon Routine Details';
    icon = '☀️';
    themeColor = '#FF7450';
  } else if (filterTarget === 'evening') {
    list = due.filter(h => h.timeOfDay === 'evening');
    title = 'Evening Routine Details';
    icon = '🌙';
    themeColor = '#5856D6';
  } else if (filterTarget === 'anytime') {
    list = due.filter(h => h.timeOfDay === 'anytime');
    title = 'Anytime Tasks Details';
    icon = '⏰';
    themeColor = '#007AFF';
  } else if (typeof filterTarget === 'number') {
    const single = state.habits.find(h => h.id === filterTarget);
    if (single) {
      list = [single];
      title = single.name + ' Details';
      icon = '✨';
      themeColor = single.color || '#007AFF';
    }
  }

  const doneCount = list.filter(h => {
    const rec = h.history && h.history[state.selectedDay];
    return rec && (rec.done || rec.skipped || rec.usedShield);
  }).length;
  const pct = list.length > 0 ? Math.round((doneCount / list.length) * 100) : 0;
  desc = doneCount + ' of ' + list.length + ' completed • ' + pct + '% accomplished';

  let html =
    '<div class="ls-popup-header">' +
      '<div class="ls-popup-icon" style="background:' + themeColor + ';">' + icon + '</div>' +
      '<div class="ls-popup-title-group">' +
        '<h4 class="ls-popup-title">' + escapeHtml(title) + '</h4>' +
        '<p class="ls-popup-desc">' + escapeHtml(desc) + '</p>' +
      '</div>' +
    '</div>' +
    '<div class="ls-popup-progress-track">' +
      '<div class="ls-popup-progress-fill" style="width:' + pct + '%; background:' + (pct === 100 ? '#34C759' : themeColor) + ';"></div>' +
    '</div>' +
    '<div class="ls-popup-items-list">';

  if (list.length === 0) {
    html += '<p style="text-align:center; color:rgba(255,255,255,0.6); padding:20px;">No scheduled tasks for this filter.</p>';
  } else {
    list.forEach(h => {
      const rec = h.history && h.history[state.selectedDay];
      const isDone = !!(rec && rec.done);
      const isSkipped = !!(rec && rec.skipped);

      let subDetail = escapeHtml(h.timeOfDay || 'anytime') + ' • ' + (h.repeatLabel || 'Every day');
      if (h.subtasks && h.subtasks.length > 0) {
        const completedSub = (rec && rec.completedSubtaskIds) ? rec.completedSubtaskIds.length : 0;
        subDetail += ' • ' + completedSub + '/' + h.subtasks.length + ' steps';
      }
      if (h.type === 'amount' && h.targetAmount > 0) {
        const amt = rec ? (rec.amount || 0) : 0;
        subDetail += ' • ' + amt + '/' + h.targetAmount + ' ' + (h.unit || '');
      }

      const argFilter = typeof filterTarget === 'string' ? filterTarget : 'all';

      html +=
        '<div class="ls-popup-item">' +
          '<div class="ls-popup-item-left">' +
            '<div class="ls-popup-item-icon" style="background:' + (h.color || '#007AFF') + ';">' +
              getIconSvg(h.icon, '#FFFFFF', 16) +
            '</div>' +
            '<div class="ls-popup-item-info">' +
              '<h6 style="' + (isDone ? 'text-decoration:line-through; opacity:0.6;' : '') + '">' + escapeHtml(h.name) + '</h6>' +
              '<span>' + subDetail + '</span>' +
            '</div>' +
          '</div>' +
          '<button type="button" class="ls-popup-check ' + (isDone ? 'done' : '') + '" onclick="toggleHabitFromLsPopup(' + h.id + ', &apos;' + argFilter + '&apos;)">' +
            (isDone ? '✓' : '') +
          '</button>' +
        '</div>';
    });
  }

  html += '</div>';

  html +=
    '<div class="ls-popup-actions">';
  if (doneCount < list.length) {
    const argFilter = typeof filterTarget === 'string' ? filterTarget : 'all';
    html += '<button type="button" class="ls-popup-btn primary" onclick="completeAllFromLsPopup(&apos;' + argFilter + '&apos;)">Complete All</button>';
  }
  html +=
      '<button type="button" class="ls-popup-btn secondary" onclick="unlockAndOpenDueTasks(&apos;' + (typeof filterTarget === 'string' ? filterTarget : 'all') + '&apos;)">Open in App</button>' +
      '<button type="button" class="ls-popup-btn secondary" onclick="closeLockscreenDetailPopup()">Done</button>' +
    '</div>';

  card.innerHTML = html;
  backdrop.style.display = 'flex';
}

function closeLockscreenDetailPopup() {
  const backdrop = document.getElementById('ls-detail-popup-backdrop');
  if (backdrop) backdrop.style.display = 'none';
}

function toggleHabitFromLsPopup(habitId, filterTarget) {
  state.toggleHabit(habitId, state.selectedDay);
  sound.playClick();
  updateLockScreenWidgets();
  renderTodayScreen();
  showCircleDetailPopup(filterTarget);
}

function completeAllFromLsPopup(filterTarget) {
  const due = state.activeHabits.filter(h => state.isHabitDueOnDate(h, state.selectedDay));
  let list = due;
  if (['morning', 'afternoon', 'evening', 'anytime'].includes(filterTarget)) {
    list = due.filter(h => h.timeOfDay === filterTarget);
  }
  list.forEach(h => {
    const rec = h.history && h.history[state.selectedDay];
    if (!rec || !rec.done) {
      state.toggleHabit(h.id, state.selectedDay);
    }
  });
  sound.playSuccess();
  confetti.burst();
  updateLockScreenWidgets();
  renderTodayScreen();
  showCircleDetailPopup(filterTarget);
}

function toggleLockScreen() {
  sound.playClick();
  const overlay = document.getElementById('ios-lockscreen-overlay');
  const btn = document.getElementById('tool-lockscreen-btn');
  if (!overlay) return;

  if (overlay.style.display === 'none' || !overlay.style.display) {
    closeLockscreenDetailPopup();
    updateLockScreenWidgets();
    overlay.style.display = 'flex';
    if (btn) btn.style.background = 'rgba(255, 255, 255, 0.25)';
  } else {
    closeLockscreenDetailPopup();
    overlay.style.display = 'none';
    if (btn) btn.style.background = '';
  }
}

function unlockAndOpenDueTasks(filterTarget) {
  sound.playSuccess();
  closeLockscreenDetailPopup();
  const overlay = document.getElementById('ios-lockscreen-overlay');
  const btn = document.getElementById('tool-lockscreen-btn');
  if (overlay) overlay.style.display = 'none';
  if (btn) btn.style.background = '';
  setTimeout(function() {
    openDueTasksPopup(filterTarget || 'all');
  }, 100);
}

window.updateLockScreenWidgets = updateLockScreenWidgets;
window.showCircleDetailPopup = showCircleDetailPopup;
window.closeLockscreenDetailPopup = closeLockscreenDetailPopup;
window.toggleHabitFromLsPopup = toggleHabitFromLsPopup;
window.completeAllFromLsPopup = completeAllFromLsPopup;
window.toggleLockScreen = toggleLockScreen;
window.unlockAndOpenDueTasks = unlockAndOpenDueTasks;

// ============================================================================
// DETAILS, INSIGHTS (SWIFT CHARTS) & CHALLENGES SCREENS
// ============================================================================

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
  const calEl = document.getElementById('details-cal-grid');
  const checkinBtn = document.getElementById('details-checkin-btn');

  if (iconEl) {
    iconEl.style.background = habit.color;
    iconEl.innerHTML = getIconSvg(habit.icon, '#FFFFFF', 34);
  }
  if (titleEl) titleEl.textContent = habit.name;
  if (subEl) subEl.textContent = habit.repeatLabel + ' • ' + habit.timeOfDay.toUpperCase() + ' • ' + habit.strictness.toUpperCase();
  if (curStreakEl) curStreakEl.textContent = (habit.streak || 0) + 'd';
  if (bestStreakEl) bestStreakEl.textContent = (habit.bestStreak || 0) + 'd';
  if (totalLogsEl) totalLogsEl.textContent = String(habit.totalLogs || 0);

  const todayDone = habit.history && habit.history[state.todayKey] && habit.history[state.todayKey].done;
  if (checkinBtn) checkinBtn.textContent = todayDone ? '✓ Completed Today' : '⚡ Check In Today';

  // Real 28-Day Calendar Grid
  let satisfied28 = 0;
  let calHtml = '';
  for (let offset = -27; offset <= 0; offset++) {
    const key = addDaysToKey(state.todayKey, offset);
    const dNum = parseISODateKey(key).getDate();
    const rec = (habit.history && habit.history[key]) || {};
    if (rec.done || rec.skipped || rec.usedShield) satisfied28++;
    const moodEmoji = rec.mood && MOOD_META[rec.mood] ? MOOD_META[rec.mood].emoji : '';
    let cls = 'cal-cell';
    let style = 'cursor:pointer;';
    if (rec.done) cls += ' completed';
    else if (rec.skipped || rec.usedShield) style += 'background:rgba(50,173,230,0.32); color:#fff;';
    if (offset === 0) style += 'outline:2px solid #007AFF;';
    calHtml += '<div class="' + cls + '" style="' + style + '" onclick="openJournalModal(' + habit.id + ', \\'' + key + '\\')" title="' + key + '">' + dNum + (moodEmoji ? '<span style="font-size:8px;">' + moodEmoji + '</span>' : '') + '</div>';
  }
  if (calEl) calEl.innerHTML = calHtml;
  if (rateEl) rateEl.textContent = Math.round((satisfied28 / 28) * 100) + '%';

  // Journal Entries Feed
  const jList = document.getElementById('details-journal-list');
  const jCount = document.getElementById('details-journal-count');
  const entries = Object.entries(habit.history || {})
    .filter(([, r]) => r && ((r.note && r.note.trim()) || r.mood))
    .sort((a, b) => (a[0] < b[0] ? 1 : -1));
  if (jCount) jCount.textContent = entries.length + ' entries';
  if (jList) {
    if (entries.length === 0) {
      jList.innerHTML = '<p style="font-size:12px; color:var(--app-text-muted);">No reflection notes yet. Tap any calendar cell above or "Log Note & Mood".</p>';
    } else {
      jList.innerHTML = entries.map(([k, r]) => {
        const m = r.mood && MOOD_META[r.mood] ? (MOOD_META[r.mood].emoji + ' ' + MOOD_META[r.mood].label) : '';
        return '<div style="padding:8px 0; border-bottom:0.5px solid var(--app-divider);">' +
          '<div style="display:flex; justify-content:space-between; font-size:11px; font-weight:700; color:var(--app-text-secondary);"><span>' + k + '</span><span>' + m + '</span></div>' +
          (r.note ? '<div style="font-size:12.5px; color:var(--app-text-primary); margin-top:3px;">' + escapeHtml(r.note) + '</div>' : '') +
        '</div>';
      }).join('');
    }
  }
}

function toggleCurrentDetailHabit() {
  if (!state.selectedHabitId) return;
  state.toggleBinaryHabit(state.selectedHabitId, state.todayKey);
  sound.playSuccess();
  renderHabitDetails(state.selectedHabitId);
  renderTodayScreen();
}
function openJournalModalForCurrent() {
  if (state.selectedHabitId) openJournalModal(state.selectedHabitId, state.todayKey);
}
function skipCurrentDetailHabit() {
  if (!state.selectedHabitId) return;
  state.toggleSkipHabit(state.selectedHabitId, state.todayKey);
  renderHabitDetails(state.selectedHabitId);
  renderTodayScreen();
  showToast('Updated Skip status ⏭️');
}
function openEditCurrentHabit() {
  if (state.selectedHabitId) openEditHabitSheet(state.selectedHabitId);
}
function duplicateCurrentDetailHabit() {
  if (!state.selectedHabitId) return;
  state.duplicateHabit(state.selectedHabitId);
  renderTodayScreen();
  showToast('Habit duplicated 📋');
}
function archiveCurrentDetailHabit() {
  if (!state.selectedHabitId) return;
  state.toggleArchiveHabit(state.selectedHabitId);
  switchScreen('today');
  renderTodayScreen();
  showToast('Habit archived 📦');
}
function deleteCurrentDetailHabit() {
  if (!state.selectedHabitId) return;
  state.deleteHabit(state.selectedHabitId);
  switchScreen('today');
  renderTodayScreen();
  showToast('Habit deleted 🗑️');
}

function renderInsightsScreen() {
  const container = document.getElementById('insights-content-container');
  if (!container) return;

  const dayLetters = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
  const pts = [];
  for (let offset = -6; offset <= 0; offset++) {
    const k = addDaysToKey(state.todayKey, offset);
    const d = parseISODateKey(k);
    pts.push({ label: dayLetters[d.getDay()], pct: state.getCompletionRate(k) });
  }
  const avg = Math.round(pts.reduce((s, p) => s + p.pct, 0) / 7);
  const totalLogs = state.habits.reduce((s, h) => s + (h.totalLogs || 0), 0);

  // KPI Card
  let html = '<div class="swift-chart-card" style="display:flex; justify-content:space-between; align-items:center;">';
  html += '<div><div style="font-size:11.5px; font-weight:700; color:var(--app-text-secondary);">7-DAY CONSISTENCY</div>';
  html += '<div style="font-size:34px; font-weight:800; color:var(--app-text-primary); line-height:1.1;">' + avg + '%</div>';
  html += '<div style="font-size:11.5px; color:var(--app-text-muted); margin-top:3px;">' + totalLogs + ' lifetime check-ins • ' + state.activeHabits.length + ' active habits</div></div>';
  html += '<div style="font-size:34px;">📊</div></div>';

  // BarMark + RuleMark Chart
  html += '<div class="swift-chart-card">';
  html += '<div class="swift-chart-title"><span>Last 7 Days Adherence</span><span style="color:#007AFF; font-size:11px;">Swift Charts</span></div>';
  html += '<div class="swift-bars-wrap">';
  html += '<div class="swift-avg-line" style="bottom:' + Math.max(18, Math.round(avg * 1.1) + 18) + 'px;"><span class="swift-avg-label">Avg ' + avg + '%</span></div>';
  pts.forEach(p => {
    const hPx = Math.max(5, Math.round((p.pct / 100) * 105));
    html += '<div class="swift-bar-col"><div class="swift-bar-fill" style="height:' + hPx + 'px;" title="' + p.pct + '%"></div><span class="swift-bar-lbl">' + p.label + '</span></div>';
  });
  html += '</div></div>';

  // Time-of-Day Donut Breakdown
  const bucketMeta = [
    { id: 'morning', label: 'Morning', color: '#FF9F0A' },
    { id: 'afternoon', label: 'Afternoon', color: '#FFD60A' },
    { id: 'evening', label: 'Evening', color: '#5E5CE6' },
    { id: 'anytime', label: 'Anytime', color: '#007AFF' }
  ];
  const counts = bucketMeta.map(b => ({
    ...b,
    val: state.habits.filter(h => h.timeOfDay === b.id).reduce((s, h) => s + (h.totalLogs || 0), 0)
  }));
  const sumBucket = Math.max(1, counts.reduce((s, c) => s + c.val, 0));
  let accDeg = 0;
  const stops = counts.map(c => {
    const start = accDeg;
    accDeg += (c.val / sumBucket) * 360;
    return c.color + ' ' + start.toFixed(1) + 'deg ' + accDeg.toFixed(1) + 'deg';
  }).join(', ');

  html += '<div class="swift-chart-card">';
  html += '<div class="swift-chart-title"><span>Time-of-Day Rhythm</span></div>';
  html += '<div style="display:flex; align-items:center; gap:18px;">';
  html += '<div style="width:96px; height:96px; border-radius:50%; background:' + (totalLogs > 0 ? ('conic-gradient(' + stops + ')') : 'var(--app-input-bg)') + '; display:flex; align-items:center; justify-content:center; flex-shrink:0;">';
  html += '<div style="width:56px; height:56px; border-radius:50%; background:var(--app-card-bg); display:flex; align-items:center; justify-content:center; font-size:12px; font-weight:800; color:var(--app-text-primary);">' + totalLogs + '</div></div>';
  html += '<div style="flex:1; display:flex; flex-direction:column; gap:6px;">';
  counts.forEach(c => {
    html += '<div style="display:flex; justify-content:space-between; font-size:12px;"><span style="color:var(--app-text-secondary);"><span style="color:' + c.color + ';">●</span> ' + c.label + '</span><strong style="color:var(--app-text-primary);">' + c.val + '</strong></div>';
  });
  html += '</div></div></div>';

  // 84-Day Activity Heatmap
  html += '<div class="swift-chart-card">';
  html += '<div class="swift-chart-title"><span>12-Week Activity Heatmap</span></div>';
  html += '<div class="heatmap-84-grid">';
  for (let offset = -83; offset <= 0; offset++) {
    const k = addDaysToKey(state.todayKey, offset);
    const pct = state.getCompletionRate(k);
    const bg = pct === 0 ? 'var(--app-input-bg)' : (pct < 50 ? 'rgba(48,209,88,0.35)' : (pct < 90 ? 'rgba(48,209,88,0.68)' : '#30D158'));
    html += '<div class="heat-cell" style="background:' + bg + ';" title="' + k + ': ' + pct + '%"></div>';
  }
  html += '</div></div>';

  // Top Streaks Leaderboard
  const topHabits = state.activeHabits.slice().sort((a, b) => (b.streak || 0) - (a.streak || 0)).slice(0, 5);
  html += '<div class="swift-chart-card" style="margin-bottom:24px;">';
  html += '<div class="swift-chart-title"><span>Streak Leaderboard</span></div>';
  if (topHabits.length === 0) {
    html += '<div style="font-size:12px; color:var(--app-text-muted);">Add habits to track streaks.</div>';
  } else {
    topHabits.forEach(h => {
      html += '<div style="display:flex; justify-content:space-between; align-items:center; padding:7px 0; border-bottom:0.5px solid var(--app-divider);">';
      html += '<span style="font-size:13px; font-weight:700; color:var(--app-text-primary);">' + escapeHtml(h.name) + '</span>';
      html += '<span style="font-size:12px; font-weight:800; color:#FF9F0A;">🔥 ' + (h.streak || 0) + 'd</span></div>';
    });
  }
  html += '</div>';

  container.innerHTML = html;
}

function renderChallengesScreen() {
  const container = document.getElementById('challenges-content-container');
  if (!container) return;

  let html = '';
  const joined = state.challenges.filter(c => c.isJoined);
  const avail = state.challenges.filter(c => !c.isJoined);

  if (joined.length > 0) {
    html += '<div class="settings-section-title">ACTIVE CHALLENGES</div>';
    joined.forEach(ch => {
      const doneDays = state.getChallengeProgress(ch);
      const pct = Math.min(100, Math.round((doneDays / ch.durationDays) * 100));
      html += '<div class="challenge-card">';
      html += '<div style="display:flex; justify-content:space-between; align-items:center; gap:10px; margin-bottom:8px;">';
      html += '<div style="display:flex; align-items:center; gap:10px; flex:1; min-width:0;"><span style="font-size:22px; flex-shrink:0;">' + ch.emoji + '</span><div style="min-width:0; flex:1;"><div style="font-size:14px; font-weight:800; color:var(--app-text-primary);">' + escapeHtml(ch.title) + '</div><div style="font-size:11px; color:var(--app-text-secondary);">Day ' + doneDays + ' of ' + ch.durationDays + ' completed</div></div></div>';
      html += '<button class="mini-pill-btn danger" style="flex-shrink:0;" onclick="onLeaveChallenge(\\'' + ch.id + '\\')">Leave</button></div>';
      html += '<div class="amount-track"><div class="amount-fill" style="width:' + pct + '%; background:' + ch.color + ';"></div></div>';
      html += '</div>';
    });
  }

  html += '<div class="settings-section-title">GUIDED MULTI-DAY PROGRAMS</div>';
  avail.forEach(ch => {
    html += '<div class="challenge-card" style="display:flex; justify-content:space-between; align-items:center; gap:10px;">';
    html += '<div style="display:flex; align-items:center; gap:10px; flex:1; min-width:0;"><div style="width:40px; height:40px; border-radius:12px; background:' + ch.color + '; display:flex; align-items:center; justify-content:center; font-size:20px; flex-shrink:0;">' + ch.emoji + '</div>';
    html += '<div style="min-width:0; flex:1;"><div style="font-size:13.5px; font-weight:800; color:var(--app-text-primary);">' + escapeHtml(ch.title) + '</div><div style="font-size:11px; color:var(--app-text-secondary);">' + escapeHtml(ch.subtitle) + '</div></div></div>';
    html += '<button class="mini-pill-btn primary" style="background:' + ch.color + '; flex-shrink:0; white-space:nowrap;" onclick="onJoinChallenge(\\'' + ch.id + '\\')">Join ' + ch.durationDays + 'd</button>';
    html += '</div>';
  });

  html += '<div class="settings-section-title" style="margin-top:14px;">MILESTONE ACHIEVEMENT BADGES</div>';
  html += '<div class="badges-grid" style="margin-bottom:24px;">';
  state.getAchievementBadges().forEach(b => {
    html += '<div class="badge-tile ' + (b.unlocked ? 'unlocked' : '') + '">';
    html += '<div class="badge-icon-circle" style="background:' + (b.unlocked ? b.color : 'var(--app-input-bg)') + ';">' + b.emoji + '</div>';
    html += '<div style="font-size:12.5px; font-weight:800; color:var(--app-text-primary);">' + b.title + '</div>';
    html += '<div style="font-size:10.5px; color:var(--app-text-muted); margin-top:2px;">' + b.sub + '</div>';
    html += '</div>';
  });
  html += '</div>';

  container.innerHTML = html;
}

function onJoinChallenge(id) {
  state.joinChallenge(id);
  sound.playSuccess();
  confetti.burst();
  renderChallengesScreen();
  renderTodayScreen();
  showToast('Challenge joined! Habit added to Today 🏆');
}

function onLeaveChallenge(id) {
  state.leaveChallenge(id);
  sound.playClick();
  renderChallengesScreen();
}

// ============================================================================
// ADD & EDIT HABIT SHEET + PRESETS SEARCH
// ============================================================================

function openAddHabitSheet() {
  state.editingHabitId = null;
  state.builderSubtasks = [];
  state.customPolarity = 'build';
  state.customTrackingMode = 'binary';
  state.customWeekdays = [1, 2, 3, 4, 5];
  sound.playClick();

  const mainTitle = document.getElementById('sheet-main-title');
  const segNav = document.getElementById('sheet-segmented-nav');
  const submitBtn = document.getElementById('custom-submit-btn');
  const nameIn = document.getElementById('custom-name-input');
  if (mainTitle) mainTitle.textContent = 'New Habit';
  if (segNav) segNav.style.display = 'flex';
  if (submitBtn) submitBtn.textContent = 'Create Habit';
  if (nameIn) nameIn.value = '';

  state.sheetTab = 'presets';
  renderBuilderSubtasks();
  onPolarityChange('build');
  onTrackingModeChange('binary');
  const freqSel = document.getElementById('custom-frequency-select');
  if (freqSel) freqSel.value = 'daily';
  onFrequencySelectChange('daily');
  renderSheetView();
  const bd = document.getElementById('sheet-backdrop');
  if (bd) bd.classList.add('active');
}

function openEditHabitSheet(habitId) {
  const h = state.habits.find(x => x.id === habitId);
  if (!h) return;
  state.editingHabitId = h.id;
  state.sheetTab = 'custom';
  state.builderSubtasks = Array.isArray(h.subtasks) ? h.subtasks.map(s => ({ ...s })) : [];
  state.customWeekdays = Array.isArray(h.customWeekdays) ? h.customWeekdays.slice() : [1, 2, 3, 4, 5];
  sound.playClick();

  const mainTitle = document.getElementById('sheet-main-title');
  const segNav = document.getElementById('sheet-segmented-nav');
  const submitBtn = document.getElementById('custom-submit-btn');
  if (mainTitle) mainTitle.textContent = 'Edit Habit';
  if (segNav) segNav.style.display = 'none';
  if (submitBtn) submitBtn.textContent = 'Save Changes';

  const setVal = (id, v) => { const el = document.getElementById(id); if (el) el.value = v; };
  setVal('custom-name-input', h.name);
  setVal('custom-target-amount', h.targetAmount);
  setVal('custom-unit-select', h.unit);
  setVal('custom-step-amount', h.stepAmount);
  setVal('custom-reps-count', h.targetReps);
  setVal('custom-duration-minutes', h.targetDuration);
  setVal('custom-frequency-select', h.frequency);
  setVal('custom-frequency-target-input', h.frequencyTargetTimes || getPeriodicTargetCount(h));
  setVal('custom-strictness-select', h.strictness);
  setVal('custom-time-select', h.timeOfDay);
  setVal('custom-reminder-time', h.reminderTime || '09:00');
  setVal('custom-color-select', h.color);
  setVal('custom-icon-select', h.icon);

  onPolarityChange(h.polarity || 'build');
  onTrackingModeChange(h.type || 'binary');
  onFrequencySelectChange(h.frequency || 'daily');
  renderBuilderSubtasks();
  renderSheetView();
  const bd = document.getElementById('sheet-backdrop');
  if (bd) bd.classList.add('active');
}

function closeAddHabitSheet() {
  sound.playClick();
  const bd = document.getElementById('sheet-backdrop');
  if (bd) bd.classList.remove('active');
}

function setSheetTab(tabName) {
  state.sheetTab = tabName;
  sound.playClick();
  renderSheetView();
}

function renderSheetView() {
  const presetsView = document.getElementById('sheet-presets-view');
  const customView = document.getElementById('sheet-custom-view');
  const tabPresets = document.getElementById('sheet-tab-presets');
  const tabCustom = document.getElementById('sheet-tab-custom');
  if (!presetsView || !customView) return;

  if (state.sheetTab === 'presets' && !state.editingHabitId) {
    presetsView.style.display = 'block';
    customView.style.display = 'none';
    if (tabPresets) tabPresets.classList.add('active');
    if (tabCustom) tabCustom.classList.remove('active');
    renderSheetPresets();
  } else {
    presetsView.style.display = 'none';
    customView.style.display = 'block';
    if (tabPresets) tabPresets.classList.remove('active');
    if (tabCustom) tabCustom.classList.add('active');
  }
}

function renderSheetPresets() {
  const tabsContainer = document.getElementById('sheet-cat-tabs');
  const presetsContainer = document.getElementById('sheet-presets-list');
  const searchIn = document.getElementById('preset-search-input');
  if (!tabsContainer || !presetsContainer) return;

  const q = searchIn ? searchIn.value.trim().toLowerCase() : '';
  let tabsHtml = '<button class="cat-tab-btn ' + (state.activeCategory === 0 ? 'active' : '') + '" onclick="onSelectSheetCategory(0)">All (83)</button>';
  APP_DATA.categories.forEach(cat => {
    tabsHtml += '<button class="cat-tab-btn ' + (cat.id === state.activeCategory ? 'active' : '') + '" onclick="onSelectSheetCategory(' + cat.id + ')">' + escapeHtml(cat.name) + '</button>';
  });
  tabsContainer.innerHTML = tabsHtml;

  let list = APP_DATA.presets;
  if (state.activeCategory !== 0) {
    list = list.filter(p => p.categoryIds.includes(state.activeCategory));
  }
  if (q) {
    list = list.filter(p => p.name.toLowerCase().includes(q));
  }

  presetsContainer.innerHTML = list.slice(0, 30).map(preset =>
    '<div class="preset-row-item" onclick="onCustomizePreset(' + preset.id + ')">' +
      '<div class="preset-row-left">' +
        '<div class="habit-icon-wrapper" style="width:36px; height:36px; border-radius:10px; background:' + preset.color + ';">' + getIconSvg(preset.icon, '#FFFFFF', 18) + '</div>' +
        '<span>' + escapeHtml(preset.name) + '</span>' +
      '</div>' +
      '<div class="preset-row-actions">' +
        '<span class="preset-customize-hint">Customize</span>' +
        '<button type="button" class="add-preset-btn" onclick="event.stopPropagation(); onAddPresetDirectly(' + preset.id + ')">+ Add</button>' +
      '</div>' +
    '</div>'
  ).join('');
}

function onSelectSheetCategory(catId) {
  sound.playClick();
  state.activeCategory = catId;
  renderSheetPresets();
}

function getPresetConfig(preset) {
  const n = (preset.name || '').toLowerCase();
  let polarity = 'build';
  let type = 'binary';
  let targetAmount = 2000;
  let unit = 'ml';
  let stepAmount = 250;
  let targetReps = 3;
  let targetDuration = 15;

  if (n.includes('zero ') || n.includes('avoid ') || n.includes('no ')) {
    polarity = 'quit';
  } else if (n.includes('limit ')) {
    polarity = 'limit';
    type = 'amount';
    targetAmount = 2;
    unit = 'cups';
    stepAmount = 1;
  } else if (n.includes('water') || n.includes('drink')) {
    type = 'amount'; targetAmount = 2000; unit = 'ml'; stepAmount = 250;
  } else if (n.includes('walk') || n.includes('run')) {
    type = 'amount'; targetAmount = 30; unit = 'mins'; stepAmount = 10;
  } else if (n.includes('read') || n.includes('book')) {
    type = 'amount'; targetAmount = 20; unit = 'pages'; stepAmount = 5;
  } else if (n.includes('vitamin') || n.includes('pill')) {
    type = 'reps'; targetReps = 2;
  } else if (n.includes('meditat') || n.includes('yoga') || n.includes('stretch') || n.includes('exercise') || n.includes('pomodoro')) {
    type = 'timer'; targetDuration = n.includes('10') ? 10 : (n.includes('pomodoro') ? 25 : 15);
  }

  return {
    name: preset.name,
    icon: preset.icon || 'ic_all_habits',
    color: preset.color || '#007AFF',
    timeOfDay: preset.timeOfDay || 'morning',
    polarity,
    type,
    targetAmount,
    unit,
    stepAmount,
    targetReps,
    targetDuration,
    frequency: 'daily',
    repeatLabel: 'Every day',
    strictness: state.defaultStrictness || 'strict'
  };
}

function onAddPresetDirectly(presetId) {
  const preset = APP_DATA.presets.find(p => p.id === presetId);
  if (!preset) return;
  state.addCustomHabit(getPresetConfig(preset));
  sound.playSuccess();
  confetti.burst();
  closeAddHabitSheet();
  renderTodayScreen();
  showToast('Added: ' + preset.name + ' 🔥');
}

function onCustomizePreset(presetId) {
  const preset = APP_DATA.presets.find(p => p.id === presetId);
  if (!preset) return;
  const cfg = getPresetConfig(preset);
  const nameEl = document.getElementById('custom-name-input');
  if (nameEl) nameEl.value = cfg.name;
  onPolarityChange(cfg.polarity);
  onTrackingModeChange(cfg.type);
  const tAmt = document.getElementById('custom-target-amount');
  if (tAmt) tAmt.value = cfg.targetAmount;
  const uSel = document.getElementById('custom-unit-select');
  if (uSel) uSel.value = cfg.unit;
  const sAmt = document.getElementById('custom-step-amount');
  if (sAmt) sAmt.value = cfg.stepAmount;
  setSheetTab('custom');
}

function onPolarityChange(pol) {
  state.customPolarity = pol;
  if (document.querySelectorAll) {
    document.querySelectorAll('.polarity-btn').forEach(b => {
      b.classList.toggle('active', b.dataset.polarity === pol);
    });
  }
  const typeWrap = document.getElementById('form-tracking-type-wrap');
  const amtGroup = document.getElementById('form-amount-group');
  const repsGroup = document.getElementById('form-reps-group');
  const tmrGroup = document.getElementById('form-timer-group');
  const amtLbl = document.getElementById('amount-target-label');

  if (typeWrap) typeWrap.style.display = pol === 'build' ? 'block' : 'none';
  if (pol === 'limit') {
    if (amtGroup) amtGroup.style.display = 'block';
    if (repsGroup) repsGroup.style.display = 'none';
    if (tmrGroup) tmrGroup.style.display = 'none';
    if (amtLbl) amtLbl.textContent = 'STAY AT OR UNDER';
  } else if (pol === 'quit') {
    if (amtGroup) amtGroup.style.display = 'none';
    if (repsGroup) repsGroup.style.display = 'none';
    if (tmrGroup) tmrGroup.style.display = 'none';
  } else {
    if (amtLbl) amtLbl.textContent = 'DAILY TARGET';
    onTrackingModeChange(state.customTrackingMode);
  }
}

function onTrackingModeChange(mode) {
  state.customTrackingMode = mode;
  const amt = document.getElementById('form-amount-group');
  const reps = document.getElementById('form-reps-group');
  const tmr = document.getElementById('form-timer-group');
  if (state.customPolarity === 'build') {
    if (amt) amt.style.display = mode === 'amount' ? 'block' : 'none';
    if (reps) reps.style.display = mode === 'reps' ? 'block' : 'none';
    if (tmr) tmr.style.display = mode === 'timer' ? 'block' : 'none';
  }
  if (document.querySelectorAll) {
    document.querySelectorAll('.mode-chip').forEach(c => {
      c.classList.toggle('selected', c.dataset.mode === mode);
    });
  }
}

function onFrequencySelectChange(val) {
  const picker = document.getElementById('custom-weekdays-picker');
  if (picker) picker.style.display = val === 'custom_days' ? 'grid' : 'none';
  syncWeekdayCirclesUI();

  const targetRow = document.getElementById('custom-frequency-target-row');
  const targetLabel = document.getElementById('custom-frequency-target-label');
  const targetInput = document.getElementById('custom-frequency-target-input');
  const hintEl = document.getElementById('custom-frequency-hint');

  if (val === 'custom_times_per_week') {
    if (targetRow) targetRow.style.display = 'block';
    if (targetLabel) targetLabel.textContent = 'TARGET TIMES PER WEEK';
    if (targetInput) { targetInput.min = '1'; targetInput.max = '6'; if (!targetInput.value || Number(targetInput.value) > 6) targetInput.value = '3'; }
  } else if (val === 'custom_times_per_month') {
    if (targetRow) targetRow.style.display = 'block';
    if (targetLabel) targetLabel.textContent = 'TARGET TIMES PER MONTH';
    if (targetInput) { targetInput.min = '1'; targetInput.max = '28'; if (!targetInput.value || Number(targetInput.value) > 28) targetInput.value = '2'; }
  } else {
    if (targetRow) targetRow.style.display = 'none';
  }

  if (hintEl) {
    hintEl.style.display = isPeriodicFrequency(val) ? 'block' : 'none';
    if (isWeeklyPeriodic(val)) {
      hintEl.textContent = '📅 Flexible schedule: accomplish on any day(s) during the week to fulfill your target goal.';
    } else if (isMonthlyPeriodic(val)) {
      hintEl.textContent = '📅 Flexible schedule: accomplish on any day(s) during the month to fulfill your target goal.';
    }
  }
}

function toggleCustomWeekday(dayNum) {
  const idx = state.customWeekdays.indexOf(dayNum);
  if (idx >= 0 && state.customWeekdays.length > 1) state.customWeekdays.splice(idx, 1);
  else if (idx < 0) state.customWeekdays.push(dayNum);
  sound.playClick();
  syncWeekdayCirclesUI();
}

function syncWeekdayCirclesUI() {
  if (!document.querySelectorAll) return;
  document.querySelectorAll('#custom-weekdays-picker .wd-circle').forEach(btn => {
    const d = Number(btn.dataset.day);
    btn.classList.toggle('active', state.customWeekdays.includes(d));
  });
}

function addBuilderSubtask() {
  const input = document.getElementById('builder-subtask-input');
  if (!input || !input.value.trim()) return;
  state.builderSubtasks.push({ id: 'sub_' + Date.now() + '_' + Math.random().toString(36).slice(2, 6), title: input.value.trim() });
  input.value = '';
  sound.playClick();
  renderBuilderSubtasks();
}

function removeBuilderSubtask(subId) {
  state.builderSubtasks = state.builderSubtasks.filter(s => s.id !== subId);
  renderBuilderSubtasks();
}

function renderBuilderSubtasks() {
  const listEl = document.getElementById('builder-subtasks-list');
  if (!listEl) return;
  listEl.innerHTML = state.builderSubtasks.map(s =>
    '<div style="display:flex; justify-content:space-between; align-items:center; background:var(--app-input-bg); padding:6px 10px; border-radius:8px; font-size:12px;">' +
      '<span>☑️ ' + escapeHtml(s.title) + '</span>' +
      '<button type="button" style="border:none; background:transparent; color:#FF453A; cursor:pointer; font-weight:800;" onclick="removeBuilderSubtask(\\'' + s.id + '\\')">✕</button>' +
    '</div>'
  ).join('');
}

function stepCustomRepsInput(delta) {
  const input = document.getElementById('custom-reps-count');
  if (!input) return;
  sound.playClick();
  input.value = Math.max(1, Math.min(99, (parseInt(input.value, 10) || 1) + delta));
}

// ============================================================================
// SETTINGS, BACKUPS (JSON + CSV), LOCK SCREEN PUSH & DEMO DATA SEEDER
// ============================================================================

function renderSettingsScreen() {
  const ws = document.getElementById('settings-week-start-select');
  const ds = document.getElementById('settings-default-strictness');
  const soundBtn = document.getElementById('settings-sound-toggle-btn');
  const vacBtn = document.getElementById('settings-vacation-btn');
  const shieldsEl = document.getElementById('settings-shields-count');
  const healthBtn = document.getElementById('settings-health-btn');
  const statsEl = document.getElementById('settings-storage-stats');

  if (ws) ws.value = state.weekStartDay;
  if (ds) ds.value = state.defaultStrictness;
  if (soundBtn) {
    soundBtn.textContent = state.soundEnabled ? '🔊 Enabled' : '🔇 Muted';
    soundBtn.classList.toggle('active', state.soundEnabled);
  }
  ['system', 'dark', 'light'].forEach(t => {
    const b = document.getElementById('theme-btn-' + t);
    if (b) b.classList.toggle('active', state.theme === t);
  });
  if (vacBtn) {
    vacBtn.textContent = state.vacationMode ? '🏖️ Active' : 'Off';
    vacBtn.classList.toggle('active', state.vacationMode);
  }
  if (shieldsEl) shieldsEl.textContent = state.streakFreezeShields + ' available';
  if (healthBtn) {
    healthBtn.textContent = state.healthSyncEnabled ? '✓ Active' : 'Connect';
    healthBtn.classList.toggle('active', state.healthSyncEnabled);
  }
  if (statsEl) {
    const totalLogs = state.habits.reduce((s, h) => s + (h.totalLogs || 0), 0);
    statsEl.textContent = 'v3.0 Native • ' + state.activeHabits.length + ' active • ' + totalLogs + ' logs';
  }

  // Archived Habits List
  const archWrap = document.getElementById('settings-archived-wrapper');
  const archList = document.getElementById('settings-archived-list');
  const archived = state.archivedHabits;
  if (archWrap && archList) {
    if (archived.length === 0) {
      archWrap.style.display = 'none';
    } else {
      archWrap.style.display = 'block';
      archList.innerHTML = archived.map(h =>
        '<div class="settings-row">' +
          '<div class="settings-label">' + escapeHtml(h.name) + '</div>' +
          '<button class="mini-pill-btn primary" onclick="restoreArchivedHabit(' + h.id + ')">Restore</button>' +
        '</div>'
      ).join('');
    }
  }
}

function restoreArchivedHabit(id) {
  state.toggleArchiveHabit(id);
  sound.playSuccess();
  renderSettingsScreen();
  renderTodayScreen();
  showToast('Habit restored to Today!');
}

function toggleVacationMode() {
  state.vacationMode = !state.vacationMode;
  state.recalculateAllStreaks();
  state.saveSettings();
  sound.playClick();
  renderTodayScreen();
  renderSettingsScreen();
  showToast(state.vacationMode ? 'Vacation Mode enabled 🏖️' : 'Vacation Mode disabled');
}

function toggleHealthSync() {
  state.healthSyncEnabled = !state.healthSyncEnabled;
  state.saveSettings();
  sound.playSuccess();
  renderSettingsScreen();
  showToast(state.healthSyncEnabled ? 'Apple HealthKit Bridge Active ❤️' : 'HealthKit disconnected');
}

function simulatePushNotification() {
  sound.playHaptic();
  const pending = state.activeHabits.find(h => state.getHabitStatusOnSelectedDay(h, state.todayKey) === 'pending') || state.activeHabits[0];
  state.pushHabitId = pending ? pending.id : null;
  const titleEl = document.getElementById('push-banner-title');
  const bodyEl = document.getElementById('push-banner-body');
  const banner = document.getElementById('ios-push-banner');
  if (titleEl) titleEl.textContent = pending ? ('⏰ ' + pending.name) : '☀️ Daily Habit Check-in';
  if (bodyEl) bodyEl.textContent = pending ? ('Due in your ' + pending.timeOfDay + ' routine • Use Lock Screen quick actions:') : 'Add your first habit or load Demo Data to test quick completion!';
  if (banner) banner.classList.add('active');
}

function dismissPushBanner() {
  const banner = document.getElementById('ios-push-banner');
  if (banner) banner.classList.remove('active');
}

function handlePushAction(act) {
  dismissPushBanner();
  if (act === 'done' && state.pushHabitId) {
    state.toggleBinaryHabit(state.pushHabitId, state.todayKey);
    sound.playSuccess();
    confetti.burst();
    renderTodayScreen();
    showToast('Marked Completed from Notification! ✓');
  } else if (act === 'snooze') {
    sound.playClick();
    showToast('Snoozed reminder for 15 minutes ⏰');
  }
}

function exportUserData() {
  sound.playSuccess();
  const backup = {
    app: 'Productive Native iOS',
    version: '3.0.0',
    exportedAt: new Date().toISOString(),
    theme: state.theme,
    finish: state.finish,
    weekStartDay: state.weekStartDay,
    defaultStrictness: state.defaultStrictness,
    streakFreezeShields: state.streakFreezeShields,
    habits: state.habits,
    challenges: state.challenges
  };
  const blob = new Blob([JSON.stringify(backup, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'Productive_Backup_' + state.todayKey + '.json';
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
  showToast('Shared JSON Backup! 📤');
}

function exportCSVData() {
  sound.playSuccess();
  const rows = ['Habit Name,Polarity,Mode,TimeOfDay,Frequency,Streak,BestStreak,TotalLogs,Date,Completed,Skipped,Amount,Reps,Mood,Note'];
  state.habits.forEach(h => {
    const cleanName = '"' + String(h.name).replace(/"/g, '""') + '"';
    const keys = Object.keys(h.history || {}).sort();
    if (keys.length === 0) {
      rows.push([cleanName, h.polarity, h.type, h.timeOfDay, h.frequency, h.streak, h.bestStreak, h.totalLogs, '', '', '', '', '', '', ''].join(','));
    } else {
      keys.forEach(k => {
        const r = h.history[k] || {};
        const note = '"' + String(r.note || '').replace(/"/g, '""').replace(/\\n/g, ' ') + '"';
        rows.push([cleanName, h.polarity, h.type, h.timeOfDay, h.frequency, h.streak, h.bestStreak, h.totalLogs, k, Boolean(r.done), Boolean(r.skipped), r.amount || 0, r.reps || 0, r.mood || '', note].join(','));
      });
    }
  });
  const blob = new Blob([rows.join('\\n')], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'Productive_Habits_' + state.todayKey + '.csv';
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
  showToast('Exported Spreadsheet (.CSV)! 📊');
}

function importUserData(event) {
  const file = event.target.files && event.target.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = (e) => {
    try {
      const data = JSON.parse(e.target.result);
      const importedHabits = Array.isArray(data) ? data : data.habits;
      if (Array.isArray(importedHabits)) {
        state.habits = importedHabits.map(h => state.normalizeHabit(h));
        if (Array.isArray(data.challenges)) state.challenges = data.challenges;
        state.recalculateAllStreaks();
        state.saveHabits();
        sound.playSuccess();
        confetti.burst();
        renderTodayScreen();
        renderSettingsScreen();
        showToast('Imported ' + state.habits.length + ' habits! 🎉');
      } else {
        showToast('Invalid JSON backup file ⚠️');
      }
    } catch (err) {
      showToast('Could not parse JSON file ⚠️');
    }
  };
  reader.readAsText(file);
  event.target.value = '';
}

function resetToDefaults() {
  if (typeof confirm === 'function' && !confirm('Reset all habits, challenges, and restart onboarding?')) return;
  stopFocusTimer();
  localStorage.removeItem('productive_habits_user_v1');
  localStorage.removeItem('productive_challenges_v1');
  localStorage.removeItem('productive_settings');
  state.habits = [];
  state.challenges = JSON.parse(JSON.stringify(DEFAULT_CHALLENGES));
  state.hasCompletedOnboarding = false;
  state.vacationMode = false;
  state.streakFreezeShields = 2;
  state.saveSettings();
  relaunchOnboarding();
  showToast('Reset complete 🔄');
}

function seedRichDemoData() {
  const t0 = state.todayKey;
  const d1 = addDaysToKey(t0, -1);
  const d2 = addDaysToKey(t0, -2);
  const d3 = addDaysToKey(t0, -3);
  const d4 = addDaysToKey(t0, -4);

  state.hasCompletedOnboarding = true;
  state.habits = [];

  // 1. Amount + Rollover Habit (Yesterday had 1500/2000 -> +500ml rollover today!)
  state.addCustomHabit({
    name: 'Drink Water',
    icon: 'ic_drink',
    color: '#007AFF',
    timeOfDay: 'morning',
    polarity: 'build',
    type: 'amount',
    targetAmount: 2000,
    unit: 'ml',
    stepAmount: 250,
    strictness: 'rollover',
    createdAtKey: d4,
    history: {
      [d3]: { done: true, amount: 2000 },
      [d2]: { done: true, amount: 2000, mood: 'great', note: 'Felt super hydrated after morning walk!' },
      [d1]: { done: false, amount: 1500 },
      [t0]: { done: false, amount: 1250 }
    }
  });

  // 2. Habit with Sub-Checklist Steps
  state.addCustomHabit({
    name: 'Morning Reset & Skincare',
    icon: 'ic_sunny',
    color: '#5700CB',
    timeOfDay: 'morning',
    polarity: 'build',
    type: 'binary',
    strictness: 'strict',
    subtasks: [
      { id: 's1', title: 'Make the bed' },
      { id: 's2', title: 'Cleanser + SPF 50' },
      { id: 's3', title: 'Take daily vitamins' }
    ],
    createdAtKey: d4,
    history: {
      [d3]: { done: true, completedSubtasks: ['s1','s2','s3'] },
      [d2]: { done: true, completedSubtasks: ['s1','s2','s3'] },
      [d1]: { done: true, completedSubtasks: ['s1','s2','s3'] },
      [t0]: { done: false, completedSubtasks: ['s1'] }
    }
  });

  // 3. Real Interactive Focus Timer Habit
  state.addCustomHabit({
    name: 'Deep Focus Reading',
    icon: 'ic_read',
    color: '#FF7450',
    timeOfDay: 'afternoon',
    polarity: 'build',
    type: 'timer',
    targetDuration: 15,
    strictness: 'flexible',
    createdAtKey: d4,
    history: {
      [d2]: { done: true, durationSeconds: 900, mood: 'good', note: 'Finished 18 pages of Atomic Habits.' },
      [d1]: { done: true, durationSeconds: 900 }
    }
  });

  // 4. Daily Limit Mode (Stay <= 2 cups of coffee)
  state.addCustomHabit({
    name: 'Caffeine Budget',
    icon: 'ic_drink',
    color: '#BF5AF2',
    timeOfDay: 'afternoon',
    polarity: 'limit',
    type: 'amount',
    targetAmount: 2,
    unit: 'cups',
    stepAmount: 1,
    createdAtKey: d4,
    history: {
      [d2]: { done: true, amount: 1 },
      [d1]: { done: true, amount: 2 },
      [t0]: { done: true, amount: 1 }
    }
  });

  // 5. Quit / Abstain Bad-Habit Mode
  state.addCustomHabit({
    name: 'Zero Refined Sugar',
    icon: 'ic_fruit',
    color: '#30D158',
    timeOfDay: 'evening',
    polarity: 'quit',
    type: 'binary',
    createdAtKey: d4,
    history: {
      [d3]: { done: true },
      [d2]: { done: true },
      [d1]: { done: true, mood: 'great', note: 'Swapped dessert for berries!' },
      [t0]: { done: true }
    }
  });

  // 6. Weekly Periodic Habit: Strength Workout (3 times / week, spread across week)
  state.addCustomHabit({
    name: 'Strength Workout',
    icon: 'ic_gym',
    color: '#FF9500',
    timeOfDay: 'afternoon',
    polarity: 'build',
    type: 'binary',
    frequency: '3_per_week',
    frequencyTargetTimes: 3,
    repeatLabel: '3x / week',
    strictness: 'flexible',
    createdAtKey: d4,
    history: {
      [d3]: { done: true },
      [d1]: { done: true }
    }
  });

  // 7. Monthly Periodic Habit: Deep Clean & Declutter (Twice a month)
  state.addCustomHabit({
    name: 'Deep Clean & Declutter',
    icon: 'ic_all_habits',
    color: '#32ADE6',
    timeOfDay: 'anytime',
    polarity: 'build',
    type: 'binary',
    frequency: '2_per_month',
    frequencyTargetTimes: 2,
    repeatLabel: 'Twice a month',
    strictness: 'flexible',
    createdAtKey: d4,
    history: {
      [d2]: { done: true, note: 'Pantry and closet fully organized.' }
    }
  });

  state.joinChallenge('hydration_hero_14');
  state.saveSettings();
  state.saveHabits();
  sound.playSuccess();
  confetti.burst();
  switchScreen('today');
  renderTodayScreen();
  showToast('Loaded Multi-Mode Demo Suite! 🌱');
}

// ============================================================================
// NAVIGATION, ONBOARDING & GLOBAL SHORTCUTS
// ============================================================================

function refocusToToday() {
  state.selectedDay = state.todayKey;
  sound.playHaptic();
  renderTodayScreen();
  scrollRibbonToToday(true, true);
}

function selectDay(dateKey, shouldScrollToToday = false) {
  if (shouldScrollToToday) {
    refocusToToday();
    return;
  }
  state.selectedDay = dateKey;
  sound.playClick();
  renderTodayScreen();
  syncReturnTodayPillVisibility();
}

function setTodayFilter(filter) {
  state.todayFilter = filter;
  sound.playClick();
  renderTodayScreen();
}

function onTodaySearch(q) {
  state.searchQuery = q || '';
  renderTodayScreen();
}

function onHabitCardClick(e, id) {
  if (Date.now() < suppressRowClickUntil) {
    if (e) { e.stopPropagation(); e.preventDefault(); }
    return;
  }
  if (state.swipedHabitId !== null) {
    closeSwipedRowSmoothly();
    return;
  }
  sound.playClick();
  renderHabitDetails(id);
  switchScreen('details');
}

function switchScreen(screenName) {
  state.activeScreen = screenName;
  sound.playClick();
  if (document.querySelectorAll) {
    document.querySelectorAll('.screen-view').forEach(s => s.classList.remove('active'));
    document.querySelectorAll('.tab-item').forEach(t => {
      t.classList.toggle('active', t.dataset.screen === screenName);
    });
  }
  const target = document.getElementById('screen-' + screenName);
  if (target && target.classList) target.classList.add('active');

  const tabBar = document.querySelector ? document.querySelector('.ios-tab-bar') : null;
  if (tabBar && tabBar.style) {
    tabBar.style.display = (screenName === 'onboarding') ? 'none' : 'flex';
  }

  if (screenName === 'today') renderTodayScreen();
  else if (screenName === 'insights') renderInsightsScreen();
  else if (screenName === 'challenges') renderChallengesScreen();
  else if (screenName === 'settings') renderSettingsScreen();
}

function setOnboardingWeekStart(val) {
  state.weekStartDay = val;
  sound.playClick();
  if (document.querySelectorAll) {
    document.querySelectorAll('#onboarding-week-start-options .onboarding-option-pill').forEach(p => {
      p.classList.toggle('selected', p.dataset.value === val);
    });
  }
}

function setOnboardingTheme(val) {
  state.theme = val;
  applyThemeToDOM();
  sound.playClick();
  if (document.querySelectorAll) {
    document.querySelectorAll('#onboarding-theme-options .onboarding-option-pill').forEach(p => {
      p.classList.toggle('selected', p.dataset.value === val);
    });
  }
}

function setOnboardingStrictness(val) {
  state.defaultStrictness = val;
  sound.playClick();
  if (document.querySelectorAll) {
    document.querySelectorAll('#onboarding-strictness-options .onboarding-list-row').forEach(row => {
      const isSel = row.dataset.value === val;
      row.classList.toggle('selected', isSel);
      const check = row.querySelector ? row.querySelector('.check-mark') : null;
      if (check) check.textContent = isSel ? '✓' : '';
    });
  }
}

function toggleOnboardingSound() {
  state.soundEnabled = !state.soundEnabled;
  sound.playClick();
  const btn = document.getElementById('onboarding-sound-btn');
  if (btn) {
    btn.textContent = state.soundEnabled ? '🔊 Enabled' : '🔇 Muted';
    btn.classList.toggle('active', state.soundEnabled);
  }
}

function finishOnboarding() {
  state.hasCompletedOnboarding = true;
  state.saveSettings();
  sound.playSuccess();
  confetti.burst();
  switchScreen('today');
  renderTodayScreen();
}

function relaunchOnboarding() {
  sound.playClick();
  setOnboardingWeekStart(state.weekStartDay);
  setOnboardingTheme(state.theme);
  setOnboardingStrictness(state.defaultStrictness);
  switchScreen('onboarding');
}

function onWeekStartChange(val) {
  state.weekStartDay = val;
  state.saveSettings();
  sound.playClick();
  renderTodayScreen();
  showToast('Week starts on ' + val);
}

function onDefaultStrictnessChange(val) {
  state.defaultStrictness = val;
  state.saveSettings();
  sound.playClick();
  showToast('Default strictness: ' + val);
}

function pulseDynamicIsland(text) {
  const island = document.getElementById('dynamic-island');
  const title = document.getElementById('island-pulse-title');
  const textEl = document.getElementById('island-pulse-text');
  if (textEl) textEl.textContent = text;
  else if (title) title.textContent = text;
  if (title) title.style.display = 'flex';
  if (island && island.classList && !island.classList.contains('expanded')) {
    island.style.width = '166px';
    setTimeout(() => {
      if (!state.activeTimerHabitId && title) title.style.display = 'none';
      if (!island.classList.contains('expanded')) island.style.width = 'var(--island-width)';
    }, 1200);
  }
}

function toggleDynamicIsland() {
  sound.playClick();
  const island = document.getElementById('dynamic-island');
  if (island && island.classList) {
    if (state.activeTimerHabitId) {
      island.classList.toggle('expanded');
    }
  }
}

function triggerActionButton() {
  sound.playHaptic();
  const pending = state.activeHabits.find(h => {
    if (!state.isHabitDueOnDate(h, state.todayKey)) return false;
    const s = state.getHabitStatusOnSelectedDay(h, state.todayKey);
    return s === 'pending';
  });
  if (pending) {
    if (pending.polarity === 'build' && pending.type === 'amount') {
      state.incrementAmount(pending.id, pending.stepAmount, state.todayKey);
    } else if (pending.polarity === 'build' && pending.type === 'reps') {
      state.stepReps(pending.id, 1, state.todayKey);
    } else {
      state.toggleBinaryHabit(pending.id, state.todayKey);
    }
    sound.playSuccess();
    confetti.burst();
    renderTodayScreen();
    showToast('Action Button Logged: ' + pending.name + ' ⚡');
    pulseDynamicIsland('⚡ ' + pending.name);
  } else {
    showToast('All due habits completed for today! 🎉');
  }
}

function toggleTodaySearchBar() {
  const row = document.getElementById('today-search-row');
  const input = document.getElementById('today-search-input');
  const btn = document.getElementById('today-search-toggle-btn');
  if (!row) return;
  const isHidden = row.style.display === 'none' || !row.style.display;
  if (isHidden) {
    row.style.display = 'flex';
    if (btn) btn.textContent = '✕';
    if (input && input.focus) input.focus();
  } else {
    row.style.display = 'none';
    if (btn) btn.textContent = '🔍';
    if (input) input.value = '';
    state.searchQuery = '';
    renderTodayScreen();
  }
  sound.playClick();
}

function showToast(message) {
  const toast = document.getElementById('ios-toast');
  if (!toast || !toast.querySelector) return;
  const msgEl = toast.querySelector('.toast-msg');
  if (msgEl) msgEl.textContent = message;
  toast.classList.add('active');
  setTimeout(() => toast.classList.remove('active'), 2200);
}

function setDeviceFinish(finish) {
  state.finish = finish;
  if (document.documentElement && document.documentElement.dataset) {
    document.documentElement.dataset.finish = finish;
  }
  if (document.querySelectorAll) {
    document.querySelectorAll('.finish-dot').forEach(d => {
      d.classList.toggle('active', d.dataset.finish === finish);
    });
  }
  state.saveSettings();
  sound.playClick();
}

function toggleSound() {
  state.soundEnabled = !state.soundEnabled;
  state.saveSettings();
  const btn = document.getElementById('tool-sound-btn');
  if (btn) btn.innerHTML = state.soundEnabled ? '🔊 Haptics' : '🔇 Muted';
  renderSettingsScreen();
  if (state.soundEnabled) sound.playClick();
}

function updateLiveClock() {
  const clockEl = document.getElementById('status-time-clock');
  if (!clockEl) return;
  const now = new Date();
  clockEl.textContent = now.getHours() + ':' + String(now.getMinutes()).padStart(2, '0');
}

if (typeof window !== 'undefined' && window.addEventListener) {
  window.addEventListener('DOMContentLoaded', () => {
    const canvas = document.getElementById('confetti-canvas');
    if (canvas) confetti = new ConfettiEngine(canvas);

    updateLiveClock();
    setInterval(updateLiveClock, 30000);
    applyThemeToDOM();

    if (!state.hasCompletedOnboarding) {
      relaunchOnboarding();
    } else {
      renderTodayScreen();
    }
    renderSettingsScreen();

    if (document.querySelectorAll) {
      document.querySelectorAll('.tab-item').forEach(tab => {
        tab.addEventListener('click', () => {
          if (tab.dataset.screen === 'today' && state.activeScreen === 'today') {
            refocusToToday();
            return;
          }
          if (tab.dataset.screen) switchScreen(tab.dataset.screen);
        });
      });
    }

    const weekRibbonEl = document.getElementById('week-ribbon-container');
    enableHorizontalDragScroll(weekRibbonEl);
    if (weekRibbonEl && weekRibbonEl.addEventListener) {
      weekRibbonEl.addEventListener('scroll', syncReturnTodayPillVisibility, { passive: true });
    }
    enableHorizontalDragScroll(document.getElementById('sheet-cat-tabs'));

    const island = document.getElementById('dynamic-island');
    if (island && island.addEventListener) {
      island.addEventListener('click', (e) => {
        if (e.target && e.target.closest && e.target.closest('.island-quick-btn')) {
          e.stopPropagation();
          triggerActionButton();
          return;
        }
        toggleDynamicIsland();
      });
    }

    const hwBtn = document.getElementById('hw-action-btn');
    if (hwBtn && hwBtn.addEventListener) hwBtn.addEventListener('click', triggerActionButton);

    window.addEventListener('keydown', (e) => {
      const tag = (e.target && e.target.tagName) || '';
      if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') return;
      if (e.code === 'Space') { e.preventDefault(); triggerActionButton(); }
      if (e.key === 'd' || e.key === 'D') toggleDynamicIsland();
      if (e.key === 't' || e.key === 'T') cycleAppTheme();
    });

    const customForm = document.getElementById('custom-habit-form');
    if (customForm && customForm.addEventListener) {
      customForm.addEventListener('submit', (e) => {
        e.preventDefault();
        const name = document.getElementById('custom-name-input').value.trim();
        if (!name) return;
        const freqSel = document.getElementById('custom-frequency-select');
        const targetInput = document.getElementById('custom-frequency-target-input');
        const freqVal = freqSel ? freqSel.value : 'daily';
        const targetTimes = Number(targetInput ? targetInput.value : 1) || 1;
        const payload = {
          name,
          polarity: state.customPolarity,
          type: state.customTrackingMode,
          targetAmount: Number(document.getElementById('custom-target-amount').value) || 2000,
          unit: document.getElementById('custom-unit-select').value,
          stepAmount: Number(document.getElementById('custom-step-amount').value) || 250,
          targetReps: Number(document.getElementById('custom-reps-count').value) || 3,
          targetDuration: Number(document.getElementById('custom-duration-minutes').value) || 15,
          frequency: freqVal,
          frequencyTargetTimes: targetTimes,
          customWeekdays: state.customWeekdays.slice(),
          repeatLabel: (freqSel && freqSel.selectedOptions && freqSel.selectedOptions[0]) ? freqSel.selectedOptions[0].text : 'Every day',
          strictness: document.getElementById('custom-strictness-select').value,
          subtasks: state.builderSubtasks.slice(),
          timeOfDay: document.getElementById('custom-time-select').value,
          reminderTime: document.getElementById('custom-reminder-time').value || '09:00',
          color: document.getElementById('custom-color-select').value,
          icon: document.getElementById('custom-icon-select').value
        };

        if (state.editingHabitId) {
          state.updateHabit(state.editingHabitId, payload);
          showToast('Updated: ' + name + ' ✓');
          if (state.activeScreen === 'details') renderHabitDetails(state.editingHabitId);
        } else {
          state.addCustomHabit(payload);
          confetti.burst();
          showToast('Created: ' + name + ' 🎉');
        }
        state.editingHabitId = null;
        closeAddHabitSheet();
        renderTodayScreen();
      });
    }
  });
}
`;

const finalAppJs = engineTemplate.replace('__APP_DATA_JSON__', JSON.stringify(appData));
fs.writeFileSync('app.js', finalAppJs, 'utf8');
console.log('Successfully generated app.js (' + finalAppJs.length + ' bytes)!');
