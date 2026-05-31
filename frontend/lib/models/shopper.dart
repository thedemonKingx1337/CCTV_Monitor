class Shopper {
  final String id;
  final double x;
  final double y;
  final String zoneId;
  final String state;
  final double speed;

  Shopper({
    required this.id,
    required this.x,
    required this.y,
    required this.zoneId,
    required this.state,
    required this.speed,
  });

  factory Shopper.fromJson(Map<String, dynamic> json) {
    return Shopper(
      id: json['id'],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      zoneId: json['zone_id'],
      state: json['state'],
      speed: (json['speed'] as num).toDouble(),
    );
  }
}
