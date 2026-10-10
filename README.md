# JalMitra – Your Pocket Water Saver 💧

> **Zero hardware. Zero cost. Fully offline. No login.**
> An Android app that stops overhead-tank overflows, measures the water your home
> uses and wastes, finds leaks, and helps families save water — using only the
> phone's timer, buttons and notifications.

**Fluid Hackathon 2026** · Department of EEE, KPR Institute of Engineering and Technology
**Theme:** Water management and conservation · **Languages:** English and தமிழ்

---

## 1. The problem

Most Indian homes store water the same way: a **sump** at ground level, one or more
**tanks** on the roof, and an electric **motor** that pumps water up.

Nobody knows exactly when the tank will be full. The motor is switched on, everyone
gets busy, and the tank **overflows** until someone hears the splashing. Every day:

- **Clean water is wasted** off the roof.
- **Electricity is wasted** running the motor for nothing.
- **Leaks go unnoticed** – a dripping tap or a hidden pipe can waste hundreds of litres
  a month.
- **Families don't know how much water they use** compared with what they need.

Float sensors, smart meters and IoT controllers can fix this, but they cost money and
need installation. Most families will never buy them.

## 2. The solution

**Every family already has a smartphone.** JalMitra turns it into a water manager:

| Instead of… | JalMitra uses… |
|---|---|
| A float sensor in the tank | The phone's **timer** + a one-time calibration of how long each tank takes to fill |
| An automatic motor cut-off | An **exact alarm** 2 minutes before full — even if the app is closed, the phone is locked, or it was restarted |
| A flow meter on each tap | A **1-litre bottle** and a stopwatch |
| A leak detector | **Counting drips** for 10 seconds, or comparing the **water meter** at night and in the morning |
| A smart water meter | Adding up the water **pumped, measured and wasted** every day |

The key insight: **a motor fills a tank at a nearly constant rate.** Once we know how
long one full fill takes, simple maths predicts exactly when the tank will be full from
any starting level — and how much water and electricity each overflow wastes.

Designed for everyone, including elderly users: large text and buttons, icons with
labels, simple words, colour never the only signal, and every screen in English and Tamil.

---

## 3. Features

### 🏠 Home
- "This week you saved: X L · Y kWh · ₹Z" and a 7-day bar chart.
- Big round **Motor ON** button.
- **Water today** card: used / wasted vs what your home needs → opens the Usage screen.
- **Tip of the Day** (61 tips, English and Tamil; a new one each day, no repeats until
  all are shown) and an optional 8 AM tip notification.
- **Daily Challenge** (30 challenges) with streaks and badges at 3, 7 and 30 days.
- Reminder when a tank is due for cleaning.

### 🔌 Motor Guard (main feature)
- **Tank selector** at the top — each tank has its own motor and learned fill time.
- **Calibrate once:** empty tank → *Start Calibration* → *Tank Full*.
- **Daily:** pick the level (Empty, ¼, ½, ¾) → *Motor ON – Start Guard*. A countdown ring
  shows the time to full, the expected full time and the alarm time.
- **Alarm 2 minutes before full** with the phone's alarm tone, vibration and full-screen
  wake-up, showing the tank name. Works when the app is closed, the phone is locked, or
  after a restart. The running session survives closing the app.
- **Self-learning:** every *Tank Full* refines the fill time; accidental taps are ignored.
- **Results:** "Great! You saved ~208 L and ₹0.37 today", water pumped, and overflow
  wasted if *Tank Full* was tapped late. *Cancel* records the water pumped so far.

### 🛢️ My Tanks
- Several tanks: overhead, sump, loft or other; plastic, RCC/concrete, stainless steel,
  galvanised iron, ferro-cement, brick or other; round standing, round lying, or rectangular.
- Capacity **typed, or calculated from the tank's size**.
- Each tank keeps its motor HP, overflow minutes, learned fill time and number of runs.
- Cleaning interval by material and last-cleaned date, with a "cleaning due" badge.
- Add / edit / delete / set default / recalibrate / mark cleaned. At least one tank
  always exists.

### 🚿 Flow Timer
Time a tap or shower with a 1-litre bottle → save it by name. Pick a tap, set a limit
(e.g. 40 L), *Start*: live litres and a progress bar; the phone vibrates past the limit.
Litres are added to today's usage.

### 💧 Leak Check
- **Drip Calculator:** tap a big button for every drip in 10 seconds → litres per
  day / month and buckets. Save it as an **active leak** (counted as daily waste until
  fixed), or tap **Fixed it!** to add the saving.
- **Night Meter Test:** night reading → 7 AM reminder → morning reading. Any difference
  is a hidden leak, counted as waste, with places to check: toilet flush, tank float
  valve, underground pipe, overflow pipe.

### 📊 Water Used & Wasted
- **Today:** used / wasted / saved, wasted as % of used and in buckets
  ("Wasted 12% — about 3 buckets today").
