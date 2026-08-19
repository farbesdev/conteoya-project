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

class PersoneroActasScreen extends ConsumerWidget {
  const PersoneroActasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState is Authenticated ? authState.session : null;

    final mesasAsync = ref.watch(mesasStreamProvider);
    final personerosAsync = ref.watch(personerosStreamProvider);

    final theme = Theme.of(context);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurface.withAlpha(178);

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
                        'No tiene una mesa de votación asignada actualmente.',
                        style: TextStyle(color: AppColors.warning, fontSize: 15),
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mis Actas Electorales',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mesa N.º ${assignedMesa.code} • ${assignedMesa.locationName}',
                          style: TextStyle(color: textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Resumen de la mesa
                    _buildMesaHeaderCard(context, assignedMesa),
                    const SizedBox(height: 20),

                    // Título sección
                    Text(
                      'Actas Electorales de la Mesa',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 1. Acta Regional
                    _buildActCard(
                      context: context,
                      ref: ref,
                      mesaCode: assignedMesa.code,
                      electoralLevelId: 1,
                      title: 'Acta Regional',
                      subtitle: 'Elección de Gobernador y Vicegobernador Regional',
                      icon: Icons.account_balance_rounded,
                      iconColor: AppColors.accent,
                      status: assignedMesa.regionalStatus,
                    ),
                    const SizedBox(height: 12),

                    // 2. Acta Municipal Provincial-Distrital
                    _buildActCard(
                      context: context,
                      ref: ref,
                      mesaCode: assignedMesa.code,
                      electoralLevelId: 2,
                      title: 'Acta Municipal Provincial-Distrital',
                      subtitle: 'Elección de Alcaldes y Concejos Municipales',
                      icon: Icons.location_city_rounded,
                      iconColor: AppColors.info,
                      status: assignedMesa.municipalStatus,
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

  Widget _buildMesaHeaderCard(BuildContext context, MesaModel mesa) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurface.withAlpha(178);
    final textMuted = theme.colorScheme.onSurface.withAlpha(128);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.how_to_vote_rounded, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Mesa N.º ${mesa.code}',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
                  style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${mesa.locationName} — ${mesa.districtName}, ${mesa.provinceName}',
            style: TextStyle(color: textMuted, fontSize: 12),
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
    required IconData icon,
    required Color iconColor,
    required ActRegistrationStatus status,
  }) {
    final isRegistered = status.isRegistrada;
    final statusColor = isRegistered ? AppColors.successOf(context) : AppColors.warningOf(context);

    final theme = Theme.of(context);
    final textPrimary = theme.colorScheme.onSurface;
    final textSecondary = theme.colorScheme.onSurface.withAlpha(178);
    final buttonBg = isRegistered ? theme.colorScheme.surfaceContainerHigh : iconColor;

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
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
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
                        fontSize: 15,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonBg,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(
                isRegistered ? Icons.visibility_outlined : Icons.edit_note_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                isRegistered ? 'Ver Detalle del Acta' : 'Registrar Acta Ahora',
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
}
