import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../core/theme/app_colors.dart';
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

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Cerrar Sesión', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: const Text(
          '¿Está seguro de que desea cerrar la sesión actual?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getTitle(),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 17),
            ),
            if (user != null)
              Text(
                '${user.name} • ${user.role}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
          ],
        ),
        actions: [
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
                final metrics = await ref.read(syncEngineProvider).syncPendingOperations();
                if (context.mounted) {
                  final stations = metrics['polling_stations'] ?? 0;
                  final personeros = metrics['personeros'] ?? 0;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '✓ Sincronización completada. Mesas: $stations, Personeros: $personeros actualizados.',
                      ),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 3),
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
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.primary,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: safeIndex,
          onTap: _onTabTapped,
          backgroundColor: AppColors.primary,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          items: navItems,
        ),
      ),
    );
  }
}
