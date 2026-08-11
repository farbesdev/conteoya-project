import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database/app_database.dart';
import 'network/api_client.dart';
import 'sync/sync_engine.dart';
import '../features/personeros/data/personeros_repository.dart';
import '../features/personeros/domain/personero_model.dart';
import '../features/mesas/data/mesas_repository.dart';
import '../features/mesas/domain/mesa_model.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  // Inicializar sembrado de datos local si la base de datos está vacía
  db.seedInitialDataIfEmpty();
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

// Repositorios
final personerosRepositoryProvider = Provider<PersonerosRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PersonerosRepository(db: db);
});

final mesasRepositoryProvider = Provider<MesasRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return MesasRepository(db: db);
});

// Streams Reactivos
final personerosStreamProvider = StreamProvider<List<PersoneroModel>>((ref) {
  final repo = ref.watch(personerosRepositoryProvider);
  return repo.watchPersoneros();
});

final mesasStreamProvider = StreamProvider<List<MesaModel>>((ref) {
  final repo = ref.watch(mesasRepositoryProvider);
  return repo.watchMesasWithDetails();
});

final allActsStreamProvider = StreamProvider<List<LocalAct>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllActs();
});
