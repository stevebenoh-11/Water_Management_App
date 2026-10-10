import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jalmitra/main.dart';
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

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(JalMitraApp(
        controller: AppController(storage, notifications: notes)));
    await tester.pumpAndSettle();
  }

  Future<void> goToSetup(WidgetTester tester) async {
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
  }

  testWidgets('first launch shows onboarding page 1', (tester) async {
    await pumpApp(tester);
    expect(find.text('Never let your tank overflow'), findsOneWidget);
    expect(find.byType(MainShell), findsNothing);
  });

  testWidgets('Next swipes through the info pages', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Measure every litre'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Set up my home'), findsOneWidget);
  });

  testWidgets('language toggle switches to Tamil instantly', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('தமிழ்'));
    await tester.pumpAndSettle();
    expect(find.text('தொட்டி நிரம்பி வழிய விடாதீர்கள்'), findsOneWidget);
    expect(storage.loadSettings().languageCode, 'ta');
  });

  testWidgets('setup form rejects zero and empty values', (tester) async {
    await pumpApp(tester);
    await goToSetup(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '0');
    await tester.enterText(fields.at(1), '');
    await tester.tap(find.text('Save and start'));
    await tester.pumpAndSettle();

    expect(find.text('Must be more than 0'), findsOneWidget);
    expect(find.text('Please enter a value'), findsOneWidget);
    expect(storage.isOnboarded, isFalse);
  });

  testWidgets('valid setup saves, asks permission politely, opens app',
      (tester) async {
    await pumpApp(tester);
    await goToSetup(tester);

    await tester.enterText(find.byType(TextFormField).at(0), '2000');
    await tester.tap(find.text('Save and start'));
    await tester.pumpAndSettle();

    expect(storage.isOnboarded, isTrue);
    expect(storage.loadSettings().tankCapacityLitres, 2000);
    expect(storage.loadSettings().motorHp, 1);
    expect(find.byType(MainShell), findsOneWidget);

    // Polite explanation first, then the Android prompt.
    expect(find.text('Allow alarms & notifications'), findsOneWidget);
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(notes.permissionRequests, 1);
    expect(storage.permissionsAsked, isTrue);
    expect(find.text('This week you saved'), findsOneWidget);
  });

  testWidgets('denying permission is handled gracefully', (tester) async {
    await storage.setOnboarded(true);
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

  testWidgets('bottom navigation switches tabs', (tester) async {
    await storage.setOnboarded(true);
    await storage.setPermissionsAsked(true);
    await pumpApp(tester);
    for (final label in ['Motor Guard', 'Flow Timer', 'Leak Check', 'Settings']) {
      await tester.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, label), findsOneWidget);
    }
  });
}
