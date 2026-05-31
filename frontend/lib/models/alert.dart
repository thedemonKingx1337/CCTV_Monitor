class AnomalyAlert {
  final String id;
  final String timestamp;
  final String type;
  final String severity;
  final String zoneId;
  final String message;
  final String status;
  final String? resolvedAt;

  AnomalyAlert({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.severity,
    required this.zoneId,
    required this.message,
    required this.status,
    this.resolvedAt,
  });

  factory AnomalyAlert.fromJson(Map<String, dynamic> json) {
    return AnomalyAlert(
      id: json['id'],
      timestamp: json['timestamp'],
      type: json['type'],
      severity: json['severity'],
      zoneId: json['zone_id'],
      message: json['message'],
      status: json['status'],
      resolvedAt: json['resolved_at'],
    );
  }

  AnomalyAlert copyWith({String? status}) {
    return AnomalyAlert(
      id: id,
      timestamp: timestamp,
      type: type,
      severity: severity,
      zoneId: zoneId,
      message: message,
      status: status ?? this.status,
      resolvedAt: resolvedAt,
    );
  }
}
