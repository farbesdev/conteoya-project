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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final textMuted = AppColors.textMutedOf(context);
    final warningColor = AppColors.warningOf(context);
    final borderColor = AppColors.borderOf(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.info, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sugerencias OCR / IA Asistida',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: warningColor.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: warningColor.withValues(alpha: isDark ? 0.3 : 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: warningColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Principio ConteoYA: La IA nunca confirma el acta. Revise los campos con baja confianza antes de aplicar.',
                    style: TextStyle(color: textPrimary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Campos Extraídos & Confianza:',
            style: TextStyle(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
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
                          ? warningColor.withValues(alpha: 0.1)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isLow ? warningColor : borderColor,
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
                                style: TextStyle(color: textMuted, fontSize: 12),
                              ),
                              Text(
                                '$value',
                                style: TextStyle(
                                  color: textPrimary,
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
                            color: isLow ? warningColor : AppColors.successOf(context),
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
                  style: TextStyle(color: textSecondary, fontSize: 13),
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
