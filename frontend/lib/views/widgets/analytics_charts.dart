import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/metrics_provider.dart';

class AnalyticsCharts extends ConsumerWidget {
  const AnalyticsCharts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(metricsProvider);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONVERSION & PERFORMANCE METRICS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: metrics.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.purpleAccent,
                    ),
                  )
                : Row(
                    children: [
                      // 1. Conversion rates
                      Expanded(child: _buildBarChart(context, metrics)),
                      const SizedBox(width: 24),
                      // 2. Payments split
                      Expanded(child: _buildPieChart(context, metrics)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, MetricsState metrics) {
    final Map<String, dynamic> zoneMetrics = metrics.zoneMetrics;

    // Fallback if empty
    double cosmeticsVal = 0;
    double skincareVal = 0;
    double fragranceVal = 0;

    if (zoneMetrics.containsKey('zone_cosmetics')) {
      cosmeticsVal = (zoneMetrics['zone_cosmetics']['conversion_rate'] as num)
          .toDouble()
          .clamp(0.0, 100.0);
    }
    if (zoneMetrics.containsKey('zone_skincare')) {
      skincareVal = (zoneMetrics['zone_skincare']['conversion_rate'] as num)
          .toDouble()
          .clamp(0.0, 100.0);
    }
    if (zoneMetrics.containsKey('zone_fragrance')) {
      fragranceVal = (zoneMetrics['zone_fragrance']['conversion_rate'] as num)
          .toDouble()
          .clamp(0.0, 100.0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zone Conversion Rate (%)',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceEvenly,
              maxY: 100,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 1,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      const style = TextStyle(
                        color: Colors.white60,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      );
                      String text;
                      switch (value.toInt()) {
                        case 0:
                          text = 'Cosmetics';
                          break;
                        case 1:
                          text = 'Skincare';
                          break;
                        case 2:
                          text = 'Fragrance';
                          break;
                        default:
                          text = '';
                          break;
                      }
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 4,
                        child: Text(text, style: style),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 25,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Text(
                        '${value.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white30,
                          fontSize: 9,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.white.withOpacity(0.05),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: cosmeticsVal,
                      color: const Color(0xFF9C00AD),
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: skincareVal,
                      color: const Color(0xFF00B4D8),
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 2,
                  barRods: [
                    BarChartRodData(
                      toY: fragranceVal,
                      color: const Color(0xFFFFB703),
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(BuildContext context, MetricsState metrics) {
    final Map<String, int> paymentSplits = metrics.paymentsSplit;

    int upi = paymentSplits['UPI'] ?? 1;
    int card = paymentSplits['Card'] ?? 1;
    int cash = paymentSplits['Cash'] ?? 1;

    int total = upi + card + cash;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transactions Payment Split',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 35,
              sections: [
                PieChartSectionData(
                  color: const Color(0xFF2A9D8F),
                  value: upi.toDouble(),
                  title: 'UPI\n${(upi / total * 100).toStringAsFixed(0)}%',
                  radius: 40,
                  titleStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: const Color(0xFF00B4D8),
                  value: card.toDouble(),
                  title: 'Card\n${(card / total * 100).toStringAsFixed(0)}%',
                  radius: 40,
                  titleStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  color: const Color(0xFFFFB703),
                  value: cash.toDouble(),
                  title: 'Cash\n${(cash / total * 100).toStringAsFixed(0)}%',
                  radius: 40,
                  titleStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
