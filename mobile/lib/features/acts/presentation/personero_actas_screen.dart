import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../mesas/domain/mesa_model.dart';
import 'act_form_screen.dart';
import 'act_detail_screen.dart';
import 'select_act_type_modal.dart';

class PersoneroActasScreen extends ConsumerWidget {
  const PersoneroActasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState is Authenticated ? authState.session : null;

    final mesasAsync = ref.watch(mesasStreamProvider);
    final personerosAsync = ref.watch(personerosStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: mesasAsync.when(
          data: (mesas) {
            // Obtener la mesa asignada a este personero
            return personerosAsync.when(
              data: (personeros) {
                // Intentar encontrar el personero por email o ID o dni
                final myPersonero = personeros.cast<dynamic>().firstWhere(
                      (p) =>
                          p.email == user?.email ||
                          (user?.personeroId != null && p.id == user?.personeroId),
                      orElse: () => personeros.isNotEmpty ? personeros.first : null,
                    );

                final assignedMesaCode = myPersonero?.pollingStationCode ?? '030390';
                final assignedMesa = mesas.cast<MesaModel?>().firstWhere(
                      (m) => m?.code == assignedMesaCode,
                      orElse: () => mesas.isNotEmpty ? mesas.first : null,
                    );

                if (assignedMesa == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No tiene una mesa de votación asignada actualmente.',
                        style: TextStyle(color: AppColors.warning, fontSize: 15),
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Informativo de la Mesa Asignada
                    _buildMesaHeaderCard(assignedMesa),
                    const SizedBox(height: 20),

                    const Text(
                      'Actas Electorales a Registrar',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Seleccione el acta correspondiente para registrar o verificar los votos:',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // Opción 1: Acta Regional
                    _buildActCard(
                      context: context,
                      ref: ref,
                      mesaCode: assignedMesa.code,
                      electoralLevelId: 1,
                      title: '🏛 Acta Regional',
                      subtitle: 'Elección para Gobernador y Vicegobernador Regional',
                      status: assignedMesa.regionalStatus,
                      primaryColor: AppColors.accent,
                    ),
                    const SizedBox(height: 16),

                    // Opción 2: Acta Municipal Provincial-Distrital
                    _buildActCard(
                      context: context,
                      ref: ref,
                      mesaCode: assignedMesa.code,
                      electoralLevelId: 2,
                      title: '🏙 Acta Municipal Provincial-Distrital',
                      subtitle: 'Elección para Alcalde y Regidores Provinciales y Distritales',
                      status: assignedMesa.municipalStatus,
                      primaryColor: AppColors.info,
                    ),
                    const SizedBox(height: 80),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final personeros = personerosAsync.asData?.value;
          dynamic myPersonero;
          if (personeros != null && personeros.isNotEmpty) {
            myPersonero = personeros.firstWhere(
              (p) => p.email == user?.email || (user?.personeroId != null && p.id == user?.personeroId),
              orElse: () => personeros.first,
            );
          }
          final code = myPersonero?.pollingStationCode ?? '030390';

          SelectActTypeModal.show(
            context,
            pollingStationCode: code,
          );
        },
        backgroundColor: AppColors.accent,
        elevation: 4,
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: const Text(
          '+ Registrar Acta',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMesaHeaderCard(MesaModel mesa) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
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
                      'Mi Mesa Asignada',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Mesa N.º ${mesa.code}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
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
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.school_outlined, color: AppColors.textMuted, size: 16),
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
              const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 16),
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

  Widget _buildActCard({
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
      borderColor: isRegistered ? AppColors.success.withValues(alpha: 0.3) : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.description_rounded, color: primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      status.label,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.3),
          ),
          const SizedBox(height: 16),

          // Botón Acción [ Registrar Acta ] o [ Ver Acta ]
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isRegistered ? AppColors.surfaceElevated : primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(
                isRegistered ? Icons.visibility_outlined : Icons.how_to_vote_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                isRegistered ? 'Ver Acta Registrada' : 'Registrar Acta',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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
}
