import 'dart:convert';

class Fixture {
  final String id;
  final String name;
  final double flowRateLps; // Litres per second

  Fixture({
    required this.id,
    required this.name,
    required this.flowRateLps,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'flowRateLps': flowRateLps,
    };
  }

  factory Fixture.fromMap(Map<String, dynamic> map) {
    return Fixture(
      id: map['id'] as String,
      name: map['name'] as String,
      flowRateLps: (map['flowRateLps'] as num).toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Fixture.fromJson(String source) => Fixture.fromMap(json.decode(source));
}
