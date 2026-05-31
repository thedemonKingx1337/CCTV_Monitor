import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/telemetry_provider.dart';
import '../../controllers/metrics_provider.dart';
import '../../models/store_zone.dart';
import '../../models/shopper.dart';

class StoreMap extends ConsumerStatefulWidget {
  const StoreMap({super.key});

  @override
  ConsumerState<StoreMap> createState() => _StoreMapState();
}

class _StoreMapState extends ConsumerState<StoreMap>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = ref.watch(telemetryProvider);
    final metrics = ref.watch(metricsProvider);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0914), // Deep Purplle black
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Map Drawing area
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: StoreMapPainter(
                      zones: metrics.zones,
                      shoppers: telemetry.shoppers,
                      alerts: telemetry.alerts,
                      pulseValue: _pulseController.value,
                    ),
                  );
                },
              ),
            ),

            // Map Legend
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _legendItem('Cosmetics', const Color(0xFF9C00AD)),
                    const SizedBox(width: 8),
                    _legendItem('Skincare', const Color(0xFF00B4D8)),
                    const SizedBox(width: 8),
                    _legendItem('Fragrance', const Color(0xFFFFB703)),
                    const SizedBox(width: 8),
                    _legendItem('Queue', const Color(0xFFE63946)),
                    const SizedBox(width: 8),
                    _legendItem('Billing', const Color(0xFF2A9D8F)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String name, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class StoreMapPainter extends CustomPainter {
  final List<StoreZone> zones;
  final List<Shopper> shoppers;
  final List<dynamic> alerts;
  final double pulseValue;

  StoreMapPainter({
    required this.zones,
    required this.shoppers,
    required this.alerts,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 640x480 is the coordinates resolution from backend
    final double scaleX = size.width / 640.0;
    final double scaleY = size.height / 480.0;

    // 1. Draw Zones Polygons
    for (var zone in zones) {
      final path = Path();
      final poly = zone.polygon;
      if (poly.isEmpty) continue;

      path.moveTo(poly[0][0] * scaleX, poly[0][1] * scaleY);
      for (int i = 1; i < poly.length; i++) {
        path.lineTo(poly[i][0] * scaleX, poly[i][1] * scaleY);
      }
      path.close();

      // Check active alerts for this zone
      bool hasAlert = alerts.any(
        (a) => a.zoneId == zone.id && a.status == "active",
      );

      // Draw Zone Fill
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = hasAlert
            ? Color.lerp(
                Colors.red.withOpacity(0.08),
                Colors.red.withOpacity(0.24),
                pulseValue,
              )!
            : zone.color.withOpacity(0.12);
      canvas.drawPath(path, fillPaint);

      // Draw Zone Border
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hasAlert ? 2.5 : 1.5
        ..color = hasAlert
            ? Color.lerp(Colors.red, Colors.redAccent, pulseValue)!
            : zone.color.withOpacity(0.65);
      canvas.drawPath(path, borderPaint);

      // Draw zone name label
      double sumX = 0;
      double sumY = 0;
      for (var p in poly) {
        sumX += p[0];
        sumY += p[1];
      }
      final double centroidX = (sumX / poly.length) * scaleX;
      final double centroidY = (sumY / poly.length) * scaleY;

      final textSpan = TextSpan(
        text: zone.name,
        style: TextStyle(
          color: hasAlert ? Colors.redAccent : Colors.white60,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          centroidX - textPainter.width / 2,
          centroidY - textPainter.height / 2,
        ),
      );
    }

    // 2. Draw Shoppers
    for (var s in shoppers) {
      final double mappedX = s.x * scaleX;
      final double mappedY = s.y * scaleY;

      // Pulse ring representing continuous tracking
      final pulsePaint = Paint()
        ..color = Colors.purple.withOpacity(0.25 - (pulseValue * 0.15))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(
        Offset(mappedX, mappedY),
        12 + (pulseValue * 8),
        pulsePaint,
      );

      // Bounding box overlay representation
      final boxPaint = Paint()
        ..color = Colors.purpleAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(mappedX, mappedY),
          width: 22,
          height: 22,
        ),
        boxPaint,
      );

      // Center Dot
      final shopperPaint = Paint()
        ..color = Colors.purpleAccent
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(mappedX, mappedY), 5.5, shopperPaint);

      // Outer ring
      final ringPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(Offset(mappedX, mappedY), 6.5, ringPaint);

      // Draw shopper ID label
      final textSpan = TextSpan(
        text: '${s.id} (${s.state})',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          backgroundColor: Colors.black45,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(mappedX - textPainter.width / 2, mappedY - 20),
      );
    }
  }

  @override
  bool shouldRepaint(covariant StoreMapPainter oldDelegate) {
    return true; // Continuously redraw live coordinate points
  }
}
