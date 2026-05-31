import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/shopper.dart';
import '../models/alert.dart';

class TelemetryState {
  final int activeShoppersCount;
  final int queueCount;
  final bool billingActive;
  final List<Shopper> shoppers;
  final List<AnomalyAlert> alerts;
  final String frame;
  final bool isConnected;

  TelemetryState({
    this.activeShoppersCount = 0,
    this.queueCount = 0,
    this.billingActive = false,
    this.shoppers = const [],
    this.alerts = const [],
    this.frame = '',
    this.isConnected = false,
  });

  TelemetryState copyWith({
    int? activeShoppersCount,
    int? queueCount,
    bool? billingActive,
    List<Shopper>? shoppers,
    List<AnomalyAlert>? alerts,
    String? frame,
    bool? isConnected,
  }) {
    return TelemetryState(
      activeShoppersCount: activeShoppersCount ?? this.activeShoppersCount,
      queueCount: queueCount ?? this.queueCount,
      billingActive: billingActive ?? this.billingActive,
      shoppers: shoppers ?? this.shoppers,
      alerts: alerts ?? this.alerts,
      frame: frame ?? this.frame,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

class TelemetryNotifier extends StateNotifier<TelemetryState> {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _isDisposed = false;
  final String wsUrl = 'ws://localhost:8000/ws/telemetry';

  TelemetryNotifier() : super(TelemetryState()) {
    final bool isTesting = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (!isTesting) {
      _connect();
    }
  }

  void _connect() {
    if (_isDisposed || !mounted) return;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      state = state.copyWith(isConnected: true);

      _channel!.stream.listen(
        (message) {
          if (_isDisposed || !mounted) return;
          _handleMessage(message);
        },
        onError: (err) {
          if (_isDisposed || !mounted) return;
          state = state.copyWith(isConnected: false);
          _scheduleReconnect();
        },
        onDone: () {
          if (_isDisposed || !mounted) return;
          state = state.copyWith(isConnected: false);
          _scheduleReconnect();
        },
      );
    } catch (e) {
      if (_isDisposed || !mounted) return;
      state = state.copyWith(isConnected: false);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed || !mounted) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (_isDisposed || !mounted) return;
      if (!state.isConnected) {
        _connect();
      }
    });
  }

  void _handleMessage(String message) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      
      final shoppersList = (data['shoppers'] as List)
          .map((s) => Shopper.fromJson(s))
          .toList();
          
      final alertsList = (data['alerts'] as List)
          .map((a) => AnomalyAlert.fromJson(a))
          .toList();

      state = state.copyWith(
        activeShoppersCount: data['active_shoppers_count'] ?? 0,
        queueCount: data['queue_count'] ?? 0,
        billingActive: data['billing_active'] ?? false,
        shoppers: shoppersList,
        alerts: alertsList,
        frame: data['frame'] ?? '',
        isConnected: true,
      );
    } catch (e) {
      // Handle parse error
    }
  }

  void acknowledgeAlert(String alertId) {
    if (_channel != null && state.isConnected) {
      final msg = jsonEncode({
        "action": "acknowledge_alert",
        "alert_id": alertId,
      });
      _channel!.sink.add(msg);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}

final telemetryProvider = StateNotifierProvider<TelemetryNotifier, TelemetryState>((ref) {
  return TelemetryNotifier();
});
