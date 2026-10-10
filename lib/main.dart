import 'package:flutter/material.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Storage Service
  final storageService = await StorageService.getInstance();

  // Initialize Local Notifications
  await NotificationService().initialize();

  runApp(JalMitraApp(storageService: storageService));
}

class JalMitraApp extends StatelessWidget {
  final StorageService storageService;

  const JalMitraApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    final settings = storageService.getUserSettings();

    return MaterialApp(
      title: 'JalMitra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: settings.isOnboardingCompleted
          ? MainScreen(storageService: storageService)
          : OnboardingScreen(storageService: storageService),
    );
  }
}
