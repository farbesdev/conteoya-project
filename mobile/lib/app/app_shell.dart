import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/theme_notifier.dart';
import '../features/acts/presentation/admin_actas_screen.dart';
import '../features/acts/presentation/personero_actas_screen.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/auth_notifier.dart';
import '../features/dashboard/presentation/admin_dashboard_screen.dart';
import '../features/dashboard/presentation/personero_dashboard_screen.dart';
import '../features/personeros/presentation/personeros_screen.dart';
import '../features/users/presentation/users_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  // Controlador de animación para el icono del tema
  late final AnimationController _themeAnimController;
  late final Animation<double> _themeIconRotation;

  @override
  void initState() {
    super.initState();
    _themeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _themeIconRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _themeAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _themeAnimController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  Future<void> _toggleTheme() async {
    if (_themeAnimController.isCompleted) {
      await _themeAnimController.reverse();
    } else {
      await _themeAnimController.forward();
    }
    await ref.read(themeModeProvider.notifier).toggle();
  }

  void _showLogoutDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.outlineVariant),
        ),
        title: Text(
          'Cerrar Sesión',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Está seguro de que desea cerrar la sesión actual?',
          style: TextStyle(color: cs.onSurface.withAlpha(178)),
        ),
        actions: [
          TextButton(
            child: Text(
              'Cancelar',
              style: TextStyle(color: cs.onSurface.withAlpha(128)),
            ),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState is Authenticated ? authState.session : null;
    final isAdminOrDirector = user?.isAdminOrDirector ?? false;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final cs = Theme.of(context).colorScheme;

    // Pantallas disponibles según rol
    final List<Widget> screens = isAdminOrDirector
        ? [
            AdminDashboardScreen(onNavigateTab: _onTabTapped),
            const PersonerosScreen(),
            const UsersScreen(),
            const AdminActasScreen(),
          ]
        : [
            PersoneroDashboardScreen(onNavigateTab: _onTabTapped),
            const PersoneroActasScreen(),
          ];

    // Ítems de Navegación según rol
    final List<BottomNavigationBarItem> navItems = isAdminOrDirector
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_rounded),
              label: 'Personeros',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.manage_accounts_rounded),
              label: 'Usuarios',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_rounded),
              label: 'Actas',
            ),
          ]
        : const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_rounded),
              label: 'Actas',
            ),
          ];

    // Evitar desbordamiento de índice si cambia de rol dinámicamente
    final safeIndex = _currentIndex >= screens.length ? 0 : _currentIndex;

    String getTitle() {
      if (isAdminOrDirector) {
        switch (safeIndex) {
          case 0:
            return 'Dashboard General';
          case 1:
            return 'Gestión de Personeros';
          case 2:
            return 'Gestión de Usuarios';
          case 3:
            return 'Mesas y Actas';
          default:
            return 'ConteoYA';
        }
      } else {
        switch (safeIndex) {
          case 0:
            return 'Mi Dashboard';
          case 1:
            return 'Mis Actas Electorales';
          default:
            return 'ConteoYA';
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getTitle(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            if (user != null)
              Text(
                '${user.name} • ${user.role}',
                style: TextStyle(
                  color: cs.onSurface.withAlpha(128),
                  fontSize: 11,
                ),
              ),
          ],
        ),
        actions: [
          // ─── Botón Toggle Tema ──────────────────────────────────────────
          Tooltip(
            message: isDark ? 'Cambiar a tema claro' : 'Cambiar a tema oscuro',
            child: AnimatedBuilder(
              animation: _themeIconRotation,
              builder: (context, child) => Transform.rotate(
                angle: _themeIconRotation.value * 3.14159,
                child: child,
              ),
              child: IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                  child: Icon(
                    isDark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    key: ValueKey(isDark),
                    color: isDark ? AppColors.warning : AppColors.accent,
                  ),
                ),
                onPressed: _toggleTheme,
              ),
            ),
          ),

          // ─── Botón Sincronizar (Bidireccional) ──────────────────────────
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: AppColors.info),
            tooltip: 'Sincronizar Datos',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Iniciando sincronización bidireccional...'),
                  backgroundColor: AppColors.info,
                  duration: Duration(seconds: 1),
                ),
              );

              try {
                await ref.read(syncEngineProvider).syncPendingOperations();
                final db = ref.read(appDatabaseProvider);
                final totalPersoneros = (await db.getAllPersoneros()).length;
                final totalMesas = (await db.getAllPollingStations()).length;

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '✓ Sincronización bidireccional completada. Total en dispositivo: $totalPersoneros usuarios/personeros, $totalMesas mesas.',
                      ),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⚠️ Error al sincronizar con el servidor: $e'),
                      backgroundColor: AppColors.danger,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
          ),

          // ─── Botón Cerrar Sesión ────────────────────────────────────────
          IconButton(
            icon: Icon(
              Icons.logout_rounded,
              color: cs.onSurface.withAlpha(153),
            ),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: _onTabTapped,
        items: navItems,
      ),
    );
  }
}
