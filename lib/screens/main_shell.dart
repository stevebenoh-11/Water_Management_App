import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import 'flow_timer_screen.dart';
import 'home_screen.dart';
import 'leak_check_screen.dart';
import 'motor_guard_screen.dart';
import 'settings_screen.dart';

/// Bottom navigation: Home, Motor Guard, Flow Timer, Leak Check, Settings.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static const homeTab = 0;
  static const motorTab = 1;
  static const flowTab = 2;
  static const leakTab = 3;
  static const settingsTab = 4;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = MainShell.homeTab;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _askPermissionsOnce());
    // If a Motor Guard session is running (app reopened), go straight to it.
    if (AppScope.read(context).motorSession != null) _index = MainShell.motorTab;
  }

  /// Politely explains why alarms are needed, then asks Android once.
  /// Denial is handled: Motor Guard shows a warning with a retry button.
  Future<void> _askPermissionsOnce() async {
    final app = AppScope.read(context);
    if (app.permissionsAsked || !mounted) return;
    await app.markPermissionsAsked();
    if (!mounted) return;
    final allow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.alarm, size: 56, color: AppColors.blue),
        title: Text(ctx.tr('permTitle')),
        content:
            Text(ctx.tr('permBody'), style: Theme.of(ctx).textTheme.bodyLarge),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.tr('notNow')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.tr('allow')),
          ),
        ],
      ),
    );
    if (allow == true) await app.notifications.requestPermissions();
  }

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onOpenTab: _select),
          const MotorGuardScreen(),
          const FlowTimerScreen(),
          const LeakCheckScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: context.tr('navHome'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.power_settings_new_outlined),
            selectedIcon: const Icon(Icons.power_settings_new),
            label: context.tr('navMotor'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.shower_outlined),
            selectedIcon: const Icon(Icons.shower),
            label: context.tr('navFlow'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.water_drop_outlined),
            selectedIcon: const Icon(Icons.water_drop),
            label: context.tr('navLeak'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: context.tr('navSettings'),
          ),
        ],
      ),
    );
  }
}
