import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jalmitra/main.dart';
import 'package:jalmitra/models/tank_profile.dart';
import 'package:jalmitra/models/user_settings.dart';
import 'package:jalmitra/screens/main_shell.dart';
import 'package:jalmitra/services/app_controller.dart';
import 'package:jalmitra/services/storage_service.dart';

import 'helpers.dart';

void main() {
  late StorageService storage;
  late FakeNotifications notes;

  setUp(() async {
    storage = await freshStorage();
    notes = FakeNotifications();
  });

  Future<void> pumpApp(WidgetTester tester,
      {Size size = const Size(420, 1800)}) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(JalMitraApp(
        controller: AppController(storage, notifications: notes)));
    await tester.pumpAndSettle();
  }

  Future<void> goToSetup(WidgetTester tester) async {
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester) async {
    final save = find.text('Save and start');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
  }

  testWidgets('first launch shows onboarding and swipes', (tester) async {
    await pumpApp(tester, size: const Size(420, 900));
    expect(find.text('Never let your tank overflow'), findsOneWidget);
    expect(find.byType(MainShell), findsNothing);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Measure every litre'), findsOneWidget);
  });

  testWidgets('language toggle switches to Tamil instantly', (tester) async {
    await pumpApp(tester, size: const Size(420, 900));
    await tester.tap(find.text('தமிழ்'));
    await tester.pumpAndSettle();
    expect(find.text('தொட்டி நிரம்பி வழிய விடாதீர்கள்'), findsOneWidget);
    expect(storage.loadSettings().languageCode, 'ta');
  });

  testWidgets('setup form validates people and capacity', (tester) async {
    await pumpApp(tester);
    await goToSetup(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '0'); // people
    await tester.enterText(fields.at(2), ''); // capacity
    await tapSave(tester);
    expect(find.text('Must be more than 0'), findsOneWidget);
    expect(find.text('Please enter a value'), findsOneWidget);
    expect(storage.isOnboarded, isFalse);
  });

  testWidgets('valid setup saves home + first tank, then asks permission',
      (tester) async {
    await pumpApp(tester);
    await goToSetup(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '5');
    await tester.tap(find.text('Village'));
    await tester.enterText(fields.at(1), 'Roof tank');
    await tester.enterText(fields.at(2), '2000');
    await tapSave(tester);

    expect(storage.isOnboarded, isTrue);
    final s = storage.loadSettings();
    expect(s.peopleCount, 5);
    expect(s.areaType, AreaType.village);
    final tank = storage.loadTanks().single;
    expect(tank.name, 'Roof tank');
    expect(tank.capacityLitres, 2000);
    expect(tank.material, TankMaterial.plastic);
    expect(tank.isDefault, isTrue);

    expect(find.text('Allow alarms & notifications'), findsOneWidget);
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(notes.permissionRequests, 1);
    expect(find.text('This week you saved'), findsOneWidget);
  });

  testWidgets('denying permission is handled gracefully', (tester) async {
    await storage.setOnboarded(true);
    await storage.saveTanks([testTank()]);
    notes.enabled = false;
    await pumpApp(tester);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(notes.permissionRequests, 0);
    await tester.tap(find.descendant(
        of: find.byType(NavigationBar), matching: find.text('Motor Guard')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Notifications are off'), findsOneWidget);
    expect(find.text('Allow alarms'), findsOneWidget);
  });
}
