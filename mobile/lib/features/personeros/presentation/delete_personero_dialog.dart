import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DeletePersoneroDialog extends StatelessWidget {
  final String personeroName;
  final VoidCallback onConfirm;

  const DeletePersoneroDialog({
    super.key,
    required this.personeroName,
    required this.onConfirm,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String personeroName,
    required VoidCallback onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => DeletePersoneroDialog(
        personeroName: personeroName,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final borderColor = AppColors.borderOf(context);
    final dangerColor = AppColors.dangerOf(context);

    return AlertDialog(
      backgroundColor: AppColors.surfaceOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: dangerColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.warning_amber_rounded, color: dangerColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '¿Eliminar personero?',
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            personeroName,
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Esta acción eliminará la asignación del personero a su mesa.',
            style: TextStyle(
              color: textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          child: Text(
            'Cancelar',
            style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
          ),
          onPressed: () => Navigator.pop(context, false),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: dangerColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: const Text(
            'Eliminar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            Navigator.pop(context, true);
            onConfirm();
          },
        ),
      ],
    );
  }
}
