import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../l10n/app_strings.dart';
import 'home_screen.dart';
import 'motor_guard_screen.dart';
import 'flow_timer_screen.dart';
import 'leak_check_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  final StorageService storageService;

  const MainScreen({super.key, required this.storageService});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        storageService: widget.storageService,
        onTabSwitch: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      MotorGuardScreen(storageService: widget.storageService),
      FlowTimerScreen(storageService: widget.storageService),
      LeakCheckScreen(storageService: widget.storageService),
      SettingsScreen(storageService: widget.storageService),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.storageService.getUserSettings().language;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey.shade600,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: AppStrings.get('home', lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shield_rounded),
            label: AppStrings.get('motor_guard', lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.timer_rounded),
            label: AppStrings.get('flow_timer', lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.water_drop_rounded),
            label: AppStrings.get('leak_check', lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_rounded),
            label: AppStrings.get('settings', lang),
          ),
        ],
      ),
    );
  }
}
