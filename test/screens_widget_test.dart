import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jalmitra/main.dart';
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
  });

  Future<void> pumpApp(WidgetTester tester,
      {Size size = const Size(420, 1800), String lang = 'en'}) async {
    if (lang != 'en') {
      await storage.saveSettings(UserSettings(languageCode: lang));
    }
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

  /// Advances the fake clock and lets the 1-second tickers run.
  Future<void> elapse(WidgetTester tester, Duration d) async {
    clock.advance(d);
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('Motor Guard: calibrate, guard a half tank, Tank Full',
      (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'Motor Guard');

    await tester.tap(find.text('Start Calibration'));
    await tester.pumpAndSettle();
    expect(find.text('Calibrating…'), findsOneWidget);

    await elapse(tester, const Duration(minutes: 24));
    await tester.tap(find.text('Tank Full'));
    await tester.pumpAndSettle();
    expect(find.text('Saved! Your tank fills in about 24 min.'), findsOneWidget);
    expect(storage.fillTime, 1440);

    await tester.tap(find.text('Half'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tank will be full in 12 min'), findsOneWidget);

    await tester.tap(find.text('Motor ON – Start Guard'));
    await tester.pumpAndSettle();
    expect(find.text('Expected full at'), findsOneWidget);
    expect(find.text('6:36 AM'), findsOneWidget);
    expect(find.text('6:34 AM'), findsOneWidget); // alarm 2 min before
    expect(notes.motorAlarm, DateTime(2026, 10, 10, 6, 34));

    await elapse(tester, const Duration(minutes: 12));
    expect(find.text('Tank should be full now!'), findsOneWidget);

    await tester.tap(find.text('Tank Full'));
    await tester.pumpAndSettle();
    expect(find.text('Great!'), findsOneWidget);
    expect(find.text('You saved ~208 L and ₹0.37 today.'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Home reflects the savings.
    await openTab(tester, 'Home');
    expect(find.text('208'), findsOneWidget);
  });

  testWidgets('Motor Guard: cancel asks for confirmation', (tester) async {
    await storage.saveCalibration(1440, 1);
    await pumpApp(tester);
    await openTab(tester, 'Motor Guard');
    await tester.tap(find.text('Motor ON – Start Guard'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stop guard'));
    await tester.pumpAndSettle();
    expect(notes.motorAlarm, isNull);
    expect(find.text('Motor ON – Start Guard'), findsOneWidget);
  });

  testWidgets('Demo mode shows badge and 1 min = 1 s countdown',
      (tester) async {
    await storage.saveCalibration(1440, 1);
    await storage.saveSettings(const UserSettings(demoMode: true));
    await pumpApp(tester);
    await openTab(tester, 'Motor Guard');
    expect(find.text('DEMO MODE'), findsWidgets);
    await tester.tap(find.text('Motor ON – Start Guard'));
    await tester.pumpAndSettle();
    expect(find.text('0:24'), findsOneWidget);
    expect(notes.motorAlarm, clock.now.add(const Duration(seconds: 22)));
  });

  testWidgets('Flow Timer: add fixture, cross limit, save history',
      (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'Flow Timer');
    expect(find.textContaining('No taps saved yet'), findsOneWidget);

    await tester.tap(find.text('Add tap / shower'));
    await tester.pumpAndSettle();
    // Validation: empty name and zero seconds.
    await tester.enterText(find.byType(TextFormField).at(1), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter a name'), findsOneWidget);
    expect(find.text('Must be more than 0'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Kitchen tap');
    await tester.enterText(find.byType(TextFormField).at(1), '10');
    await tester.pump();
    expect(find.text('Flow rate: 0.100 L/s (6.0 L/min)'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Kitchen tap'), findsOneWidget);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    await elapse(tester, const Duration(seconds: 200));
    expect(find.text('20.0'), findsOneWidget);
    expect(find.textContaining('Limit crossed'), findsNothing);

    await elapse(tester, const Duration(seconds: 210));
    expect(find.text('41.0'), findsOneWidget);
    expect(find.textContaining('Limit crossed'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2)); // vibration pattern

    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();
    expect(find.text('41.0 L'), findsOneWidget); // history entry
    expect(storage.loadFlowHistory().single.exceededLimit, isTrue);
  });

  testWidgets('Leak Check: drip count by tapping', (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'Leak Check');
    await tester.tap(find.text('Start 10-second count'));
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Tap per drip'));
      await tester.pump();
    }
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle();
    expect(find.text('This tap wastes 194 L/month ≈ 19.4 buckets'),
        findsOneWidget);

    await tester.tap(find.text('Fixed it!'));
    await tester.pumpAndSettle();
    expect(storage.loadDailySavings().values.single.litres,
        closeTo(194.4, 1e-9));
  });

  testWidgets('Leak Check: manual drip entry is validated', (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'Leak Check');
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter a value'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '3');
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
    expect(find.textContaining('194 L/month'), findsOneWidget);
  });

  testWidgets('Leak Check: night meter test finds a leak', (tester) async {
    clock.now = DateTime(2026, 10, 10, 22, 0);
    await pumpApp(tester);
    await openTab(tester, 'Leak Check');
    await tester.tap(find.text('Night Meter Test'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '5000');
    await tester.tap(find.text('Save night reading'));
    await tester.pumpAndSettle();
    expect(notes.meterReminder, DateTime(2026, 10, 11, 7));

    clock.now = DateTime(2026, 10, 11, 7, 5);
    await tester.enterText(find.byType(TextFormField), '4990');
    await tester.tap(find.text('Check for leaks'));
    await tester.pumpAndSettle();
    expect(find.textContaining('cannot be lower'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '5012');
    await tester.tap(find.text('Check for leaks'));
    await tester.pumpAndSettle();
    expect(find.text('Hidden leak likely! 12.0 L lost overnight.'),
        findsOneWidget);
    expect(find.text('Where to look'), findsOneWidget);

    await tester.tap(find.text('New test'));
    await tester.pumpAndSettle();
    expect(find.text('Save night reading'), findsOneWidget);
  });

  testWidgets('Leak Check: no leak when readings match', (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'Leak Check');
    await tester.tap(find.text('Night Meter Test'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('m³'));
    await tester.enterText(find.byType(TextFormField), '1234.5');
    await tester.tap(find.text('Save night reading'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '1234.5');
    await tester.tap(find.text('Check for leaks'));
    await tester.pumpAndSettle();
    expect(find.text('No leak detected ✅'), findsOneWidget);
  });

  testWidgets('Home: empty state, then challenge Done updates chart',
      (tester) async {
    await pumpApp(tester);
    expect(find.textContaining('No savings yet this week'), findsOneWidget);
    expect(find.text('0-day streak'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Done for today ✅'), findsOneWidget);
    expect(find.text('1-day streak'), findsOneWidget);
    expect(find.textContaining('No savings yet this week'), findsNothing);

    await tester.tap(find.text('See all challenges'));
    await tester.pumpAndSettle();
    expect(find.text('All 30 challenges'), findsOneWidget);
    expect(find.text('3-day Starter'), findsOneWidget);
  });

  testWidgets('Home: Motor ON button opens Motor Guard', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Motor ON'));
    await tester.pumpAndSettle();
    expect(find.text('Start Calibration'), findsOneWidget);
  });

  testWidgets('Settings: validation, save, demo toggle, reset',
      (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'Settings');

    await tester.enterText(find.byType(TextFormField).at(0), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Must be more than 0'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '1500');
    await tester.enterText(find.byType(TextFormField).at(1), '25');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Must be 20 or less'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), '1.5');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(storage.loadSettings().tankCapacityLitres, 1500);
    expect(storage.loadSettings().motorHp, 1.5);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(storage.loadSettings().demoMode, isTrue);
    expect(find.text('DEMO MODE'), findsWidgets);

    await tester.tap(find.text('Reset all data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete everything'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(storage.isOnboarded, isFalse);
  });

  testWidgets('Tamil: every screen renders on a small phone without overflow',
      (tester) async {
    await storage.saveCalibration(1440, 1);
    await storage.saveSettings(const UserSettings(languageCode: 'ta'));
    await pumpApp(tester, size: const Size(360, 740), lang: 'ta');
    expect(find.text('இந்த வாரம் நீங்கள் சேமித்தது'), findsOneWidget);

    for (final tab in [
      'மோட்டார் காவல்',
      'நீர் அளவி',
      'கசிவு சோதனை',
      'அமைப்புகள்',
      'முகப்பு',
    ]) {
      await openTab(tester, tab);
      expect(tester.takeException(), isNull, reason: tab);
    }

    // Running Motor Guard in Tamil.
    await openTab(tester, 'மோட்டார் காவல்');
    final startGuard = find.text('மோட்டார் ON – காவலைத் தொடங்கு');
    await tester.ensureVisible(startGuard);
    await tester.pumpAndSettle();
    await tester.tap(startGuard);
    await tester.pumpAndSettle();
    expect(find.text('நிரம்ப மீதமுள்ளது'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Night meter tab in Tamil.
    await openTab(tester, 'கசிவு சோதனை');
    await tester.tap(find.text('இரவு மீட்டர் சோதனை'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tamil onboarding fits a small phone', (tester) async {
    await storage.setOnboarded(false);
    await pumpApp(tester, size: const Size(360, 640), lang: 'ta');
    for (var i = 0; i < 3; i++) {
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();
    }
    expect(find.text('உங்கள் வீட்டு அமைப்பு'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
