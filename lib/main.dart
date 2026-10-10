import 'package:flutter/material.dart';

import 'screens/main_shell.dart';
import 'screens/onboarding_screen.dart';
import 'services/app_controller.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.create();
  final notifications = NotificationService();
  await notifications.init();
  runApp(JalMitraApp(
    controller: AppController(storage, notifications: notifications),
  ));
}

class JalMitraApp extends StatelessWidget {
  const JalMitraApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => MaterialApp(
          title: controller.strings.get('appName'),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: controller.onboarded
              ? const MainShell()
              : const OnboardingScreen(),
        ),
      ),
    );
  }
}
