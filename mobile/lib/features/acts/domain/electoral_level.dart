import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ElectoralLevelOption {
  final int id;
  final String code;
  final String title;
  final String shortTitle;
  final String subtitle;
  final IconData icon;
  final Color color;

  const ElectoralLevelOption({
    required this.id,
    required this.code,
    required this.title,
    required this.shortTitle,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

const List<ElectoralLevelOption> kElectoralLevels = [
  ElectoralLevelOption(
    id: 1,
    code: 'REGIONAL_GOBERNADOR',
    title: 'Gobernador y Vicegobernador Regional',
    shortTitle: 'Gobernador Regional',
    subtitle: 'Elección Regional — Fórmula Gobernador y Vicegobernador',
    icon: Icons.account_balance_rounded,
    color: AppColors.accent,
  ),
  ElectoralLevelOption(
    id: 3,
    code: 'MUNICIPAL_PROVINCIAL',
    title: 'Alcalde y Regidores Provinciales',
    shortTitle: 'Municipal Provincial',
    subtitle: 'Elección Municipal — Alcaldía y Concejo Provincial',
    icon: Icons.location_city_rounded,
    color: AppColors.info,
  ),
  ElectoralLevelOption(
    id: 4,
    code: 'MUNICIPAL_DISTRITAL',
    title: 'Alcalde y Regidores Distritales',
    shortTitle: 'Municipal Distrital',
    subtitle: 'Elección Municipal — Alcaldía y Concejo Distrital',
    icon: Icons.home_work_rounded,
    color: AppColors.warning,
  ),
];

ElectoralLevelOption getElectoralLevelById(int id) {
  return kElectoralLevels.firstWhere(
    (level) => level.id == id,
    orElse: () => kElectoralLevels.first,
  );
}
