import 'package:flutter_test/flutter_test.dart';
import 'package:conteoya_mobile/features/auth/domain/user_model.dart';
import 'package:conteoya_mobile/features/auth/domain/auth_state.dart';

void main() {
  group('Auth Tests', () {
    test('UserSession serializa y deserializa correctamente', () {
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
      expect(restored.token, 'mock-sanctum-token-1234');
      expect(restored.deviceUuid, 'device-uuid-abcd');
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
