import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'views/dashboard_view.dart';

void main() {
  runApp(const ProviderScope(child: StoreMonitorApp()));
}

class StoreMonitorApp extends StatelessWidget {
  const StoreMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Purplle Store Intelligence',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF9C00AD), // Premium Purplle Neon
        scaffoldBackgroundColor: const Color(0xFF07030A),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9C00AD),
          secondary: Color(0xFF00B4D8),
          surface: Color(0xFF0F0914),
          error: Colors.redAccent,
        ),
        useMaterial3: true,
      ),
      home: const DashboardView(),
    );
  }
}
