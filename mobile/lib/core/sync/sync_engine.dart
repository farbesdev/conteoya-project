import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../network/api_client.dart';
import 'backoff_calculator.dart';

enum SyncEngineState { idle, syncing, offline, error }

class SyncEngine {
  final AppDatabase db;
  final ApiClient apiClient;
  final Connectivity connectivity;

  Timer? _periodicTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  final StreamController<SyncEngineState> _stateController =
      StreamController<SyncEngineState>.broadcast();

  Stream<SyncEngineState> get stateStream => _stateController.stream;

  SyncEngine({
    required this.db,
    required this.apiClient,
    Connectivity? connectivity,
  }) : connectivity = connectivity ?? Connectivity();

  void start() {
    // Sincronización periódica cada 30 segundos
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (_) => syncPendingOperations());

    // Escuchar cambios de conectividad
    _connectivitySubscription = connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        _stateController.add(SyncEngineState.idle);
        syncPendingOperations();
      } else {
        _stateController.add(SyncEngineState.offline);
      }
    });

    // Intento inicial
    syncPendingOperations();
  }

  void stop() {
    _periodicTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  /// Ejecuta un ciclo de sincronización de operaciones pendientes
  Future<void> syncPendingOperations() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _stateController.add(SyncEngineState.syncing);

    try {
      final pendingOps = await db.getPendingSyncOperations();
      if (pendingOps.isEmpty) {
        _stateController.add(SyncEngineState.idle);
        _isSyncing = false;
        return;
      }

      final operationsPayload = pendingOps.map((op) {
        final Map<String, Object?> parsedPayload =
            jsonDecode(op.payloadJson) as Map<String, Object?>;
        return {
          'client_operation_id': op.clientOperationId,
          'entity_type': op.entityType,
          'entity_id': op.entityId,
          'operation': op.operation,
          'payload': parsedPayload,
          'checksum': op.checksum,
        };
      }).toList();

      final response = await apiClient.post<Map<String, Object?>>(
        '/sync',
        data: {
          'device_uuid': pendingOps.first.deviceUuid,
          'operations': operationsPayload,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final dataList = response.data!['data'] as List<Object?>? ?? [];
        for (final item in dataList) {
          if (item is Map<String, Object?>) {
            final clientOpId = item['client_operation_id'] as String?;
            final status = item['status'] as String? ?? 'FAILED';

            if (clientOpId != null) {
              if (status == 'SYNCED') {
                await db.updateSyncOpStatus(clientOpId, 'SYNCED');

                // Encontrar la operación para actualizar el estado del acta local
                final op = pendingOps.firstWhere((o) => o.clientOperationId == clientOpId);
                if (op.entityType == 'acts') {
                  final serverActId = (item['result'] as Map<String, Object?>?)?['act_id'] as int?;
                  await db.updateActStatus(op.entityId, 'SYNCED', serverActId: serverActId);
                }
              } else {
                final error = item['error'] as String? ?? 'Error en sincronización';
                final op = pendingOps.firstWhere((o) => o.clientOperationId == clientOpId);
                final nextDelay = ExponentialBackoff.calculateDelay(op.attempts + 1);
                await db.updateSyncOpStatus(
                  clientOpId,
                  'FAILED',
                  error: error,
                  nextSchedule: DateTime.now().add(nextDelay),
                );
              }
            }
          }
        }
      }

      // Sincronizar evidencias fotográficas pendientes
      await _syncPendingEvidence();

      _stateController.add(SyncEngineState.idle);
    } catch (e) {
      _stateController.add(SyncEngineState.error);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncPendingEvidence() async {
    final pendingEvidence = await (db.select(db.localActEvidenceTable)
          ..where((t) => t.isUploaded.equals(false)))
        .get();

    for (final ev in pendingEvidence) {
      final file = File(ev.localFilePath);
      if (!file.existsSync()) continue;

      try {
        // Obtener el acta local para conocer el serverActId si existe
        final act = await (db.select(db.localActsTable)
              ..where((t) => t.clientActUuid.equals(ev.clientActUuid)))
            .getSingleOrNull();

        if (act == null || act.serverActId == null) {
          // El acta aún no tiene ID en el servidor; esperar a que se sincronice el acta primero
          continue;
        }

        // 1. Solicitar presigned upload URL
        final urlRes = await apiClient.post<Map<String, Object?>>(
          '/acts/${act.serverActId}/evidence/upload-url',
          data: {
            'sha256_hash': ev.sha256Hash,
            'file_mime': ev.fileMime,
            'file_size_bytes': ev.fileSizeBytes,
          },
        );

        if (urlRes.statusCode == 200 && urlRes.data != null) {
          final data = urlRes.data!['data'] as Map<String, Object?>;
          final uploadUrl = data['upload_url'] as String;
          final objectKey = data['object_key'] as String;

          // 2. Subir binario a Cloudflare R2 vía PUT presignado
          await apiClient.uploadToPresignedUrl(
            presignedUrl: uploadUrl,
            file: file,
            fileMime: ev.fileMime,
            sha256Hash: ev.sha256Hash,
          );

          // 3. Confirmar evidencia en el backend
          await apiClient.post<Map<String, Object?>>(
            '/acts/${act.serverActId}/evidence/confirm',
            data: {
              'object_key': objectKey,
              'sha256_hash': ev.sha256Hash,
              'file_mime': ev.fileMime,
              'file_size_bytes': ev.fileSizeBytes,
              'width_px': ev.widthPx,
              'height_px': ev.heightPx,
            },
          );

          // Marcar como subida en base de datos local
          await (db.update(db.localActEvidenceTable)..where((t) => t.id.equals(ev.id))).write(
            LocalActEvidenceTableCompanion(
              isUploaded: const Value(true),
              storageKey: Value(objectKey),
            ),
          );
        }
      } catch (e) {
        // Continuará en el siguiente ciclo
      }
    }
  }
}
