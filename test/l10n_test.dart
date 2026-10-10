import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jalmitra/l10n/app_strings.dart';
import 'package:jalmitra/l10n/tips.dart';
import 'package:jalmitra/models/challenge.dart';
import 'package:jalmitra/models/tank_profile.dart';
import 'package:jalmitra/models/user_settings.dart';
import 'package:jalmitra/widgets/tank_labels.dart';

void main() {
  final en = AppStrings.values['en']!;
  final ta = AppStrings.values['ta']!;

  test('every English key has a Tamil translation', () {
    final missing = en.keys.where((k) => !ta.containsKey(k)).toList();
    expect(missing, isEmpty, reason: 'Missing Tamil keys: $missing');
  });

  test('Tamil has no keys that English lacks', () {
    final extra = ta.keys.where((k) => !en.containsKey(k)).toList();
    expect(extra, isEmpty, reason: 'Extra Tamil keys: $extra');
  });

  test('no empty strings', () {
    for (final map in [en, ta]) {
      for (final e in map.entries) {
        expect(e.value.trim(), isNotEmpty, reason: e.key);
      }
    }
  });

  test('placeholders match between languages', () {
    final re = RegExp(r'\{(\w+)\}');
    for (final key in en.keys) {
      final enParams = re.allMatches(en[key]!).map((m) => m[1]).toSet();
      final taParams = re.allMatches(ta[key]!).map((m) => m[1]).toSet();
      expect(taParams, enParams, reason: key);
    }
  });

  test('every key used in lib/ exists in the strings file', () {
    // Literal keys passed to tr('...') or s.get('...'), plus keys stored in
    // `key:` / `title:` / `body:` records and step/tip lists.
    final patterns = [
      RegExp(r"""tr\(\s*'([A-Za-z0-9_]+)'"""),
      RegExp(r"""\.get\('([A-Za-z0-9_]+)'"""),
      RegExp(r"""(?:key|title|body): '([A-Za-z0-9_]+)'"""),
      RegExp(r"""\(\s*Icons\.\w+,\s*[\w.]+,\s*'([A-Za-z0-9_]+)'"""),
      RegExp(r"""'((?:calibrateStep|leakTip)\d)'"""),
    ];
    final used = <String>{};
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.contains('l10n')) continue;
      final src = file.readAsStringSync();
      for (final p in patterns) {
        used.addAll(p.allMatches(src).map((m) => m[1]!));
      }
    }
    // Dynamic families.
    used.addAll([for (var d = 1; d <= 7; d++) 'day$d']);
    used.addAll(['badge3', 'badge7', 'badge30', 'am', 'pm']);
    used.addAll([for (var m = 1; m <= 12; m++) 'month$m']);
    used.addAll(['usedLeftBar', 'wastedRightBar', 'editTank', 'addTank']);
    used.addAll(TankType.values.map(tankTypeKey));
    used.addAll(TankMaterial.values.map(tankMaterialKey));
    used.addAll(TankShape.values.map(tankShapeKey));
    used.addAll(AreaType.values.map(areaKey));
    used.addAll(allChallenges.map((c) => c.textKey));

    final missing = used.where((k) => !en.containsKey(k)).toList()..sort();
    expect(missing, isEmpty, reason: 'Keys used but not defined: $missing');
  });

  test('30 challenges with unique ids and positive litres', () {
    expect(allChallenges.length, 30);
    expect(allChallenges.map((c) => c.id).toSet().length, 30);
    expect(allChallenges.every((c) => c.litres > 0), isTrue);
  });

  test('at least 60 tips, each in English and Tamil, no duplicates', () {
    expect(allTips.length, greaterThanOrEqualTo(60));
    expect(allTips.every((t) => t.en.trim().isNotEmpty && t.ta.trim().isNotEmpty),
        isTrue);
    expect(allTips.map((t) => t.en).toSet().length, allTips.length);
    expect(allTips.map((t) => t.ta).toSet().length, allTips.length);
  });

  test('get() replaces placeholders and falls back sensibly', () {
    const s = AppStrings('en');
    expect(s.get('errTooLarge', {'max': '20'}), 'Must be 20 or less');
    expect(const AppStrings('ta').get('navHome'), 'முகப்பு');
    expect(s.get('noSuchKey'), 'noSuchKey');
  });
}
