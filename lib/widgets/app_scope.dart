import 'package:flutter/widgets.dart';

import '../services/app_controller.dart';

/// Makes the [AppController] available to every widget below it.
class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context');
    return scope!.notifier!;
  }

  /// Reads the controller without listening (safe in initState).
  static AppController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

extension AppScopeContext on BuildContext {
  AppController get app => AppScope.of(this);

  /// Translated string for [key] in the current language.
  String tr(String key, [Map<String, String> params = const {}]) =>
      AppScope.of(this).strings.get(key, params);
}
