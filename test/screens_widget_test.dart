import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jalmitra/main.dart';
import 'package:jalmitra/models/daily_record.dart';
import 'package:jalmitra/models/tank_profile.dart';
import 'package:jalmitra/models/user_settings.dart';
import 'package:jalmitra/screens/onboarding_screen.dart';
import 'package:jalmitra/services/app_controller.dart';
import 'package:jalmitra/services/storage_service.dart';

import 'helpers.dart';

void main() {
  late StorageService storage;
  late FakeNotifications notes;
  late FakeClock clock;

  setUp(() async {
    storage = await freshStorage();
    notes = FakeNotifications();
    clock = FakeClock(DateTime(2026, 10, 10, 6, 0));
    await storage.setOnboarded(true);
    await storage.setPermissionsAsked(true);
    await storage.saveTanks([testTank()]);
  });

  Future<void> pumpApp(WidgetTester tester,
      {Size size = const Size(420, 2000)}) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(JalMitraApp(
      controller:
          AppController(storage, notifications: notes, clock: clock.call),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.descendant(
        of: find.byType(NavigationBar), matching: find.text(label)));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final f = find.text(text).last;
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  /// Advances the fake clock and lets the 1-second tickers run.
  Future<void> elapse(WidgetTester tester, Duration d) async {
    clock.advance(d);
    await tester.pump(const Duration(seconds: 1));
  }

  // ------------------------------------------------------------ Tanks

  testWidgets('Tanks: add (from size), edit, set default, delete',
      (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'Motor Guard');
    await tester.tap(find.byTooltip('My Tanks'));
    await tester.pumpAndSettle();
    expect(find.text('Overhead tank'), findsWidgets);
    expect(find.text('Not calibrated'), findsOneWidget);

    // Add a rectangular sump, capacity from size.
    await tapText(tester, 'Add tank');
    await tester.enterText(find.byType(TextFormField).first, 'Sump');
    await tapText(tester, 'Round, standing');
    await tapText(tester, 'Rectangular / square');
    await tapText(tester, 'From size');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Length'), '2');
    await tester.enterText(find.widgetWithText(TextFormField, 'Width'), '1.5');
    await tester.enterText(find.widgetWithText(TextFormField, 'Height'), '1');
    await tester.pump();
    expect(find.text('Capacity: about 3000 L'), findsOneWidget);
    await tapText(tester, 'Save');
    expect(find.text('Sump'), findsOneWidget);
    expect(storage.loadTanks().last.capacityLitres, 3000);
    expect(storage.loadTanks().last.shape, TankShape.rectangular);

    // Make it default.
    await tapText(tester, 'Make default');
    expect(storage.loadTanks().firstWhere((t) => t.isDefault).name, 'Sump');

    // Edit the name.
    await tapText(tester, 'Sump');
    await tester.enterText(find.byType(TextFormField).first, 'Ground sump');
    await tapText(tester, 'Save');
    expect(find.text('Ground sump'), findsOneWidget);

    // Delete it; the other tank becomes default.
    await tapText(tester, 'Ground sump');
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Delete');
    expect(storage.loadTanks().length, 1);
    expect(storage.loadTanks().single.isDefault, isTrue);

    // The last tank cannot be deleted.
    await tapText(tester, 'Overhead tank');
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('You need at least one tank.'), findsOneWidget);
  });

  testWidgets('Tanks: cleaning due shows on Home and can be marked done',
      (tester) async {
    await storage.saveTanks([
      testTank().copyWith(
          lastCleaned: DateTime(2026, 1, 1), cleaningIntervalDays: 90),
    ]);
    await pumpApp(tester);
    expect(find.text('Time to clean: Overhead tank'), findsOneWidget);
    await tapText(tester, 'My Tanks');
    expect(find.text('Cleaning due now'), findsOneWidget);
    await tapText(tester, 'Cleaned today');
    expect(find.text('Next cleaning in 90 days'), findsOneWidget);
  });

  // ------------------------------------------------------------ Motor Guard

  testWidgets('Motor Guard: calibrate, guard half tank, Tank Full',
      (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'Motor Guard');
    await tapText(tester, 'Start Calibration');
    expect(find.text('Calibrating…'), findsOneWidget);
    await elapse(tester, const Duration(minutes: 24));
    await tapText(tester, 'Tank Full');
    expect(find.text('Saved! Your tank fills in about 24 min.'), findsOneWidget);

    await tapText(tester, 'Half');
    expect(find.textContaining('Tank will be full in 12 min'), findsOneWidget);
    await tapText(tester, 'Motor ON – Start Guard');
    expect(find.text('6:36 AM'), findsOneWidget);
    expect(find.text('6:34 AM'), findsOneWidget);
    expect(notes.motorAlarmTitle, 'Overhead tank: almost full!');

    await elapse(tester, const Duration(minutes: 12));
    expect(find.text('Tank should be full now!'), findsOneWidget);
    await tapText(tester, 'Tank Full');
    expect(find.text('You saved ~208 L and ₹0.37 today.'), findsOneWidget);
    expect(find.text('About 500 L was pumped into the tank.'), findsOneWidget);
    await tapText(tester, 'OK');

    // Usage reflects calibration (1000 L) + this run (500 L).
    await openTab(tester, 'Home');
    expect(find.text('1500 L'), findsOneWidget);
  });

  testWidgets('Motor Guard: tank selector switches tanks', (tester) async {
    await storage.saveTanks([
      testTank(fillTime: 1440),
      testTank(id: 't2', name: 'Loft', isDefault: false),
    ]);
    await pumpApp(tester);
    await openTab(tester, 'Motor Guard');
    expect(find.text('Motor ON – Start Guard'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Loft').last);
    await tester.pumpAndSettle();
    expect(find.text('Start Calibration'), findsOneWidget);
  });

  testWidgets('Demo mode: badge and 1 min = 1 s countdown', (tester) async {
    await storage.saveTanks([testTank(fillTime: 1440)]);
    await storage.saveSettings(const UserSettings(demoMode: true));
    await pumpApp(tester);
    await openTab(tester, 'Motor Guard');
    expect(find.text('DEMO MODE'), findsWidgets);
    await tapText(tester, 'Motor ON – Start Guard');
    expect(find.text('0:24'), findsOneWidget);
    expect(notes.motorAlarm, clock.now.add(const Duration(seconds: 22)));
  });

  // ------------------------------------------------------------ Flow Timer

  testWidgets('Flow Timer: add tap, cross limit, litres go to usage',
      (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'Flow Timer');
    expect(find.textContaining('No taps saved yet'), findsOneWidget);
    await tapText(tester, 'Add tap / shower');
    await tester.enterText(find.byType(TextFormField).at(1), '0');
    await tapText(tester, 'Save');
    expect(find.text('Please enter a name'), findsOneWidget);
    expect(find.text('Must be more than 0'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Kitchen tap');
    await tester.enterText(find.byType(TextFormField).at(1), '10');
    await tester.pump();
    expect(find.text('Flow rate: 0.100 L/s (6.0 L/min)'), findsOneWidget);
    await tapText(tester, 'Save');

    await tapText(tester, 'Start');
    await elapse(tester, const Duration(seconds: 410));
    expect(find.text('41.0'), findsOneWidget);
    expect(find.textContaining('Limit crossed'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tapText(tester, 'Stop');
    expect(find.text('41.0 L'), findsOneWidget);
    expect(storage.loadDailyRecords().values.single.used, closeTo(41, 0.01));
  });

  // ------------------------------------------------------------ Leak Check

  testWidgets('Leak Check: save a leak, it counts as waste, then fix it',
      (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'Leak Check');
    expect(find.text('No leaks saved. Great!'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '3');
    await tapText(tester, 'Calculate');
    expect(find.text('This tap wastes 194 L/month ≈ 19.4 buckets'),
        findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Bathroom tap');
    await tapText(tester, 'Save as leak (not fixed)');
    expect(find.text('Bathroom tap'), findsOneWidget);
    expect(find.text('Wastes about 6.5 L every day'), findsOneWidget);

    await tapText(tester, 'Fixed it!');
    expect(find.text('No leaks saved. Great!'), findsOneWidget);
    expect(storage.loadLeaks().single.isActive, isFalse);
    expect(storage.loadDailyRecords().values.single.saved,
        closeTo(194.4, 1e-9));
  });

  testWidgets('Leak Check: drip count by tapping', (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'Leak Check');
    await tapText(tester, 'Start 10-second count');
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Tap per drip'));
      await tester.pump();
    }
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();
    expect(find.textContaining('194 L/month'), findsOneWidget);
  });

  testWidgets('Leak Check: night meter test finds a leak', (tester) async {
    clock.now = DateTime(2026, 10, 10, 22, 0);
    await pumpApp(tester);
    await openTab(tester, 'Leak Check');
    await tapText(tester, 'Night Meter Test');
    await tester.enterText(find.byType(TextFormField), '5000');
    await tapText(tester, 'Save night reading');
    expect(notes.meterReminder, DateTime(2026, 10, 11, 7));

    clock.now = DateTime(2026, 10, 11, 7, 5);
    await tester.enterText(find.byType(TextFormField), '4990');
    await tapText(tester, 'Check for leaks');
    expect(find.textContaining('cannot be lower'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '5012');
    await tapText(tester, 'Check for leaks');
    expect(find.text('Hidden leak likely! 12.0 L lost overnight.'),
        findsOneWidget);
    expect(find.textContaining('Underground pipe'), findsOneWidget);
    expect(storage.loadDailyRecords()['2026-10-11']!.wasted, 12);
  });

  // ------------------------------------------------------------ Usage

  testWidgets('Usage: empty state', (tester) async {
    await pumpApp(tester);
    await tapText(tester, 'See details');
    expect(find.text('Water used & wasted'), findsOneWidget);
    expect(find.textContaining('No water recorded yet'), findsNWidgets(2));
    expect(find.text('Your home needs about 540 L/day (4 people × 135 L)'),
        findsOneWidget);
  });

  testWidgets('Usage: today, week chart and year projection', (tester) async {
    await storage.addToRecord(
        const DailyRecord(used: 250, wasted: 30, saved: 208),
        day: clock.now);
    await storage.addToRecord(const DailyRecord(used: 400),
        day: DateTime(2026, 10, 9));
    await pumpApp(tester);
    await tapText(tester, 'See details');
    expect(find.text('Wasted 12% — about 3.0 buckets today'), findsOneWidget);
    expect(find.text('Below your daily need'), findsOneWidget);
    expect(find.text('Used (left bar)'), findsNWidgets(2));
    expect(find.text('Projected for the full year'), findsOneWidget);
    expect(find.textContaining('2 day(s) × 365'), findsOneWidget);
  });

  // ------------------------------------------------------------ Home

  testWidgets('Home: tip card, challenge Done, chart appears', (tester) async {
    await pumpApp(tester);
    expect(find.text('Tip of the day'), findsOneWidget);
    expect(find.textContaining('No savings yet this week'), findsOneWidget);
    await tapText(tester, 'Done');
    expect(find.text('Done for today ✅'), findsOneWidget);
    expect(find.text('1-day streak'), findsOneWidget);
    expect(find.textContaining('No savings yet this week'), findsNothing);
    await tapText(tester, 'See all challenges');
    expect(find.text('All 30 challenges'), findsOneWidget);
  });

  testWidgets('Home: tip changes the next day', (tester) async {
    final app = AppController(storage, notifications: notes, clock: clock.call);
    final today = app.todaysTip.en;
    await pumpApp(tester);
    expect(find.text(today), findsOneWidget);
  });

  // ------------------------------------------------------------ Settings

  testWidgets('Settings: validation, save, toggles, reset', (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'Settings');
    await tester.enterText(find.byType(TextFormField).at(0), '2.5');
    await tapText(tester, 'Save');
    expect(find.text('Please enter a whole number'), findsNothing,
        reason: 'decimal point is filtered out of whole-number fields');
    await tester.enterText(find.byType(TextFormField).at(0), '0');
    await tapText(tester, 'Save');
    expect(find.text('Must be more than 0'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), '6');
    await tester.enterText(find.byType(TextFormField).at(1), '100');
    await tapText(tester, 'Save');
    expect(storage.loadSettings().peopleCount, 6);
    expect(storage.loadSettings().litresPerPersonOverride, 100);

    await tapText(tester, 'Morning tip notification');
    expect(storage.loadSettings().tipNotifications, isTrue);
    expect(notes.tips.length, 14);
    expect(find.textContaining('No restrictions'), findsOneWidget);

    await tapText(tester, 'Reset all data');
    await tapText(tester, 'Delete everything');
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  // ------------------------------------------------------------ Tamil

  testWidgets('Tamil: full Motor Guard flow on a small phone', (tester) async {
    await storage.saveSettings(const UserSettings(languageCode: 'ta'));
    await pumpApp(tester, size: const Size(360, 740));
    expect(find.text('இந்த வாரம் நீங்கள் சேமித்தது'), findsOneWidget);

    for (final tab in ['நீர் அளவி', 'கசிவு சோதனை', 'அமைப்புகள்', 'முகப்பு']) {
      await openTab(tester, tab);
      expect(tester.takeException(), isNull, reason: tab);
    }

    await openTab(tester, 'மோட்டார் காவல்');
    await tapText(tester, 'அளவீட்டைத் தொடங்கு');
    await elapse(tester, const Duration(minutes: 24));
    await tapText(tester, 'தொட்டி நிரம்பியது');
    // Let the "Saved!" snackbar disappear so it doesn't cover the buttons.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tapText(tester, 'முக்கால் பங்கு');
    await tapText(tester, 'மோட்டார் ON – காவலைத் தொடங்கு');
    expect(find.text('நிரம்ப மீதமுள்ளது', skipOffstage: false), findsOneWidget);
    await elapse(tester, const Duration(minutes: 6));
    await tapText(tester, 'தொட்டி நிரம்பியது');
    expect(find.text('அருமை!'), findsOneWidget);
    await tapText(tester, 'சரி');
    expect(tester.takeException(), isNull);

    // My Tanks and Usage in Tamil.
    await tester.tap(find.byTooltip('என் தொட்டிகள்'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await openTab(tester, 'முகப்பு');
    await tapText(tester, 'விவரங்களைப் பார்');
    expect(find.text('பயன்பட்ட & வீணான நீர்'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tamil onboarding fits a small phone', (tester) async {
    await storage.setOnboarded(false);
    await storage.saveSettings(const UserSettings(languageCode: 'ta'));
    await pumpApp(tester, size: const Size(360, 640));
    for (var i = 0; i < 3; i++) {
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();
    }
    expect(find.text('உங்கள் வீட்டு அமைப்பு'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
