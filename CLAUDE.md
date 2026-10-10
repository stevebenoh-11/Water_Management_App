# JalMitra – Your Pocket Water Saver

## Project context
Hackathon project (Fluid Hackathon 2026, EEE Dept, KPR Institute of Engineering and Technology).
Theme: water management and conservation. A zero-hardware, zero-cost, fully offline Android app
that prevents overhead tank overflows, measures water usage, and detects leaks using only the
phone's timer, buttons, and notifications. Target users: Indian households with sump + overhead tank + motor.

## Tech stack
- Flutter (latest stable), Dart, Material 3, Android only
- shared_preferences (all data stored locally as JSON)
- flutter_local_notifications + timezone (exact scheduled alarms that fire when the app is closed or phone locked)
- fl_chart (weekly savings chart)
- No login, no backend, no internet, no Firebase.

## Rules for building
- Add packages with `flutter pub add` to get the latest versions. Follow each package's CURRENT
  README setup exactly (e.g. flutter_local_notifications needs core library desugaring in
  build.gradle, manifest receivers, and its newest zonedSchedule API). If unsure about an API,
  read the package source/example in the pub cache instead of guessing.
- Android permissions: POST_NOTIFICATIONS (13+), SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM (12+),
  VIBRATE, RECEIVE_BOOT_COMPLETED. Request politely at first launch; handle denial gracefully.
- Folder structure: lib/screens, lib/services (storage_service, notification_service,
  calc_service), lib/models, lib/widgets, lib/l10n
- All formulas live in lib/services/calc_service.dart as pure functions with clear comments
  (the team must explain them to judges). Write unit tests for every formula in test/.
- After every change: run `flutter analyze` and `flutter test`, fix all errors and warnings
  before saying a phase is done.
- Validate all user inputs (no zero/negative/empty values, no crashes).
- UI: water-inspired blue/teal palette, rounded cards, large buttons and text, icons with labels,
  friendly for elderly users.
- Bilingual English + Tamil via a simple Map-based strings file in lib/l10n (no ARB/intl setup).
  Every user-facing string must come from this file.

## Screens and logic

### 1. Onboarding (first launch only)
3 swipe pages explaining the app, then a setup form saved to shared_preferences:
tank capacity in litres (default 1000), motor HP (default 1), electricity rate in ₹/unit
(default 6), typical minutes a tank overflows before anyone notices (default 5).

### 2. Home / Dashboard
- "This week you saved: X L | Y kWh | ₹Z"
- Big round "Motor ON" button → Motor Guard
- Today's challenge card with "Done" button and streak
- Weekly bar chart of litres saved per day (fl_chart)
- Bottom nav: Home, Motor Guard, Flow Timer, Leak Check, Settings (Challenges reachable from Home)

### 3. Motor Guard (HERO FEATURE)
Calibration (when no fillTime saved): "Start Calibration" with empty tank + motor on →
"Tank Full" when full. Save fillTime (seconds), fillCount = 1.

Daily mode:
- Level picker: Empty 0, Quarter 0.25, Half 0.5, Three-quarters 0.75
- remainingTime = fillTime × (1 − level)
- alarmTime = now + remainingTime − 120 s (if remainingTime < 120 s, alarm immediately)
- Schedule exact notification with alarm sound + vibration:
  "Your tank is almost full! Switch off the motor now."
- Persist the running session (start time, level, end time) so the countdown survives the app
  being closed and reopened.
- Circular countdown ring + expected full time. Buttons: "Tank Full", "Cancel" (cancels alarm).

Self-learning on "Tank Full":
measured = actualElapsed ÷ (1 − level)
fillTime = (fillTime × fillCount + measured) ÷ (fillCount + 1); fillCount++

Savings per successful use:
- flowRate (L/min) = tankCapacity ÷ (fillTime / 60)
- waterSaved = flowRate × typicalOverflowMinutes
- energySaved (kWh) = HP × 0.746 × (typicalOverflowMinutes ÷ 60)
- moneySaved = energySaved × electricityRate
Save to today's record; success popup e.g. "Great! You saved ~208 L and ₹0.37 today."

DEMO MODE (toggle in Settings): 1 minute = 1 second for all Motor Guard timings and the
scheduled alarm. Show a "DEMO MODE" badge when on.

### 4. Flow Timer
- Calibration: fill a 1-litre bottle, Start/Stop measures seconds. flowRate (L/s) = 1 ÷ seconds.
  Save multiple named fixtures ("Bathroom shower", "Kitchen tap"); edit/delete supported.
- Usage: pick fixture, set limit in litres (default 40), Start. Live litres = flowRate × elapsed s,
  updated every second, progress bar. Vibrate + warning when limit crossed. Save to history on Stop.

### 5. Leak Check (two tabs)
A – Drip Calculator: 10-second countdown, user taps a big button per drip (or enters count).
dripsPerDay = drips × 8640; litresPerDay = dripsPerDay ÷ 4000; litresPerMonth = litresPerDay × 30.
Show "This tap wastes N L/month ≈ M buckets" (1 bucket = 10 L). "Fixed it!" adds monthly waste to savings.

B – Night Meter Test: Step 1 (night) enter reading with all taps closed → save with timestamp,
schedule 7 AM reminder. Step 2 (morning) enter reading. Unit choice: litres or m³ (×1000).
difference > 0 → "Hidden leak likely! X L lost overnight" + tips; else "No leak detected ✅".

### 6. Challenges
30 simple water-saving challenges, each with estimated litres saved (e.g. "Use a bucket instead
of a hose to wash your bike", "Reuse RO reject water for mopping", "Turn off the tap while brushing").
One per day (rotate by day of year). "Done" adds litres + increments streak; a missed day resets
the streak. Badges at 3, 7, 30 days.

### 7. Settings
Edit tank capacity, HP, electricity rate, overflow minutes; language toggle; Demo Mode toggle;
recalibrate motor; manage fixtures; "Reset all data" with confirmation.

## Data (shared_preferences, JSON)
settings, fillTime, fillCount, activeMotorSession, fixtures, dailySavings (yyyy-MM-dd →
{litres, kwh, rupees}), flowHistory, challengeStreak, lastChallengeDate, badges, meterTest.

## Build phases (do ONE phase per request; stop and summarise after each)
1. Project setup, theme, l10n strings, storage service, models, bottom navigation, onboarding
2. calc_service with unit tests
3. Notification service + Motor Guard (incl. demo mode, session persistence)
4. Flow Timer
5. Leak Check
6. Dashboard + chart + Challenges
7. Settings, full Tamil strings, polish, empty states, input validation review
8. Release APK build + README