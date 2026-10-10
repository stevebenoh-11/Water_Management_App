# JalMitra – Your Pocket Water Saver

**JalMitra** is a zero-hardware, zero-cost, fully offline Android application built for **FLUID HACKATHON 2026** (Department of EEE, KPR Institute of Engineering and Technology).

---

## 🌊 Overview & Problem Statement
In Indian households with sump + overhead tank + motor setups, millions of litres of potable water and thousands of kilowatt-hours of electricity are lost daily due to overhead tank overflows, unmonitored tap/shower flow, and hidden pipe leaks.

**JalMitra** turns any smartphone into an intelligent household water manager without requiring any external hardware or sensors:
1. **Motor Guard (Hero Feature)**: Calculates exact tank fill times based on motor HP and initial water level. Fires exact alarms even when the phone is locked or app is closed. Self-learns motor performance over time.
2. **Flow Timer**: Calibrates individual tap and shower flow rates (L/s) using a standard 1-Litre bottle and alerts users when water limits are reached.
3. **Leak Check**:
   - *Drip Calculator*: Converts 10-second drip counts into monthly litres and bucket waste equivalents.
   - *Night Meter Test*: Detects hidden leaks by comparing night and morning water meter readings.
4. **Daily Water Challenges & Gamification**: 30 daily water-saving habits with streaks and milestone badges.
5. **Bilingual Support**: Instant toggle between English and Tamil (தமிழ்).
6. **Demo Mode**: 1 minute = 1 second speed-up for instant hackathon live demonstrations.

---

## 🛠 Tech Stack
- **Framework**: Flutter (Material 3)
- **Language**: Dart
- **Storage**: `shared_preferences` (All data stored locally as JSON; 100% offline)
- **Notifications**: `flutter_local_notifications` + `timezone` (exact scheduled alarms with core library desugaring)
- **Charts**: `fl_chart` (weekly water savings bar chart)

---

## 📁 Architecture & Folder Structure
```text
lib/
├── l10n/
│   └── app_strings.dart       # Bilingual English + Tamil strings map
├── models/
│   ├── user_settings.dart     # Household config & preferences
│   ├── motor_session.dart     # Active motor timer session
│   ├── fixture.dart           # Tap/shower calibrated flow rates
│   ├── daily_savings.dart     # Daily water, energy & cost savings
│   └── meter_test.dart        # Night meter leak records
├── screens/
│   ├── onboarding_screen.dart # First launch tutorial & parameters setup
│   ├── home_screen.dart       # Dashboard, savings stats & fl_chart
│   ├── motor_guard_screen.dart# Motor countdown, level picker & self-learning
│   ├── flow_timer_screen.dart # Fixture flow timer & 1L calibration
│   ├── leak_check_screen.dart # Drip calculator & night meter test
│   ├── challenges_screen.dart # Daily habit challenges & streak badges
│   ├── settings_screen.dart   # Parameters, language, demo mode & reset
│   └── main_screen.dart       # 5-tab bottom navigation
├── services/
│   ├── calc_service.dart      # Pure calculation formulas
│   ├── notification_service.dart # Local notification & alarm scheduler
│   └── storage_service.dart   # SharedPreferences persistence layer
└── theme/
    └── app_theme.dart         # Water-inspired blue/teal Material 3 palette
```

---

## 🧮 Mathematical Formulas (`lib/services/calc_service.dart`)
All calculations are pure, deterministic functions tested in `test/calc_service_test.dart`:
1. **Remaining Time**:
   $$\text{remainingTimeSeconds} = \text{fillTimeSeconds} \times (1 - \text{initialLevel})$$
2. **Self-Learning Motor Update**:
   $$\text{measuredFullTime} = \frac{\text{actualElapsedSeconds}}{1 - \text{initialLevel}}$$
   $$\text{newFillTime} = \frac{\text{currentFillTime} \times \text{currentFillCount} + \text{measuredFullTime}}{\text{currentFillCount} + 1}$$
3. **Savings Calculation**:
   $$\text{flowRate} \, (\text{L/min}) = \frac{\text{tankCapacityLitres}}{\text{fillTimeSeconds} / 60}$$
   $$\text{waterSaved} = \text{flowRate} \times \text{typicalOverflowMinutes}$$
   $$\text{energySaved} \, (\text{kWh}) = \text{motorHp} \times 0.746 \times \left(\frac{\text{typicalOverflowMinutes}}{60}\right)$$
   $$\text{moneySaved} = \text{energySaved} \times \text{electricityRate}$$

---

## ⚡ How to Build & Run

### Prerequisites
- Flutter SDK (>= 3.5.0)
- Android SDK (API 34)

### Steps
1. Fetch dependencies:
   ```bash
   flutter pub get
   ```
2. Run unit tests:
   ```bash
   flutter test
   ```
3. Analyze code quality:
   ```bash
   flutter analyze
   ```
4. Build Release APK:
   ```bash
   flutter build apk --release
   ```
   The generated APK will be available at:
   `build/app/outputs/flutter-apk/app-release.apk`

---

## 🏆 Hackathon Details
- **Event**: FLUID HACKATHON 2026
- **Organizer**: Department of EEE, KPR Institute of Engineering and Technology
- **Theme**: Water Conservation & Intelligent Management
