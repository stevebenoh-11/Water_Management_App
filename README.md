# JalMitra – Your Pocket Water Saver 💧

**JalMitra** (ஜல்மித்ரா) is a zero-hardware, zero-cost, fully offline Android app that
stops overhead-tank overflows, measures water use and finds leaks — using only the
phone's timer, buttons and notifications.

Built for **Fluid Hackathon 2026**, Department of EEE, KPR Institute of Engineering
and Technology. Theme: water management and conservation.

---

## The problem

Most Indian homes pump water from a sump to an overhead tank with an electric motor.
Nobody knows exactly when the tank will be full, so the motor keeps running and water
overflows until someone notices — wasting both water and electricity, every day.
Dripping taps and hidden pipe leaks add to the loss, unseen.

Sensors and smart meters solve this, but they cost money and need installation.
JalMitra does it with the phone people already have.

---

## Features

| Screen | What it does |
|---|---|
| **Motor Guard** (hero) | Learns how long your tank takes to fill. Pick the current level (empty / ¼ / ½ / ¾) and switch on the motor: JalMitra shows a countdown ring and rings an **exact alarm 2 minutes before the tank is full** — even if the app is closed or the phone is locked. Gets more accurate every time you tap "Tank Full". |
| **Flow Timer** | Time a 1-litre bottle at any tap or shower to learn its flow rate. Then pick the tap, set a limit (default 40 L) and watch live litres used. The phone vibrates when you cross the limit. Usage history is saved. |
| **Leak Check – Drip Calculator** | Tap a big button for every drip for 10 seconds. JalMitra shows the waste per month and in buckets. "Fixed it!" adds the saving to your total. |
| **Leak Check – Night Meter Test** | Enter your water meter reading at night (all taps closed). A 7 AM reminder asks for the morning reading. Any difference means a hidden leak, with tips on where to look. Litres or m³ meters. |
| **Home dashboard** | "This week you saved X L · Y kWh · ₹Z", a big Motor ON button, today's challenge and a 7-day bar chart. |
| **Challenges** | 30 simple water-saving habits (one per day), streaks, and badges at 3, 7 and 30 days. |
| **Settings** | Edit tank size, motor HP, electricity rate and overflow minutes; English ⇄ தமிழ்; Demo Mode; recalibrate motor; manage taps; reset all data. |

Also:

- **Bilingual** – every screen in English and Tamil, switchable instantly.
- **Elderly-friendly** – large text and buttons, icons with labels, blue/teal water palette.
- **Private** – no login, no internet, no backend. All data stays on the phone.
- **Demo Mode** – 1 minute = 1 second for all Motor Guard timings and the alarm, so a
  24-minute tank fill can be shown live in 24 seconds.

---

## The formulas

All formulas live in [`lib/services/calc_service.dart`](lib/services/calc_service.dart) as
small pure functions, each with a comment and a worked example. Every one is unit-tested
in [`test/calc_service_test.dart`](test/calc_service_test.dart).

### Motor Guard

| Quantity | Formula | Example |
|---|---|---|
| Time left to fill | `remaining = fillTime × (1 − level)` | 24 min tank, half full → 12 min |
| Alarm time | `alarm = now + remaining − 120 s` (immediately if under 120 s) | alarm after 10 min |
| Measured fill time | `measured = actualElapsed ÷ (1 − level)` | half full, took 13 min → 26 min |
| Self-learning | `fillTime = (fillTime × fillCount + measured) ÷ (fillCount + 1)` | (24 × 1 + 26) ÷ 2 = 25 min |
| Motor flow rate | `flowRate (L/min) = tankCapacity ÷ (fillTime ÷ 60)` | 1000 L ÷ 24 min = **41.7 L/min** |
| Water saved | `waterSaved = flowRate × overflowMinutes` | 41.7 × 5 = **208 L** |
| Energy saved | `kWh = HP × 0.746 × (overflowMinutes ÷ 60)` | 1 × 0.746 × 5/60 = **0.062 kWh** |
| Money saved | `₹ = kWh × electricityRate` | 0.062 × ₹6 = **₹0.37** |

*Why 0.746?* 1 horsepower = 0.746 kilowatts.
*Why ignore odd runs?* If "Tank Full" is tapped by accident a few seconds after starting,
the measurement would ruin the average, so a run is only learned from if it is between
0.25× and 4× the current fill time.

### Flow Timer

| Quantity | Formula | Example |
|---|---|---|
| Tap flow rate | `flowRate (L/s) = 1 ÷ secondsToFill1L` | 10 s → 0.1 L/s (6 L/min) |
| Live litres | `litres = flowRate × elapsedSeconds` | 0.1 × 410 s = 41 L |

### Leak Check

| Quantity | Formula | Example (3 drips in 10 s) |
|---|---|---|
| Drips per day | `drips × 8640` (8640 ten-second windows in a day) | 25 920 |
| Litres per day | `dripsPerDay ÷ 4000` (≈ 4000 drips per litre) | 6.48 L |
| Litres per month | `litresPerDay × 30` | **194 L** |
| Buckets | `litres ÷ 10` (1 bucket = 10 L) | 19.4 buckets |
| Night meter loss | `morning − night` (× 1000 for m³ meters) | 1234.500 → 1234.512 m³ = 12 L |

