import 'package:flutter_test/flutter_test.dart';
import 'package:jalmitra/models/user_settings.dart';
import 'package:jalmitra/widgets/number_field.dart';

void main() {
  group('positiveNumberError', () {
    test('rejects empty input', () {
      expect(positiveNumberError(null), 'errEmpty');
      expect(positiveNumberError(''), 'errEmpty');
      expect(positiveNumberError('   '), 'errEmpty');
    });

    test('rejects non-numbers', () {
      expect(positiveNumberError('abc'), 'errNotNumber');
      expect(positiveNumberError('1.2.3'), 'errNotNumber');
      expect(positiveNumberError('.'), 'errNotNumber');
    });

    test('rejects zero and negatives', () {
      expect(positiveNumberError('0'), 'errPositive');
      expect(positiveNumberError('0.0'), 'errPositive');
      expect(positiveNumberError('-5'), 'errPositive');
    });

    test('enforces max', () {
      expect(positiveNumberError('21', max: 20), 'errTooLarge');
      expect(positiveNumberError('20', max: 20), isNull);
    });

    test('accepts valid positive numbers', () {
      expect(positiveNumberError('1000'), isNull);
      expect(positiveNumberError('0.5'), isNull);
      expect(positiveNumberError(' 6 '), isNull);
    });
  });

  test('formatNumber drops trailing .0', () {
    expect(formatNumber(1000), '1000');
    expect(formatNumber(0.5), '0.5');
    expect(formatNumber(1.5), '1.5');
  });

  test('whole numbers', () {
    expect(positiveNumberError('4', wholeNumber: true), isNull);
    expect(positiveNumberError('4.5', wholeNumber: true), 'errWholeNumber');
  });

  group('UserSettings', () {
    test('defaults match the spec', () {
      const s = UserSettings();
      expect(s.peopleCount, 4);
      expect(s.areaType, AreaType.city);
      expect(s.defaultMotorHp, 1);
      expect(s.electricityRate, 6);
      expect(s.defaultOverflowMinutes, 5);
      expect(s.languageCode, 'en');
      expect(s.demoMode, isFalse);
      expect(s.tipNotifications, isFalse);
    });

    test('JSON round trip', () {
      const s = UserSettings(
        languageCode: 'ta',
        peopleCount: 6,
        areaType: AreaType.village,
        litresPerPersonOverride: 70,
        electricityRate: 7.5,
        defaultMotorHp: 1.5,
        defaultOverflowMinutes: 10,
        demoMode: true,
        tipNotifications: true,
      );
      expect(UserSettings.fromJson(s.toJson()).toJson(), s.toJson());
    });

    test('invalid stored values fall back to defaults', () {
      final r = UserSettings.fromJson({
        'peopleCount': 0,
        'defaultMotorHp': -1,
        'electricityRate': 'x',
        'languageCode': 'fr',
        'areaType': 'moon',
      });
      expect(r.toJson(), const UserSettings().toJson());
    });
  });
}
