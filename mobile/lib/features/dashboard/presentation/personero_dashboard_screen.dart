import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../acts/presentation/act_detail_screen.dart';
import '../../acts/presentation/act_form_screen.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../mesas/domain/mesa_model.dart';

class PersoneroDashboardScreen extends ConsumerWidget {
  final Function(int tabIndex)? onNavigateTab;

  const PersoneroDashboardScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState is Authenticated ? authState.session : null;

    final mesasAsync = ref.watch(mesasStreamProvider);
    final personerosAsync = ref.watch(personerosStreamProvider);
    final syncState = ref.watch(syncStateStreamProvider);

    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.titleMedium?.color ?? theme.colorScheme.onSurface;
    final textSecondary = theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface.withAlpha(178);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: mesasAsync.when(
          data: (mesas) {
            return personerosAsync.when(
              data: (personeros) {
                final userEmail = user?.email.trim().toLowerCase();
                final matches = personeros.where(
                  (p) =>
                      (userEmail != null && p.email?.trim().toLowerCase() == userEmail) ||
                      (user?.personeroId != null && p.id == user?.personeroId),
                );
                final myPersonero = matches.isNotEmpty ? matches.first : null;

                final assignedMesaCode = user?.pollingStationCode ?? myPersonero?.pollingStationCode;
                final assignedMesa = assignedMesaCode != null
                    ? mesas.where((m) => m.code == assignedMesaCode).firstOrNull
                    : null;

                if (assignedMesa == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No tiene una mesa asignada actualmente.',
                        style: TextStyle(color: AppColors.warning),
                      ),
                    ),
                  );
                }

                final registeredActsCount = assignedMesa.registeredActsCount;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Saludo al personero
                    Text(
                      'Hola, ${user?.name ?? "Personero"}',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Jornada Electoral — Elecciones Regionales y Municipales 2026',
                      style: TextStyle(color: textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // Tarjeta de Estado del Sync Engine
                    _buildSyncStatusCard(context, ref, syncState.value ?? SyncEngineState.idle),
                    const SizedBox(height: 16),

                    // Tarjeta Principal: Mi Mesa Asignada
                    _buildMesaCard(context, assignedMesa),
                    const SizedBox(height: 16),

                    // Tarjeta de Avance de Actas
                    _buildProgressCard(context, registeredActsCount),
                    const SizedBox(height: 20),

                    // Lista de Actas de su Mesa
                    Text(
                      'Mis Actas Electorales',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Acta Regional
                    _buildActItemCard(
                      context: context,
                      ref: ref,
                      mesaCode: assignedMesa.code,
                      electoralLevelId: 1,
                      title: '🏛 Acta Regional',
                      subtitle: 'Fórmula Gobernador y Vicegobernador',
                      status: assignedMesa.regionalStatus,
                      primaryColor: AppColors.accent,
                    ),
                    const SizedBox(height: 12),

                    // Acta Municipal Provincial-Distrital
                    _buildActItemCard(
                      context: context,
                      ref: ref,
                      mesaCode: assignedMesa.code,
                      electoralLevelId: 2,
                      title: '🏙 Acta Municipal Provincial-Distrital',
                      subtitle: 'Concejos Provinciales y Distritales',
                      status: assignedMesa.municipalStatus,
                      primaryColor: AppColors.info,
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.danger))),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.danger))),
        ),
      ),
    );
  }

  Widget _buildMesaCard(BuildContext context, MesaModel mesa) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurface.withAlpha(178);
    final textMuted = theme.colorScheme.onSurface.withAlpha(128);
    final subtleBorder = isDark ? const Color(0x1AFFFFFF) : const Color(0x0F0F172A);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.how_to_vote_rounded, color: AppColors.accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mesa Asignada',
                      style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'N.º ${mesa.code}',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${mesa.registeredVoters} electores',
                  style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: subtleBorder, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.school_outlined, color: textMuted, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  mesa.locationName,
                  style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: textMuted, size: 15),
              const SizedBox(width: 6),
              Text(
                '${mesa.districtName} • ${mesa.provinceName}',
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, int registeredCount) {
    final isComplete = registeredCount == 2;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurface.withAlpha(178);
    final textMuted = theme.colorScheme.onSurface.withAlpha(128);
    final cardBg = theme.colorScheme.surface;
    final subtleBorder = isDark ? const Color(0x1AFFFFFF) : const Color(0x0F0F172A);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete ? AppColors.success.withValues(alpha: 0.3) : subtleBorder,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isComplete ? AppColors.success : AppColors.accent).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isComplete ? Icons.task_alt_rounded : Icons.pending_actions_rounded,
              color: isComplete ? AppColors.success : AppColors.accent,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mis Actas',
                  style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  '$registeredCount / 2',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  isComplete ? 'Todas las actas registradas' : 'registradas para su mesa',
                  style: TextStyle(
                    color: isComplete ? AppColors.success : textSecondary,
                    fontSize: 12,
                    fontWeight: isComplete ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActItemCard({
    required BuildContext context,
    required WidgetRef ref,
    required String mesaCode,
    required int electoralLevelId,
    required String title,
    required String subtitle,
    required ActRegistrationStatus status,
    required Color primaryColor,
  }) {
    final isRegistered = status.isRegistrada;
    final statusColor = isRegistered ? AppColors.successOf(context) : AppColors.warningOf(context);
    final statusIcon = isRegistered ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded;

    final theme = Theme.of(context);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurface.withAlpha(178);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  electoralLevelId == 1 ? Icons.account_balance_rounded : Icons.location_city_rounded,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      status.label,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isRegistered ? theme.colorScheme.surfaceContainerHigh : primaryColor,
                foregroundColor: isRegistered ? textPrimary : Colors.white,
                elevation: isRegistered ? 0 : 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(
                isRegistered ? Icons.visibility_outlined : Icons.photo_camera_rounded,
                size: 18,
              ),
              label: Text(
                isRegistered ? 'Ver Acta Registrada' : 'Registrar Acta Ahora',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ActFormScreen(
                      pollingStationCode: mesaCode,
                      electoralLevelId: electoralLevelId,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
        statusText = 'Listo para registrar';
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
