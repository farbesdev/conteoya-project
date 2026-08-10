import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conteoya_mobile/core/database/app_database.dart';
import 'package:conteoya_mobile/core/network/api_client.dart';
import 'package:conteoya_mobile/core/providers.dart';
import 'package:conteoya_mobile/core/sync/sync_engine.dart';
import 'package:conteoya_mobile/features/auth/domain/auth_state.dart';
import 'package:conteoya_mobile/features/auth/domain/user_model.dart';
import 'package:conteoya_mobile/features/auth/presentation/auth_notifier.dart';
import 'package:conteoya_mobile/main.dart';

void main() {
  testWidgets('ConteoYaApp muestra LoginScreen cuando no está autenticado', (WidgetTester tester) async {
    final memoryDb = AppDatabase(NativeDatabase.memory());
    final testEngine = SyncEngine(db: memoryDb, apiClient: ApiClient());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(memoryDb),
          syncEngineProvider.overrideWithValue(testEngine),
          authNotifierProvider.overrideWith((ref) => MockAuthNotifier(const Unauthenticated())),
        ],
        child: const ConteoYaApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ConteoYA'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Correo Electrónico'), findsOneWidget);

    testEngine.stop();
    await memoryDb.close();
  });

  testWidgets('ConteoYaApp muestra SyncDashboardScreen cuando está autenticado', (WidgetTester tester) async {
    final memoryDb = AppDatabase(NativeDatabase.memory());
    final testEngine = SyncEngine(db: memoryDb, apiClient: ApiClient());

    const mockSession = UserSession(
      id: 3,
      name: 'Juan Personero',
      email: 'personero@conteoya.pe',
      role: 'PERSONERO',
      personeroId: 1,
      token: 'mock-token',
      deviceUuid: 'dev-uuid',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(memoryDb),
          syncEngineProvider.overrideWithValue(testEngine),
          authNotifierProvider.overrideWith((ref) => MockAuthNotifier(const Authenticated(mockSession))),
        ],
        child: const ConteoYaApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ConteoYA'), findsOneWidget);
    expect(find.text('Juan Personero (PERSONERO)'), findsOneWidget);
    expect(find.text('Mesas Asignadas (ERM 2026)'), findsOneWidget);
    expect(find.text('Mesa 030390'), findsOneWidget);

    testEngine.stop();
    await memoryDb.close();
  });
}

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.initialState);

  @override
  String getServerUrl() => 'https://api.unifact.net.pe/api/v1';

  @override
  Future<void> updateServerUrl(String url) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
