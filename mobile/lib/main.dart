import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_shell.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'features/auth/domain/auth_state.dart';
import 'features/auth/presentation/auth_notifier.dart';
import 'features/auth/presentation/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: ConteoYaApp(),
    ),
  );
}

class ConteoYaApp extends ConsumerWidget {
  const ConteoYaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'ConteoYA — ERM 2026',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return switch (authState) {
      Authenticated() => const AppShell(),
      Unauthenticated() => const LoginScreen(),
      AuthLoading() || AuthInitial() => Scaffold(
          backgroundColor: isDark
              ? AppColors.background
              : AppColors.lightBackground,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.how_to_vote_rounded,
                  color: AppColors.accent,
                  size: 56,
                ),
                const SizedBox(height: 16),
                const CircularProgressIndicator(color: AppColors.accent),
              ],
            ),
          ),
        ),
    };
  }
}
