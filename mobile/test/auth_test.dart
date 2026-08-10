import 'package:flutter_test/flutter_test.dart';
import 'package:conteoya_mobile/features/auth/domain/user_model.dart';
import 'package:conteoya_mobile/features/auth/domain/auth_state.dart';

void main() {
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
        'id': '3', // String en vez de int
        'name': 'Juan Personero',
        'email': 'personero@conteoya.pe',
        'role': 'PERSONERO',
        'personero_id': '1', // String en vez de int
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
