import 'package:drift/native.dart';
import 'package:flutter/material.dart';
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
    expect(find.textContaining('Correo Electrónico'), findsOneWidget);

    testEngine.stop();
    await memoryDb.close();
  });

  testWidgets('ConteoYaApp muestra AppShell con 3 tabs para ADMIN', (WidgetTester tester) async {
    final memoryDb = AppDatabase(NativeDatabase.memory());
    await memoryDb.seedInitialDataIfEmpty();
    final testEngine = SyncEngine(db: memoryDb, apiClient: ApiClient());

    const adminSession = UserSession(
      id: 1,
      name: 'Admin Demo',
      email: 'admin@conteoya.pe',
      role: 'ADMIN',
      token: 'mock-token',
      deviceUuid: 'dev-uuid',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(memoryDb),
          syncEngineProvider.overrideWithValue(testEngine),
          authNotifierProvider.overrideWith((ref) => MockAuthNotifier(const Authenticated(adminSession))),
        ],
        child: const ConteoYaApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Debe mostrar los 3 tabs de navegación y métricas
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Personeros'), findsNWidgets(2)); // Tarjeta de métrica + Tab de navegación
    expect(find.text('Actas'), findsNWidgets(2)); // Tarjeta de métrica + Tab de navegación
    expect(find.text('Admin Demo • ADMIN'), findsOneWidget);

    testEngine.stop();
    await memoryDb.close();
  });

  testWidgets('ConteoYaApp muestra AppShell con 2 tabs para PERSONERO (sin tab de personeros)', (WidgetTester tester) async {
    final memoryDb = AppDatabase(NativeDatabase.memory());
    await memoryDb.seedInitialDataIfEmpty();
    final testEngine = SyncEngine(db: memoryDb, apiClient: ApiClient());

    const personeroSession = UserSession(
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
          authNotifierProvider.overrideWith((ref) => MockAuthNotifier(const Authenticated(personeroSession))),
        ],
        child: const ConteoYaApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Debe mostrar solo 2 tabs (Dashboard y Actas)
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Actas'), findsOneWidget);
    expect(find.text('Personeros'), findsNothing); // Personero NO tiene acceso
    expect(find.text('Juan Personero • PERSONERO'), findsOneWidget);

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
