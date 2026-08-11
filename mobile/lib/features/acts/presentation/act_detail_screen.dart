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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Detalle de Acta Electoral',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
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
                _buildHeaderCard(act, levelOption),
                const SizedBox(height: 16),

                // Resumen de Totales
                if (totals != null) ...[
                  _buildTotalsCard(totals),
                  const SizedBox(height: 16),
                ],

                // Desglose por Organización Política
                const Text(
                  'Resultados por Organización Política',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildResultsTable(results),
                const SizedBox(height: 16),

                // Evidencia Fotográfica
                if (evidence != null) ...[
                  _buildEvidenceCard(evidence),
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

  Widget _buildHeaderCard(LocalAct act, ElectoralLevelOption level) {
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
                      style: const TextStyle(
                        color: AppColors.textPrimary,
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
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.fingerprint_rounded, color: AppColors.textMuted, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'UUID: ${act.clientActUuid}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(LocalActTotal totals) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Totales del Acta',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTotalItem('Electores Hábiles', '${totals.registeredVoters}')),
              Expanded(child: _buildTotalItem('Ciudadanos que Votaron', '${totals.votersWhoVoted}')),
              Expanded(child: _buildTotalItem('Total Votos Emitidos', '${totals.totalVotes}')),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildTotalItem('Votos en Blanco', '${totals.blankVotes}')),
              Expanded(child: _buildTotalItem('Votos Nulos', '${totals.nullVotes}')),
              Expanded(child: _buildTotalItem('Votos Impugnados', '${totals.challengedVotes}')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }

  Widget _buildResultsTable(List<LocalActResult> results) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: results.length,
        separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
        itemBuilder: (context, index) {
          final res = results[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                PartyLogoWidget(
                  logoUrl: null,
                  name: res.politicalOrganizationName ?? 'Organización ${index + 1}',
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    res.politicalOrganizationName ?? 'Organización ${index + 1}',
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
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

  Widget _buildEvidenceCard(LocalActEvidence evidence) {
    final file = File(evidence.localFilePath);
    final exists = file.existsSync();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Evidencia Fotográfica del Acta',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
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
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Foto guardada en almacenamiento local', style: TextStyle(color: AppColors.textMuted)),
            ),
          const SizedBox(height: 8),
          Text(
            'SHA-256: ${evidence.sha256Hash}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
