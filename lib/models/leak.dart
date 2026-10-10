/// A dripping tap saved from the Drip Calculator. While not fixed, its
/// daily loss counts as wasted water every day.
class Leak {
  const Leak({
    required this.id,
    required this.name,
    required this.dripsPer10s,
    required this.litresPerDay,
    required this.createdAt,
    this.fixedAt,
  });

  final String id;
  final String name;
  final int dripsPer10s;
  final double litresPerDay;
  final DateTime createdAt;

  /// When the user tapped "Fixed it!" (null = still leaking).
  final DateTime? fixedAt;

  bool get isActive => fixedAt == null;

  Leak fixed(DateTime when) => Leak(
        id: id,
        name: name,
        dripsPer10s: dripsPer10s,
        litresPerDay: litresPerDay,
        createdAt: createdAt,
        fixedAt: when,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dripsPer10s': dripsPer10s,
        'litresPerDay': litresPerDay,
        'createdAt': createdAt.toIso8601String(),
        'fixedAt': fixedAt?.toIso8601String(),
      };

  factory Leak.fromJson(Map<String, dynamic> json) => Leak(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        dripsPer10s: (json['dripsPer10s'] as num).toInt(),
        litresPerDay: (json['litresPerDay'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        fixedAt: json['fixedAt'] == null
            ? null
            : DateTime.parse(json['fixedAt'] as String),
      );
}
