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

    return Scaffold(
      backgroundColor: AppColors.background,
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
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Jornada Electoral — Elecciones Regionales y Municipales 2026',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // Tarjeta de Estado del Sync Engine
                    _buildSyncStatusCard(context, ref, syncState.value ?? SyncEngineState.idle),
                    const SizedBox(height: 16),

                    // Tarjeta Principal: Mi Mesa Asignada
                    _buildMesaCard(assignedMesa),
                    const SizedBox(height: 16),

                    // Tarjeta de Avance de Actas (Requerimiento 7: "1 / 2 registradas")
                    _buildProgressCard(registeredActsCount),
                    const SizedBox(height: 20),

                    // Lista de Actas de su Mesa
                    const Text(
                      'Mis Actas Electorales',
                      style: TextStyle(
                        color: AppColors.textPrimary,
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

  Widget _buildMesaCard(MesaModel mesa) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.how_to_vote_rounded, color: AppColors.accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mesa Asignada',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'N.º ${mesa.code}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
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
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${mesa.registeredVoters} electores',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.school_outlined, color: AppColors.textMuted, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  mesa.locationName,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 15),
              const SizedBox(width: 6),
              Text(
                '${mesa.districtName} • ${mesa.provinceName}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(int registeredCount) {
    final isComplete = registeredCount == 2;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isComplete ? AppColors.success.withValues(alpha: 0.4) : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isComplete ? AppColors.success : AppColors.accent).withValues(alpha: 0.15),
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
                const Text(
                  'Mis Actas',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  '$registeredCount / 2',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  isComplete ? 'Todas las actas registradas' : 'registradas para su mesa',
                  style: TextStyle(
                    color: isComplete ? AppColors.success : AppColors.textSecondary,
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
    final statusColor = isRegistered ? AppColors.success : AppColors.warning;
    final statusIcon = isRegistered ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.description_rounded, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      status.label,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isRegistered ? AppColors.surfaceElevated : primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: Icon(
                isRegistered ? Icons.visibility_outlined : Icons.how_to_vote_rounded,
                color: Colors.white,
                size: 16,
              ),
              label: Text(
                isRegistered ? 'Ver Acta' : 'Registrar Acta',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () async {
                if (isRegistered) {
                  final db = ref.read(appDatabaseProvider);
                  final act = await db.getActByStationAndLevel(mesaCode, electoralLevelId);
                  if (act != null && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (ctx) => ActDetailScreen(clientActUuid: act.clientActUuid),
                      ),
                    );
                    return;
                  }
                }

                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (ctx) => ActFormScreen(
                        pollingStationCode: mesaCode,
                        electoralLevelId: electoralLevelId,
                      ),
                    ),
                  );
                }
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
        statusText = 'Listo para registrar';
        icon = Icons.cloud_done;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: badgeColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
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
