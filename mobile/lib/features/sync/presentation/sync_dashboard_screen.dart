import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/theme/app_colors.dart';
import '../../acts/presentation/act_form_screen.dart';

class SyncDashboardScreen extends ConsumerWidget {
  const SyncDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
    final syncState = ref.watch(syncStateStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'ConteoYA — Personero',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: AppColors.info),
            tooltip: 'Sincronizar Ahora',
            onPressed: () {
              ref.read(syncEngineProvider).syncPendingOperations();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Iniciando sincronización...'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado de Conexión & Sync Engine
            _buildSyncStatusCard(syncState.value ?? SyncEngineState.idle),

            const SizedBox(height: 20),

            // Mis Mesas Asignadas
            const Text(
              'Mesas Asignadas (ERM 2026)',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildPollingStationCard(
              context: context,
              code: '030390',
              location: 'I.E. NUESTRA SEÑORA DE GUADALUPE',
              district: 'LIMA - CERCADO',
              voters: 300,
            ),
            const SizedBox(height: 12),
            _buildPollingStationCard(
              context: context,
              code: '030391',
              location: 'I.E. NUESTRA SEÑORA DE GUADALUPE',
              district: 'LIMA - CERCADO',
              voters: 300,
            ),

            const SizedBox(height: 24),

            // Actas Registradas Localmente (Drift)
            const Text(
              'Actas en Memoria Local (SQLite)',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            StreamBuilder<List<LocalAct>>(
              stream: db.select(db.localActsTable).watch(),
              builder: (context, snapshot) {
                final acts = snapshot.data ?? [];
                if (acts.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.inbox_outlined, color: AppColors.textMuted, size: 40),
                        SizedBox(height: 8),
                        Text(
                          'No hay actas registradas localmente.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: acts.length,
                  itemBuilder: (context, index) {
                    final act = acts[index];
                    return _buildLocalActItem(act);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusCard(SyncEngineState state) {
    Color badgeColor;
    String statusText;
    IconData icon;

    switch (state) {
      case SyncEngineState.syncing:
        badgeColor = AppColors.info;
        statusText = 'Sincronizando con Laravel...';
        icon = Icons.sync;
        break;
      case SyncEngineState.offline:
        badgeColor = AppColors.warning;
        statusText = 'Modo Offline (Sin Conexión)';
        icon = Icons.cloud_off;
        break;
      case SyncEngineState.error:
        badgeColor = AppColors.danger;
        statusText = 'Error temporal — Reintento programado';
        icon = Icons.error_outline;
        break;
      case SyncEngineState.idle:
      default:
        badgeColor = AppColors.success;
        statusText = 'Motor listo — Base de datos sincronizada';
        icon = Icons.cloud_done;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: badgeColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estado del Sync Engine',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                Text(
                  statusText,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollingStationCard({
    required BuildContext context,
    required String code,
    required String location,
    required String district,
    required int voters,
  }) {
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Mesa $code',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$voters electores',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            location,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          Text(
            district,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.edit_note, color: Colors.white),
              label: const Text(
                'Registrar Resultados',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (ctx) => ActFormScreen(pollingStationCode: code),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalActItem(LocalAct act) {
    Color statusColor;
    switch (act.status) {
      case 'SYNCED':
        statusColor = AppColors.success;
        break;
      case 'READY_TO_SYNC':
      case 'SYNCING':
        statusColor = AppColors.info;
        break;
      case 'FAILED':
        statusColor = AppColors.danger;
        break;
      default:
        statusColor = AppColors.draft;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mesa ${act.pollingStationCode}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'UUID: ${act.clientActUuid.substring(0, 8)}...',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              act.status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
