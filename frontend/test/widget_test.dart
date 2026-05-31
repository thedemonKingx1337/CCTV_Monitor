import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:store_monitor/main.dart';

void main() {
  testWidgets('Store Intelligence Suite loads successfully', (WidgetTester tester) async {
    // Set a realistic desktop surface size for the glassmorphic dashboard test
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Build our app under ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: StoreMonitorApp(),
      ),
    );

    // Verify that the title loads
    expect(find.text('Store Intelligence Suite'), findsOneWidget);
  });
}