A difference above 0 means "Hidden leak likely!"; otherwise "No leak detected ✅".

### Challenges

- Today's challenge: `index = (dayOfYear − 1) mod 30`.
- Streak: +1 if the last "Done" was yesterday, unchanged if already done today,
  otherwise it restarts at 1. A missed day shows 0.

---

## Try it in 2 minutes (demo script)

1. Install the APK and finish the setup (defaults are fine: 1000 L, 1 HP, ₹6/unit, 5 min).
   Tap **Allow** when asked about alarms.
2. **Settings → Demo Mode** on (an orange DEMO MODE badge appears).
3. **Motor Guard → Start Calibration**, wait about 24 seconds (= 24 minutes), tap
   **Tank Full**.
4. Choose **Half**, tap **Motor ON – Start Guard**. Lock the phone.
   The alarm rings about 10 seconds later. Unlock it and tap **Tank Full** to see
   "Great! You saved ~208 L and ₹0.37 today."
5. **Leak Check → Drip Calculator**: enter `3` and tap **Calculate** → 194 L/month.
   Tap **Fixed it!**
6. **Home**: tap **Done** on today's challenge and see the weekly chart grow.
7. Switch the language to **தமிழ்** in Settings.

---

## Run the project

### Prerequisites

- Flutter (stable) – built and tested with Flutter 3.47.7 / Dart 3.13.5
- Android SDK with platform 36, and JDK 17 or newer
- An Android phone (Android 7.0+) with USB debugging on, or an emulator

### Commands

```bash
flutter pub get          # install packages
flutter analyze          # static checks (should report: No issues found)
flutter test             # unit + widget tests
flutter run              # run on a connected phone
flutter build apk --release
```

The release APK is written to `build/app/outputs/flutter-apk/app-release.apk`.
Copy it to a phone and open it to install (allow "Install unknown apps" for your file
manager if Android asks).

> The release build is signed with the debug key, which is fine for sideloading and
> demos. Create a proper signing key before publishing to the Play Store.

### Android permissions

| Permission | Why |
|---|---|
| `POST_NOTIFICATIONS` (Android 13+) | Show the tank alarm and reminders |
| `SCHEDULE_EXACT_ALARM` (Android 12) / `USE_EXACT_ALARM` (13+) | Ring the alarm at the exact second |
| `USE_FULL_SCREEN_INTENT` | Wake the screen for the alarm when the phone is locked |
| `VIBRATE` | Alarm vibration and the Flow Timer limit warning |
| `RECEIVE_BOOT_COMPLETED` | Restore a pending alarm after the phone restarts |

The app explains why before asking. If permission is denied, everything else still works
and Motor Guard shows a warning with an **Allow alarms** button.

---

## How it works inside

```text
lib/
├── main.dart                    App start: storage + notifications, then onboarding or tabs
├── l10n/app_strings.dart        All English + Tamil text (Map-based)
├── models/                      Plain data classes with JSON (settings, motor session,
│                                fixture, daily savings, flow record, meter test, challenge)
├── services/
│   ├── calc_service.dart        Every formula, as pure functions
│   ├── storage_service.dart     shared_preferences (all data stored locally as JSON)
│   ├── notification_service.dart Exact alarms via flutter_local_notifications + timezone
│   └── app_controller.dart      App state and actions; screens rebuild when it changes
├── screens/                     Onboarding, Home, Motor Guard, Flow Timer, Leak Check,
│                                Challenges, Settings, tap editor
├── widgets/                     Countdown ring, weekly chart, number field, shared UI
└── theme/app_theme.dart         Water-inspired Material 3 theme
```

**Why the alarm works when the app is closed:** the alarm is handed to Android's
`AlarmManager` (through `zonedSchedule` with `exactAllowWhileIdle`), so Android itself
rings it at the right time. The running session (start time, level, end time) is saved,
so reopening the app shows the correct countdown. A boot receiver restores pending alarms
after a restart.

### Stored data (shared_preferences)

`settings`, `fillTime`, `fillCount`, `activeMotorSession`, `fixtures`,
`dailySavings` (`yyyy-MM-dd → {litres, kwh, rupees}`), `flowHistory`, `challengeStreak`,
`lastChallengeDate`, `badges`, `meterTest`, plus `onboardingDone` and `permissionsAsked`.

### Tests

- `calc_service_test.dart` – every formula, using the example values above
- `app_controller_test.dart` – calibration, alarm timing, demo mode, self-learning,
  session restore, streaks and badges, meter reminder, reset
- `storage_service_test.dart` – saving and loading every data type
- `l10n_test.dart` – every string has a Tamil translation, and every key used in code exists
- `onboarding_widget_test.dart`, `screens_widget_test.dart` – full user flows on every
  screen, input validation, and Tamil layouts on a small phone screen

---

## Team & event

- **Event:** Fluid Hackathon 2026
- **Organiser:** Department of EEE, KPR Institute of Engineering and Technology
- **Theme:** Water management and conservation
