import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient: apiClient);
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthInitial()) {
    checkSession();
  }

  Future<void> checkSession() async {
    final session = await _repository.restoreSession();
    if (session != null) {
      state = Authenticated(session);
    } else {
      state = const Unauthenticated();
    }
  }

  Future<void> login({
    required String email,
    required String password,
    String? deviceModel,
  }) async {
    state = const AuthLoading();
    try {
      final session = await _repository.login(
        email: email,
        password: password,
        deviceModel: deviceModel,
      );
      state = Authenticated(session);
    } catch (e) {
      state = Unauthenticated(errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();
    await _repository.logout();
    state = const Unauthenticated();
  }
}
