import 'package:jalmitra/l10n/app_strings.dart';
import 'package:jalmitra/models/tank_profile.dart';
import 'package:jalmitra/services/notification_service.dart';
import 'package:jalmitra/services/storage_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Records scheduled alarms instead of calling the Android plugin.
class FakeNotifications implements NotificationService {
  DateTime? motorAlarm;
  String? motorAlarmTitle;
  DateTime? meterReminder;
  List<({DateTime when, String body})> tips = [];
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
  Future<void> scheduleMotorAlarm(
      DateTime when, AppStrings s, String tankName) async {
    motorAlarm = when;
    motorAlarmTitle = s.get('alarmTitle', {'tank': tankName});
  }

  @override
  Future<void> cancelMotorAlarm() async => motorAlarm = null;

  @override
  Future<void> scheduleMeterReminder(DateTime when, AppStrings s) async =>
      meterReminder = when;

  @override
  Future<void> cancelMeterReminder() async => meterReminder = null;

  @override
  Future<void> scheduleTips(
          List<({DateTime when, String body})> tips, AppStrings s) async =>
      this.tips = tips;

  @override
  Future<void> cancelTips() async => tips = [];

  @override
  Future<void> cancelAll() async {
    motorAlarm = null;
    meterReminder = null;
    tips = [];
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

/// A 1000 L overhead tank, optionally calibrated.
TankProfile testTank({
  String id = 't1',
  String name = 'Overhead tank',
  double? fillTime,
  int fillCount = 0,
  bool isDefault = true,
  double capacity = 1000,
}) =>
    TankProfile(
      id: id,
      name: name,
      capacityLitres: capacity,
      fillTimeSeconds: fillTime,
      fillCount: fillTime == null ? 0 : (fillCount == 0 ? 1 : fillCount),
      isDefault: isDefault,
    );
