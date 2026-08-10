import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_colors.dart';
import 'features/sync/presentation/sync_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: ConteoYaApp(),
    ),
  );
}

class ConteoYaApp extends StatelessWidget {
  const ConteoYaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConteoYA — ERM 2026',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.accentHover,
          surface: AppColors.surface,
          error: AppColors.danger,
        ),
        fontFamily: 'Roboto',
      ),
      home: const SyncDashboardScreen(),
    );
  }
}
