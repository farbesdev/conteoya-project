import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database/app_database.dart';
import 'network/api_client.dart';
import 'sync/sync_engine.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final client = ref.watch(apiClientProvider);
  final engine = SyncEngine(db: db, apiClient: client);
  engine.start();
  ref.onDispose(() => engine.stop());
  return engine;
});

final syncStateStreamProvider = StreamProvider<SyncEngineState>((ref) {
  final engine = ref.watch(syncEngineProvider);
  return engine.stateStream;
});
