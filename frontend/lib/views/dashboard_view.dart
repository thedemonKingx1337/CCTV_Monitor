import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/telemetry_provider.dart';
import '../../controllers/metrics_provider.dart';

import 'widgets/kpi_card.dart';
import 'widgets/cctv_viewport.dart';
import 'widgets/store_map.dart';
import 'widgets/alert_feed_widget.dart';
import 'widgets/analytics_charts.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(telemetryProvider);
    final metrics = ref.watch(metricsProvider);

    final bool queueIssue = telemetry.queueCount >= 3;
    final bool billingAlert =
        !telemetry.billingActive && telemetry.queueCount > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF07030A), // Deep Purplle Space Black
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              _buildHeader(context, telemetry),
              const SizedBox(height: 24),

              // KPI Row
              Row(
                children: [
                  Expanded(
                    child: KpiCard(
                      title: 'TOTAL REVENUE',
                      value: 'Rs. ${metrics.totalRevenue.toStringAsFixed(2)}',
                      icon: Icons.monetization_on_outlined,
                      color: Colors.greenAccent,
                      subtitle: '${metrics.totalPurchases} Orders Checked Out',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: KpiCard(
                      title: 'CUSTOMERS IN STORE',
                      value: '${telemetry.activeShoppersCount}',
                      icon: Icons.people_outline_rounded,
                      color: const Color(0xFF9C00AD),
                      subtitle:
                          '${metrics.totalCustomersTracked} Session Traces',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: KpiCard(
                      title: 'CHECKOUT QUEUE',
                      value: '${telemetry.queueCount} Waiting',
                      icon: Icons.hourglass_empty_rounded,
                      color: queueIssue
                          ? Colors.redAccent
                          : Colors.orangeAccent,
                      subtitle: queueIssue
                          ? 'Bottleneck Detected!'
                          : 'Normal Dwell Rate',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: KpiCard(
                      title: 'BILLING DESK STAFF',
                      value: telemetry.billingActive ? 'Active' : 'Absent',
                      icon: Icons.assignment_ind_outlined,
                      color: billingAlert
                          ? Colors.redAccent
                          : (telemetry.billingActive
                                ? Colors.tealAccent
                                : Colors.grey),
                      subtitle: billingAlert
                          ? 'CRITICAL: Attendance Alert'
                          : 'Staff Present',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Main Dashboard grid split
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Column (Live Feeds and Maps)
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          // Live CCTV feed viewport
                          const Expanded(flex: 5, child: CctvViewport()),
                          const SizedBox(height: 20),
                          // Live Interactive Shopper Coordinate Map
                          const Expanded(flex: 5, child: StoreMap()),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Right Column (Alert logs & statistics)
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          // Anomaly Alerts Feed (Live actions)
                          const Expanded(flex: 5, child: AlertFeedWidget()),
                          const SizedBox(height: 20),
                          // FL Charts
                          const Expanded(flex: 5, child: AnalyticsCharts()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TelemetryState telemetry) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF9C00AD),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'PURPLLE AI',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF9C00AD),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Store Intelligence Suite',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: telemetry.isConnected
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: telemetry.isConnected
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: telemetry.isConnected
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                telemetry.isConnected
                    ? 'CV PIPELINE ONLINE'
                    : 'CV PIPELINE DISCONNECTED',
                style: TextStyle(
                  color: telemetry.isConnected
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
