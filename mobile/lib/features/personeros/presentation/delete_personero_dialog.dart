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
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '¿Eliminar personero?',
              style: TextStyle(
                color: AppColors.textPrimary,
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
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esta acción eliminará la asignación del personero a su mesa.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          onPressed: () => Navigator.pop(context, false),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
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
