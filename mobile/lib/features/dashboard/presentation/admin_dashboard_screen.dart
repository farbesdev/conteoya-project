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

    final theme = Theme.of(context);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurface.withAlpha(178);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Panel de Control — ERM 2026 (${user?.role ?? "ADMIN"})',
                        style: TextStyle(
                          color: textSecondary,
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
            const SizedBox(height: 16),

            // Métricas Principales (2x2 Grid)
            Row(
              children: [
                Expanded(
                  child: StatMetricCard(
                    title: 'Personeros',
                    value: '$personerosCount',
                    icon: Icons.people_alt_rounded,
                    accentColor: AppColors.accent,
                    onTap: () => onNavigateTab?.call(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatMetricCard(
                    title: 'Mesas Electorales',
                    value: '$mesasCount',
                    icon: Icons.how_to_vote_rounded,
                    accentColor: AppColors.info,
                    onTap: () => onNavigateTab?.call(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatMetricCard(
                    title: 'Actas Procesadas',
                    value: '$actsCount',
                    icon: Icons.assignment_turned_in_rounded,
                    accentColor: AppColors.success,
                    onTap: () => onNavigateTab?.call(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatMetricCard(
                    title: 'Usuarios Totales',
                    value: '${(personerosCount + 2)}',
                    icon: Icons.manage_accounts_rounded,
                    accentColor: AppColors.warning,
                    onTap: () => onNavigateTab?.call(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Accesos Rápidos (Acciones Administrativas)
            Text(
              'Acciones Rápidas',
              style: TextStyle(
                color: textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildActionTile(
              context: context,
              icon: Icons.person_add_alt_1_rounded,
              title: 'Registrar Nuevo Personero',
              subtitle: 'Asignar DNI y mesa de votación',
              color: AppColors.accent,
              onTap: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => const PersoneroFormModal(),
                );
              },
            ),
            const SizedBox(height: 10),

            _buildActionTile(
              context: context,
              icon: Icons.add_location_alt_rounded,
              title: 'Crear Mesa de Sufragio',
              subtitle: 'Agregar nuevo código de mesa y recinto',
              color: AppColors.info,
              onTap: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => const AddMesaModal(),
                );
              },
            ),
            const SizedBox(height: 10),

            _buildActionTile(
              context: context,
              icon: Icons.sync_sharp,
              title: 'Forzar Sincronización Global',
              subtitle: 'Enviar cambios locales y descargar catálogos',
              color: AppColors.success,
              onTap: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Iniciando sincronización global...'),
                    backgroundColor: AppColors.info,
                    duration: Duration(seconds: 1),
                  ),
                );
                try {
                  await ref.read(syncEngineProvider).syncPendingOperations();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✓ Sincronización exitosa con la API ConteoYA.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('⚠️ Error al sincronizar: $e'),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 10),

            _buildActionTile(
              context: context,
              icon: Icons.delete_forever_rounded,
              title: 'Reiniciar Base de Datos (Reset)',
              subtitle: 'Restablecer conteos a cero en VPS y local',
              color: AppColors.danger,
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('¿Reiniciar Base de Datos?'),
                    content: const Text(
                      'Esta acción eliminará de forma permanente todas las actas, totales, resultados y evidencias tanto en este dispositivo (local) como en el servidor VPS (producción). Los conteos se restablecerán a cero.\n\n¿Desea continuar?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.dangerOf(context),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reiniciando base de datos...'),
                              backgroundColor: AppColors.info,
                              duration: Duration(seconds: 1),
                            ),
                          );
                          try {
                            // 1. Resetear base de datos remota
                            await ref.read(apiClientProvider).post<void>('/admin/reset-database');

                            // 2. Resetear base de datos local
                            await ref.read(appDatabaseProvider).clearTransactionalData();

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✓ Base de datos reiniciada exitosamente.'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('⚠️ Error al reiniciar base de datos: $e'),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Reiniciar', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurface.withAlpha(178);
    final cardBg = theme.colorScheme.surface;
    final isDark = theme.brightness == Brightness.dark;
    final subtleBorder = isDark ? const Color(0x1AFFFFFF) : const Color(0x0F0F172A);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: subtleBorder, width: 0.5),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: textSecondary, size: 20),
          ),
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
        badgeColor = AppColors.infoOf(context);
        statusText = 'Sincronizando con servidor...';
        icon = Icons.sync;
        break;
      case SyncEngineState.offline:
        badgeColor = AppColors.warningOf(context);
        statusText = 'Modo Offline (Sin Conexión)';
        icon = Icons.cloud_off;
        break;
      case SyncEngineState.error:
        badgeColor = AppColors.dangerOf(context);
        statusText = 'Reintento programado';
        icon = Icons.error_outline;
        break;
      case SyncEngineState.idle:
        badgeColor = AppColors.successOf(context);
        statusText = 'Servidor conectado';
        icon = Icons.cloud_done;
        break;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary = theme.colorScheme.onSurface.withAlpha(178);
    final cardBg = theme.colorScheme.surface;
    final subtleBorder = isDark ? const Color(0x1AFFFFFF) : const Color(0x0F0F172A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: subtleBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: badgeColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: AppColors.accent, size: 18),
            tooltip: 'Sincronizar',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              ref.read(syncEngineProvider).syncPendingOperations();
            },
          ),
        ],
      ),
    );
  }
}
