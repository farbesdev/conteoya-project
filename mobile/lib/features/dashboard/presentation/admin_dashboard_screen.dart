import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/stat_metric_card.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../mesas/presentation/add_mesa_modal.dart';
import '../../personeros/presentation/personero_form_modal.dart';

class AdminDashboardScreen extends ConsumerWidget {
  final Function(int tabIndex)? onNavigateTab;

  const AdminDashboardScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState is Authenticated ? authState.session : null;

    final personerosAsync = ref.watch(personerosStreamProvider);
    final mesasAsync = ref.watch(mesasStreamProvider);
    final actsAsync = ref.watch(allActsStreamProvider);
    final syncState = ref.watch(syncStateStreamProvider);

    final personerosCount = personerosAsync.value?.length ?? 0;
    final mesasCount = mesasAsync.value?.length ?? 0;
    final actsCount = actsAsync.value?.where((a) => a.status != 'DRAFT').length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo y Bienvenida
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenido, ${user?.name ?? "Administrador"}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Panel de Control — ERM 2026 (${user?.role ?? "ADMIN"})',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tarjeta de Estado del Sync Engine
            _buildSyncStatusCard(context, ref, syncState.value ?? SyncEngineState.idle),
            const SizedBox(height: 20),

            // Título de Sección Indicadores
            const Text(
              'Indicadores Generales',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Grid de Métricas Principales (Requerimiento 6)
            Row(
              children: [
                Expanded(
                  child: StatMetricCard(
                    title: 'Personeros',
                    value: '$personerosCount',
                    subtitle: 'registrados',
                    icon: Icons.people_alt_rounded,
                    color: AppColors.accent,
                    onTap: () => onNavigateTab?.call(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatMetricCard(
                    title: 'Mesas',
                    value: '$mesasCount',
                    subtitle: 'mesas electorales',
                    icon: Icons.how_to_vote_rounded,
                    color: AppColors.info,
                    onTap: () => onNavigateTab?.call(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: StatMetricCard(
                    title: 'Actas',
                    value: '$actsCount',
                    subtitle: 'registradas / procesadas',
                    icon: Icons.description_rounded,
                    color: AppColors.success,
                    onTap: () => onNavigateTab?.call(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Acciones Rápidas
            const Text(
              'Acciones Rápidas',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.person_add_rounded,
                    label: 'Registrar\nPersonero',
                    color: AppColors.accent,
                    onTap: () => PersoneroFormModal.show(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.add_home_work_rounded,
                    label: 'Agregar\nMesa',
                    color: AppColors.info,
                    onTap: () => AddMesaModal.show(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.post_add_rounded,
                    label: 'Ver / Registrar\nActas',
                    color: AppColors.success,
                    onTap: () => onNavigateTab?.call(2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusCard(BuildContext context, WidgetRef ref, SyncEngineState state) {
    Color badgeColor;
    String statusText;
    IconData icon;

    switch (state) {
      case SyncEngineState.syncing:
        badgeColor = AppColors.info;
        statusText = 'Sincronizando con servidor...';
        icon = Icons.sync;
        break;
      case SyncEngineState.offline:
        badgeColor = AppColors.warning;
        statusText = 'Modo Offline (Sin Conexión)';
        icon = Icons.cloud_off;
        break;
      case SyncEngineState.error:
        badgeColor = AppColors.danger;
        statusText = 'Reintento programado';
        icon = Icons.error_outline;
        break;
      case SyncEngineState.idle:
        badgeColor = AppColors.success;
        statusText = 'Base de datos sincronizada';
        icon = Icons.cloud_done;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: badgeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Motor de Sincronización',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                Text(
                  statusText,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: AppColors.accent, size: 20),
            tooltip: 'Sincronizar ahora',
            onPressed: () {
              ref.read(syncEngineProvider).syncPendingOperations();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sincronizando operaciones pendientes...'),
                  backgroundColor: AppColors.info,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
