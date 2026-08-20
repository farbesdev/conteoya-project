import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/electoral_level.dart';
import 'party_logo_widget.dart';

class ActDetailScreen extends ConsumerWidget {
  final String clientActUuid;

  const ActDetailScreen({super.key, required this.clientActUuid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
    final textPrimary = AppColors.textPrimaryOf(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: Text(
          'Detalle de Acta Electoral',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, Object?>>(
        future: _fetchActDetails(db),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Text(
                'Error al cargar el acta: ${snapshot.error}',
                style: const TextStyle(color: AppColors.danger),
              ),
            );
          }

          final data = snapshot.data!;
          final act = data['act'] as LocalAct;
          final totals = data['totals'] as LocalActTotal?;
          final results = data['results'] as List<LocalActResult>;
          final evidence = data['evidence'] as LocalActEvidence?;
          final levelOption = getElectoralLevelById(act.electoralLevelId);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                _buildHeaderCard(context, act, levelOption),
                const SizedBox(height: 16),

                // Resumen de Totales
                if (totals != null) ...[
                  _buildTotalsCard(context, totals),
                  const SizedBox(height: 16),
                ],

                // Desglose por Organización Política
                Text(
                  'Resultados por Organización Política',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildResultsTable(context, results),
                const SizedBox(height: 16),

                // Evidencia Fotográfica
                if (evidence != null) ...[
                  _buildEvidenceCard(context, evidence),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, Object?>> _fetchActDetails(AppDatabase db) async {
    final act = await (db.select(db.localActsTable)..where((t) => t.clientActUuid.equals(clientActUuid))).getSingle();
    final totals = await db.getTotalsForAct(clientActUuid);
    final results = await db.getResultsForAct(clientActUuid);
    final evidence = await db.getEvidenceForAct(clientActUuid);

    return {
      'act': act,
      'totals': totals,
      'results': results,
      'evidence': evidence,
    };
  }

  Widget _buildHeaderCard(BuildContext context, LocalAct act, ElectoralLevelOption level) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textMuted = AppColors.textMutedOf(context);
    final borderColor = AppColors.borderOf(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: level.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(level.icon, color: level.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Mesa ${act.pollingStationCode}',
                      style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: Text(
                  act.status,
                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.fingerprint_rounded, color: textMuted, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'UUID: ${act.clientActUuid}',
                  style: TextStyle(color: textMuted, fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(BuildContext context, LocalActTotal totals) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final borderColor = AppColors.borderOf(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Totales del Acta',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTotalItem(context, 'Electores Hábiles', '${totals.registeredVoters}')),
              Expanded(child: _buildTotalItem(context, 'Ciudadanos que Votaron', '${totals.votersWhoVoted}')),
              Expanded(child: _buildTotalItem(context, 'Total Votos Emitidos', '${totals.totalVotes}')),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildTotalItem(context, 'Votos en Blanco', '${totals.blankVotes}')),
              Expanded(child: _buildTotalItem(context, 'Votos Nulos', '${totals.nullVotes}')),
              Expanded(child: _buildTotalItem(context, 'Votos Impugnados', '${totals.challengedVotes}')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalItem(BuildContext context, String label, String value) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textMuted = AppColors.textMutedOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: textMuted, fontSize: 11)),
      ],
    );
  }

  Widget _buildResultsTable(BuildContext context, List<LocalActResult> results) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final borderColor = AppColors.borderOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rowBadgeBg = isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: results.length,
        separatorBuilder: (_, __) => Divider(color: borderColor, height: 1),
        itemBuilder: (context, index) {
          final res = results[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                PartyLogoWidget(
                  logoUrl: res.politicalOrganizationId != null
                      ? 'https://stovotoinformadodev.blob.core.windows.net/contenedor-2/${res.politicalOrganizationId}.png'
                      : null,
                  partyId: res.politicalOrganizationId,
                  name: res.politicalOrganizationName ?? 'Organización ${index + 1}',
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    res.politicalOrganizationName ?? 'Organización ${index + 1}',
                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: rowBadgeBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    '${res.votes} votos',
                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEvidenceCard(BuildContext context, LocalActEvidence evidence) {
    final file = File(evidence.localFilePath);
    final exists = file.existsSync();
    final textPrimary = AppColors.textPrimaryOf(context);
    final textMuted = AppColors.textMutedOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderBg = isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evidencia Fotográfica del Acta',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          if (exists)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                file,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: placeholderBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Foto guardada en almacenamiento local', style: TextStyle(color: textMuted)),
            ),
          const SizedBox(height: 8),
          Text(
            'SHA-256: ${evidence.sha256Hash}',
            style: TextStyle(color: textMuted, fontSize: 11, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
