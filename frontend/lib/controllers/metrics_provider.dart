import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/store_zone.dart';

class MetricsState {
  final double totalRevenue;
  final int totalCustomersTracked;
  final int totalPurchases;
  final Map<String, dynamic> zoneMetrics;
  final Map<String, double> averageDwellTimes;
  final Map<String, int> paymentsSplit;
  final List<dynamic> recentPurchases;
  final List<StoreZone> zones;
  final bool isLoading;
  final String error;

  MetricsState({
    this.totalRevenue = 0.0,
    this.totalCustomersTracked = 0,
    this.totalPurchases = 0,
    this.zoneMetrics = const {},
    this.averageDwellTimes = const {},
    this.paymentsSplit = const {},
    this.recentPurchases = const [],
    this.zones = const [],
    this.isLoading = true,
    this.error = '',
  });

  MetricsState copyWith({
    double? totalRevenue,
    int? totalCustomersTracked,
    int? totalPurchases,
    Map<String, dynamic>? zoneMetrics,
    Map<String, double>? averageDwellTimes,
    Map<String, int>? paymentsSplit,
    List<dynamic>? recentPurchases,
    List<StoreZone>? zones,
    bool? isLoading,
    String? error,
  }) {
    return MetricsState(
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalCustomersTracked: totalCustomersTracked ?? this.totalCustomersTracked,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      zoneMetrics: zoneMetrics ?? this.zoneMetrics,
      averageDwellTimes: averageDwellTimes ?? this.averageDwellTimes,
      paymentsSplit: paymentsSplit ?? this.paymentsSplit,
      recentPurchases: recentPurchases ?? this.recentPurchases,
      zones: zones ?? this.zones,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class MetricsNotifier extends StateNotifier<MetricsState> {
  Timer? _refreshTimer;
  final String baseApiUrl = 'http://localhost:8000/api';

  MetricsNotifier() : super(MetricsState()) {
    final bool isTesting = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTesting) {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    await fetchLayout();
    await fetchMetrics();
    
    // Auto-refresh metrics every 3 seconds to keep layout counts / charts perfectly updated
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      fetchMetrics();
    });
  }

  Future<void> fetchLayout() async {
    try {
      final response = await http.get(Uri.parse('$baseApiUrl/layout'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawZones = data['zones'] as List;
        final zonesList = rawZones.map((z) => StoreZone.fromJson(z)).toList();
        state = state.copyWith(zones: zonesList);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to fetch store layout: $e');
    }
  }

  Future<void> fetchMetrics() async {
    try {
      final response = await http.get(Uri.parse('$baseApiUrl/metrics'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Parse raw dwell times
        Map<String, double> dwells = {};
        if (data['average_dwell_times'] != null) {
          (data['average_dwell_times'] as Map).forEach((k, v) {
            dwells[k.toString()] = (v as num).toDouble();
          });
        }

        // Parse payments split
        Map<String, int> payments = {};
        if (data['payments_split'] != null) {
          (data['payments_split'] as Map).forEach((k, v) {
            payments[k.toString()] = v as int;
          });
        }

        state = state.copyWith(
          totalRevenue: (data['total_revenue'] as num?)?.toDouble() ?? 0.0,
          totalCustomersTracked: data['total_customers_tracked'] ?? 0,
          totalPurchases: data['total_purchases'] ?? 0,
          zoneMetrics: data['zone_metrics'] ?? {},
          averageDwellTimes: dwells,
          paymentsSplit: payments,
          recentPurchases: data['recent_purchases'] ?? [],
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to fetch metrics: $e',
        isLoading: false,
      );
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

final metricsProvider = StateNotifierProvider<MetricsNotifier, MetricsState>((ref) {
  return MetricsNotifier();
});