- **Your need:** "Your home needs about X L/day · You used Y L today" with
  below / about / above indicator, plus your 7-day and 30-day averages.
- **This week:** used vs wasted bar chart.
- **This year:** totals, monthly chart (Jan–Dec) and a clearly labelled
  **projection for the full year**.

### ⚙️ Settings
Language, people at home, area (city / town / village), litres per person, electricity
rate, default motor HP and overflow minutes, My Tanks, taps, **Demo Mode**
(1 minute = 1 second), tip notification, alarm permission, battery-optimisation help for
Xiaomi/Oppo/Vivo/Realme, and Reset all data.

---

## 4. Formulas

Every formula is a small, commented, pure function in
[`lib/services/calc_service.dart`](lib/services/calc_service.dart), with unit tests in
[`test/calc_service_test.dart`](test/calc_service_test.dart).

### Motor Guard

| Quantity | Formula | Example |
|---|---|---|
| Time left | `remaining = fillTime × (1 − level)` | 24 min tank, half full → 12 min |
| Alarm | `alarm = now + remaining − 2 min` (immediately if < 2 min) | after 10 min |
| Measured fill | `measured = elapsed ÷ (1 − level)` | ½ full, took 13 min → 26 min |
| Self-learning | `fillTime = (fillTime × runs + measured) ÷ (runs + 1)` | (24 + 26) ÷ 2 = 25 min |
| Ignore accidents | learn only if elapsed ≥ 30 s and 0.25× ≤ measured ÷ fillTime ≤ 4× | |
| Flow rate | `flowRate = capacity ÷ fillTime(min)` | 1000 L ÷ 24 = **41.7 L/min** |
| Water saved | `flowRate × overflowMinutes` | 41.7 × 5 = **208 L** |
| Energy saved | `HP × 0.746 × overflowMinutes ÷ 60` | 1 × 0.746 × 5/60 = **0.062 kWh** |
| Money saved | `energy × electricityRate` | 0.062 × ₹6 = **₹0.37** |
| Water pumped (used) | `capacity × (1 − startLevel)`; if cancelled: `flowRate × elapsed` | ½ of 1000 L → 500 L |
| Overflow wasted | `flowRate × minutes past predicted full` | 2 min late × 40 = 80 L |

(1 HP = 0.746 kW. If *Tank Full* is tapped late, the overflow minutes avoided shrink
by the minutes late, so savings shrink too.)

### Tanks

| Shape | Formula (metres → litres) | Example |
|---|---|---|
| Round (standing or lying) | `π × r² × h × 1000`, r = diameter ÷ 2 | Ø 1.1 m × 1.05 m → 998 L |
| Rectangular | `l × w × h × 1000` | 2 × 1.5 × 1 m → 3000 L |

Default cleaning interval: plastic 6 months, RCC/concrete and brick 3 months,
ferro-cement 4 months, GI 6 months, stainless steel 12 months.

### Flow, leaks, meter

| Quantity | Formula | Example |
|---|---|---|
| Tap flow | `1 ÷ seconds to fill 1 L` (L/s) | 10 s → 0.1 L/s |
| Live litres | `flowRate × seconds` | 0.1 × 410 s = 41 L |
| Drips per day | `drips × 8640` | 3 → 25 920 |
| Litres per day | `drips/day ÷ 4000` | 6.48 L |
| Litres per month | `litres/day × 30` | **194 L** |
| Buckets | `litres ÷ 10` | 19.4 |
| Overnight loss | `morning − night` (× 1000 for m³) | 1234.500 → 1234.512 m³ = 12 L |

### Usage

| Quantity | Formula |
|---|---|
| Used | Motor Guard water pumped + Flow Timer litres |
| Wasted | overflow + daily loss of unfixed leaks + overnight meter loss |
| Wasted % | `wasted ÷ used × 100` |
| Required per day | `people × litres per person` — city 135 L (CPHEEO, with sewerage), town 70 L (CPHEEO, without sewerage), village 55 L (Jal Jeevan Mission); editable |
| Below / about / above | below 90 % / 90–110 % / above 110 % of the requirement |
| Full-year projection | `(total so far ÷ days counted) × 365` — an estimate |

### Tips & challenges

- Tip: `index = (dayNumber × step + 11) mod count`, where `step` is coprime with
  `count`, so any `count` days in a row show every tip exactly once.
- Challenge: `index = (dayOfYear − 1) mod 30`. Streak +1 if done yesterday; a missed day
  resets it.

---

## 5. Technology

| Part | Choice |
|---|---|
| App | Flutter (Dart, Material 3), Android 7.0+ (API 24), targets the latest SDK |
| Storage | `shared_preferences` (`SharedPreferencesWithCache`, JSON) — on the phone only |
| Alarms & reminders | `flutter_local_notifications` + `timezone` — Android `AlarmManager` exact alarms |
| Charts | `fl_chart` |
| Languages | Map-based English/Tamil strings in `lib/l10n/` |

