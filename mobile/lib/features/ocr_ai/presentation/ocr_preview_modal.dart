import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class OcrPreviewModal extends StatelessWidget {
  final Map<String, Object?> extractionData;
  final VoidCallback onApply;

  const OcrPreviewModal({
    super.key,
    required this.extractionData,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final confidenceMap = (extractionData['confidence_map'] as List<Object?>?) ?? [];
    final results = (extractionData['results'] as List<Object?>?) ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.info, size: 24),
              const SizedBox(width: 10),
              const Text(
                'Sugerencias OCR / IA Asistida',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Principio ConteoYA: La IA nunca confirma el acta. Revise los campos con baja confianza antes de aplicar.',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Campos Extraídos & Confianza:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ...confidenceMap.map((item) {
                  if (item is! Map<String, Object?>) return const SizedBox.shrink();
                  final field = item['field'] as String? ?? '';
                  final value = item['value'];
                  final confidence = (item['confidence'] as num?)?.toDouble() ?? 1.0;
                  final isLow = confidence < 0.85;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isLow
                          ? AppColors.warning.withValues(alpha: 0.1)
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isLow ? AppColors.warning : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                field,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                              ),
                              Text(
                                '$value',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLow ? AppColors.warning : AppColors.success,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${(confidence * 100).toStringAsFixed(0)}% ${isLow ? '⚠️ Revisar' : '✓ OK'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 10),
                Text(
                  'Listas detectadas: ${results.length}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Confirmar y Cargar en Formulario',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onPressed: () {
                onApply();
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
