enum TankType { overhead, sump, loft, other }

enum TankMaterial {
  plastic,
  concrete,
  stainlessSteel,
  galvanisedIron,
  ferroCement,
  brick,
  other,
}

enum TankShape { verticalCylinder, horizontalCylinder, rectangular }

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

/// One water tank in the home, with its own motor and learned fill time.
class TankProfile {
  const TankProfile({
    required this.id,
    required this.name,
    this.type = TankType.overhead,
    this.material = TankMaterial.plastic,
    this.shape = TankShape.verticalCylinder,
    required this.capacityLitres,
    this.diameterM,
    this.lengthM,
    this.widthM,
    this.heightM,
    this.motorHp = 1,
    this.overflowMinutes = 5,
    this.fillTimeSeconds,
    this.fillCount = 0,
    this.lastCleaned,
    this.cleaningIntervalDays = 180,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final TankType type;
  final TankMaterial material;
  final TankShape shape;

  /// Capacity in litres (typed, or calculated from the dimensions below).
  final double capacityLitres;

  /// Optional dimensions in metres, kept so the user can edit them later.
  final double? diameterM;
  final double? lengthM;
  final double? widthM;
  final double? heightM;

  final double motorHp;

  /// Typical minutes this tank overflows before anyone notices.
  final double overflowMinutes;

  /// Learned seconds to fill from empty (null = not calibrated).
  final double? fillTimeSeconds;

  /// Number of runs the fill time was learned from.
  final int fillCount;

  final DateTime? lastCleaned;
  final int cleaningIntervalDays;
  final bool isDefault;

  bool get isCalibrated => fillTimeSeconds != null;

  TankProfile copyWith({
    String? name,
    TankType? type,
    TankMaterial? material,
    TankShape? shape,
    double? capacityLitres,
    double? diameterM,
    double? lengthM,
    double? widthM,
    double? heightM,
    double? motorHp,
    double? overflowMinutes,
    double? fillTimeSeconds,
    int? fillCount,
    DateTime? lastCleaned,
    int? cleaningIntervalDays,
    bool? isDefault,
    bool clearFillTime = false,
    bool clearDimensions = false,
    bool clearLastCleaned = false,
  }) {
    return TankProfile(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      material: material ?? this.material,
      shape: shape ?? this.shape,
      capacityLitres: capacityLitres ?? this.capacityLitres,
      diameterM: clearDimensions ? null : diameterM ?? this.diameterM,
      lengthM: clearDimensions ? null : lengthM ?? this.lengthM,
      widthM: clearDimensions ? null : widthM ?? this.widthM,
      heightM: clearDimensions ? null : heightM ?? this.heightM,
      motorHp: motorHp ?? this.motorHp,
      overflowMinutes: overflowMinutes ?? this.overflowMinutes,
      fillTimeSeconds:
          clearFillTime ? null : fillTimeSeconds ?? this.fillTimeSeconds,
      fillCount: clearFillTime ? 0 : fillCount ?? this.fillCount,
      lastCleaned: clearLastCleaned ? null : lastCleaned ?? this.lastCleaned,
      cleaningIntervalDays: cleaningIntervalDays ?? this.cleaningIntervalDays,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'material': material.name,
        'shape': shape.name,
        'capacityLitres': capacityLitres,
        'diameterM': diameterM,
        'lengthM': lengthM,
        'widthM': widthM,
        'heightM': heightM,
        'motorHp': motorHp,
        'overflowMinutes': overflowMinutes,
        'fillTimeSeconds': fillTimeSeconds,
        'fillCount': fillCount,
        'lastCleaned': lastCleaned?.toIso8601String(),
        'cleaningIntervalDays': cleaningIntervalDays,
        'isDefault': isDefault,
      };

  factory TankProfile.fromJson(Map<String, dynamic> json) {
    double? d(String k) => (json[k] as num?)?.toDouble();
    return TankProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      type: _enumByName(TankType.values, json['type'], TankType.overhead),
      material: _enumByName(
          TankMaterial.values, json['material'], TankMaterial.plastic),
      shape: _enumByName(
          TankShape.values, json['shape'], TankShape.verticalCylinder),
      capacityLitres: d('capacityLitres') ?? 1000,
      diameterM: d('diameterM'),
      lengthM: d('lengthM'),
      widthM: d('widthM'),
      heightM: d('heightM'),
      motorHp: d('motorHp') ?? 1,
      overflowMinutes: d('overflowMinutes') ?? 5,
      fillTimeSeconds: d('fillTimeSeconds'),
      fillCount: (json['fillCount'] as num?)?.toInt() ?? 0,
      lastCleaned: json['lastCleaned'] == null
          ? null
          : DateTime.tryParse(json['lastCleaned'] as String),
      cleaningIntervalDays:
          (json['cleaningIntervalDays'] as num?)?.toInt() ?? 180,
      isDefault: json['isDefault'] == true,
    );
  }
}
