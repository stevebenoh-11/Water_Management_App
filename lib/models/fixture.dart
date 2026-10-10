/// A calibrated tap / shower, e.g. "Kitchen tap".
class Fixture {
  const Fixture({
    required this.id,
    required this.name,
    required this.flowRateLps,
  });

  final String id;
  final String name;

  /// Flow rate in litres per second (1 ÷ seconds to fill a 1 L bottle).
  final double flowRateLps;

  Fixture copyWith({String? name, double? flowRateLps}) => Fixture(
        id: id,
        name: name ?? this.name,
        flowRateLps: flowRateLps ?? this.flowRateLps,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'flowRateLps': flowRateLps,
      };

  factory Fixture.fromJson(Map<String, dynamic> json) => Fixture(
        id: json['id'] as String,
        name: json['name'] as String,
        flowRateLps: (json['flowRateLps'] as num).toDouble(),
      );
}
