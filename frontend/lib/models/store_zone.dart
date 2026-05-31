import 'package:flutter/material.dart';

class StoreZone {
  final String id;
  final String name;
  final String type;
  final List<List<int>> polygon;
  final String colorHex;

  StoreZone({
    required this.id,
    required this.name,
    required this.type,
    required this.polygon,
    required this.colorHex,
  });

  factory StoreZone.fromJson(Map<String, dynamic> json) {
    var rawPoly = json['polygon'] as List;
    List<List<int>> polyList = rawPoly.map((p) => List<int>.from(p)).toList();
    return StoreZone(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      polygon: polyList,
      colorHex: json['color_hex'] ?? '#ffffff',
    );
  }

  Color get color {
    final hexCode = colorHex.replaceAll('#', '');
    if (hexCode.length == 6) {
      return Color(int.parse('FF$hexCode', radix: 16));
    }
    return Colors.white;
  }
}