No internet, no backend, no analytics, no login.

## 6. Architecture

```text
lib/
├── main.dart               Init storage + notifications → onboarding or the app
├── l10n/                   app_strings.dart (English + Tamil), tips.dart (61 tips)
├── models/                 user_settings, tank_profile, motor_session, fixture (tap),
│                           daily_record, flow_record, leak, meter_test, challenge
├── services/
│   ├── calc_service.dart          All formulas (pure functions)
│   ├── storage_service.dart       Local persistence + migration from v1
│   ├── notification_service.dart  Exact alarms, meter reminder, daily tips
│   └── app_controller.dart        App state (ChangeNotifier)
├── screens/                onboarding, home, motor_guard, tanks, tank_editor,
│                           flow_timer, fixtures, leak_check, usage, challenges, settings
└── widgets/                countdown ring, charts, number field, pickers, cards
```

```text
Motor ON ─► calc: remaining + alarm time ─► storage: save session
        ─► notifications: Android schedules the exact alarm (survives close/lock/reboot)
Alarm ─► "Tank Full" ─► calc: learn fill time, used / wasted / saved
      ─► storage: today's record ─► Home & Usage update
```

## 7. Android permissions

| Permission | Why |
|---|---|
| `POST_NOTIFICATIONS` | Show the tank alarm, reminders and tips |
| `SCHEDULE_EXACT_ALARM` (Android 12) / `USE_EXACT_ALARM` (13+) | Ring at the exact time |
| `USE_FULL_SCREEN_INTENT` | Wake the screen for the alarm when locked |
| `VIBRATE` | Alarm and Flow Timer warnings |
| `RECEIVE_BOOT_COMPLETED` | Restore pending alarms after a restart |

The app explains why before asking. If denied, everything else still works and Motor
Guard shows an **Allow alarms** button.

---

## 8. Two-minute demo

1. Install the APK, choose the language, finish setup (defaults are fine), tap **Allow**.
2. **Settings → Demo Mode** on (orange DEMO MODE badge).
3. **Motor Guard → Start Calibration**, wait ~24 s (= 24 min), tap **Tank Full**.
4. Choose **Half** → **Motor ON – Start Guard**, lock the phone. The alarm rings about
   10 s later with the tank name. Tap **Tank Full** → "You saved ~208 L and ₹0.37 today".
5. **Leak Check:** enter `3` drips → 194 L/month → **Save as leak** (counts as waste) →
   **Fixed it!**
6. **Home → Water today → See details:** used / wasted / saved, your daily need, week
   and year charts, full-year projection.
7. **Motor Guard → My Tanks:** add a sump with capacity from its size.
8. Switch to **தமிழ்** in Settings.

## 9. Build & run

Requirements: Flutter stable (built with 3.47.7 / Dart 3.13.5), Android SDK platform 36,
JDK 17+.

```bash
flutter pub get
flutter analyze            # No issues found
flutter test               # all tests pass
flutter run                # on a connected phone
flutter build apk --release        # build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release  # build/app/outputs/bundle/release/app-release.aab (Play Store)
```

**Release signing:** create `android/key.properties`:

```properties
storePassword=…
keyPassword=…
keyAlias=upload
storeFile=upload-keystore.jks
```

and put the keystore at `android/app/upload-keystore.jks`. Both are git-ignored —
**back them up safely**; Play Store updates need the same key. Without them, release
builds are signed with the debug key (fine for sideloading).

**Play Store notes:** `USE_EXACT_ALARM` and full-screen intents are allowed for
alarm-style apps; declare them in the Play Console. Store icon:
`assets/store/icon-512.png`.

### Tests (111)

- `calc_service_test.dart` – every formula (Motor Guard, volumes, flow, drips, meter,
  used/wasted, yearly totals and projection, required/day, tip selection)
- `app_controller_test.dart` – tanks, calibration, alarm timing, demo mode, late/early
  runs, session restore, leaks, usage, tips, challenges, reset
- `storage_service_test.dart` – save/load, Motor Guard session restore, v1 migration,
  corrupt data
- `l10n_test.dart` – every string in Tamil, every key used exists, 60+ tips
- `onboarding_widget_test.dart`, `screens_widget_test.dart` – onboarding, tanks
  add/edit/delete, Motor Guard, Flow Timer, Leak Check, Usage (incl. empty state),
  tip card, settings, and full flows in Tamil on a small phone screen

## 10. Future scope

- Home-screen widget with the Motor Guard countdown
- Family sharing of tank status over local Wi-Fi
- Optional low-cost smart plug for automatic motor cut-off
- More Indian languages (Hindi, Malayalam, Telugu, Kannada)
- Community dashboard for apartments and streets
- Export usage history as a PDF report

---

**JalMitra** – *ஜல்மித்ரா* – "friend of water". Save every drop. 💧
