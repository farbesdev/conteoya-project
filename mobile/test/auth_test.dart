import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:conteoya_mobile/core/network/api_client.dart';
import 'package:conteoya_mobile/features/auth/data/auth_repository.dart';
import 'package:conteoya_mobile/features/auth/domain/user_model.dart';
import 'package:conteoya_mobile/features/auth/domain/auth_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Auth Tests', () {
    test('UserSession serializa y deserializa correctamente con tipos int nativos', () {
      const session = UserSession(
        id: 3,
        name: 'Juan Personero',
        email: 'personero@conteoya.pe',
        role: 'PERSONERO',
        personeroId: 1,
        token: 'mock-sanctum-token-1234',
        deviceUuid: 'device-uuid-abcd',
      );

      final json = session.toJson();
      final restored = UserSession.fromJson(json);

      expect(restored.id, 3);
      expect(restored.name, 'Juan Personero');
      expect(restored.role, 'PERSONERO');
      expect(restored.personeroId, 1);
      expect(restored.token, 'mock-sanctum-token-1234');
      expect(restored.deviceUuid, 'device-uuid-abcd');
    });

    test('UserSession soporta IDs numéricos serializados como Strings sin lanzar type exception', () {
      final backendJson = {
        'id': '3',
        'name': 'Juan Personero',
        'email': 'personero@conteoya.pe',
        'role': 'PERSONERO',
        'personero_id': '1',
        'token': 'sanctum-token-xyz',
        'device_uuid': 'device-123',
      };

      final restored = UserSession.fromJson(backendJson);
      expect(restored.id, 3);
      expect(restored.personeroId, 1);

      final fromBackend = UserSession.fromBackendResponse(
        userData: {
          'id': '45',
          'name': 'Admin Demo',
          'email': 'admin@conteoya.pe',
          'role': 'ADMIN',
          'personero_id': null,
        },
        token: 'token-abc',
        deviceUuid: 'dev-456',
      );

      expect(fromBackend.id, 45);
      expect(fromBackend.personeroId, isNull);
    });

    test('AuthRepository maneja respuestas de error en formato HTML o String sin lanzar String-index exception', () async {
      final mockDio = Dio();
      final apiClient = ApiClient(customDio: mockDio);
      final repo = AuthRepository(apiClient: apiClient);

      mockDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 404,
                  data: '<!DOCTYPE html><html><head><title>404 Not Found</title></head><body>404 Not Found</body></html>',
                ),
              ),
            );
          },
        ),
      );

      expect(
        () async => await repo.login(email: 'test@test.pe', password: 'password'),
        throwsA(predicate((e) => e is Exception && e.toString().contains('404'))),
      );
    });

    test('AuthState sealed classes modelan estados exhaustivos', () {
      const state1 = AuthInitial();
      const state2 = AuthLoading();
      const state3 = Unauthenticated(errorMessage: 'Credenciales inválidas');
      const state4 = Authenticated(UserSession(
        id: 1,
        name: 'Admin',
        email: 'admin@conteoya.pe',
        role: 'ADMIN',
        token: 'token',
        deviceUuid: 'uuid',
      ));

      expect(state1, isA<AuthState>());
      expect(state2, isA<AuthState>());
      expect(state3, isA<AuthState>());
      expect(state4, isA<AuthState>());
      expect(state3.errorMessage, 'Credenciales inválidas');
      expect(state4.session.name, 'Admin');
    });
  });
}
