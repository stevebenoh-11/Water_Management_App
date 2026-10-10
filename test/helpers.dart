import 'package:jalmitra/l10n/app_strings.dart';
import 'package:jalmitra/services/notification_service.dart';
import 'package:jalmitra/services/storage_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Records scheduled alarms instead of calling the Android plugin.
class FakeNotifications implements NotificationService {
  DateTime? motorAlarm;
  DateTime? meterReminder;
  bool enabled = true;
  int permissionRequests = 0;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermissions() async {
    permissionRequests++;
    return enabled;
  }

  @override
  Future<bool> notificationsEnabled() async => enabled;

  @override
  Future<void> scheduleMotorAlarm(DateTime when, AppStrings s) async =>
      motorAlarm = when;

  @override
  Future<void> cancelMotorAlarm() async => motorAlarm = null;

  @override
  Future<void> scheduleMeterReminder(DateTime when, AppStrings s) async =>
      meterReminder = when;

  @override
  Future<void> cancelMeterReminder() async => meterReminder = null;

  @override
  Future<void> cancelAll() async {
    motorAlarm = null;
    meterReminder = null;
  }
}

/// Adjustable clock for tests.
class FakeClock {
  FakeClock(this.now);
  DateTime now;
  DateTime call() => now;
  void advance(Duration d) => now = now.add(d);
}

/// Fresh in-memory storage.
Future<StorageService> freshStorage() async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  return StorageService.create();
}
