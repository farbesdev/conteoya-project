import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conteoya_mobile/core/database/app_database.dart';
import 'package:conteoya_mobile/core/network/api_client.dart';
import 'package:conteoya_mobile/core/providers.dart';
import 'package:conteoya_mobile/core/sync/sync_engine.dart';
import 'package:conteoya_mobile/main.dart';

void main() {
  testWidgets('ConteoYaApp carga el dashboard correctamente', (WidgetTester tester) async {
    final memoryDb = AppDatabase(NativeDatabase.memory());
    final testEngine = SyncEngine(db: memoryDb, apiClient: ApiClient());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(memoryDb),
          syncEngineProvider.overrideWithValue(testEngine),
        ],
        child: const ConteoYaApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ConteoYA — Personero'), findsOneWidget);
    expect(find.text('Mesas Asignadas (ERM 2026)'), findsOneWidget);
    expect(find.text('Mesa 030390'), findsOneWidget);

    testEngine.stop();
    await memoryDb.close();
  });
}
