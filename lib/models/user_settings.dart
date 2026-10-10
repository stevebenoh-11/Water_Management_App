import 'dart:convert';

class UserSettings {
  final double tankCapacityLitres;
  final double motorHp;
  final double electricityRate;
  final double typicalOverflowMinutes;
  final bool isDemoMode;
  final String language;
  final bool isOnboardingCompleted;

  UserSettings({
    this.tankCapacityLitres = 1000.0,
    this.motorHp = 1.0,
    this.electricityRate = 6.0,
    this.typicalOverflowMinutes = 5.0,
    this.isDemoMode = false,
    this.language = 'en',
    this.isOnboardingCompleted = false,
  });

  UserSettings copyWith({
    double? tankCapacityLitres,
    double? motorHp,
    double? electricityRate,
    double? typicalOverflowMinutes,
    bool? isDemoMode,
    String? language,
    bool? isOnboardingCompleted,
  }) {
    return UserSettings(
      tankCapacityLitres: tankCapacityLitres ?? this.tankCapacityLitres,
      motorHp: motorHp ?? this.motorHp,
      electricityRate: electricityRate ?? this.electricityRate,
      typicalOverflowMinutes: typicalOverflowMinutes ?? this.typicalOverflowMinutes,
      isDemoMode: isDemoMode ?? this.isDemoMode,
      language: language ?? this.language,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tankCapacityLitres': tankCapacityLitres,
      'motorHp': motorHp,
      'electricityRate': electricityRate,
      'typicalOverflowMinutes': typicalOverflowMinutes,
      'isDemoMode': isDemoMode,
      'language': language,
      'isOnboardingCompleted': isOnboardingCompleted,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      tankCapacityLitres: (map['tankCapacityLitres'] as num?)?.toDouble() ?? 1000.0,
      motorHp: (map['motorHp'] as num?)?.toDouble() ?? 1.0,
      electricityRate: (map['electricityRate'] as num?)?.toDouble() ?? 6.0,
      typicalOverflowMinutes: (map['typicalOverflowMinutes'] as num?)?.toDouble() ?? 5.0,
      isDemoMode: map['isDemoMode'] as bool? ?? false,
      language: map['language'] as String? ?? 'en',
      isOnboardingCompleted: map['isOnboardingCompleted'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserSettings.fromJson(String source) => UserSettings.fromMap(json.decode(source));
}
