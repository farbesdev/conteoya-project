import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'act_form_screen.dart';

class SelectActTypeModal extends StatelessWidget {
  final String pollingStationCode;
  final String? mesaLocationName;

  const SelectActTypeModal({
    super.key,
    required this.pollingStationCode,
    this.mesaLocationName,
  });

  static Future<void> show(
    BuildContext context, {
    required String pollingStationCode,
    String? mesaLocationName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SelectActTypeModal(
        pollingStationCode: pollingStationCode,
        mesaLocationName: mesaLocationName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.how_to_vote_rounded, color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Registrar Acta',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Mesa $pollingStationCode ${mesaLocationName != null ? '• $mesaLocationName' : ''}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Seleccione el tipo de acta electoral que desea procesar:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Opción 1: Acta Regional
          _buildActTypeButton(
            context: context,
            title: '🏛 Acta Regional',
            subtitle: 'Gobernador y Vicegobernador Regional',
            color: AppColors.accent,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (ctx) => ActFormScreen(
                    pollingStationCode: pollingStationCode,
                    electoralLevelId: 1,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          // Opción 2: Acta Municipal Provincial-Distrital
          _buildActTypeButton(
            context: context,
            title: '🏙 Acta Municipal Provincial-Distrital',
            subtitle: 'Alcalde y Regidores Provinciales / Distritales',
            color: AppColors.info,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (ctx) => ActFormScreen(
                    pollingStationCode: pollingStationCode,
                    electoralLevelId: 2,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActTypeButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.description_rounded, color: color, size: 24),
                ),
                const SizedBox(width: 14),
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
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: color, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
