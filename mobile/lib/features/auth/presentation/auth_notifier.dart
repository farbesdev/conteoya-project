import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return AuthRepository(apiClient: apiClient, db: db);
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(repo, apiClient);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final ApiClient _apiClient;

  AuthNotifier(this._repository, this._apiClient) : super(const AuthInitial()) {
    _apiClient.onUnauthorized = (reason) {
      logoutWithReason(reason);
    };
    _init();
  }

  Future<void> _init() async {
    await _repository.initServerUrl();
    await checkSession();
  }

  Future<void> checkSession() async {
    final session = await _repository.restoreSession();
    if (session != null) {
      state = Authenticated(session);
    } else {
      state = const Unauthenticated();
    }
  }

  String getServerUrl() {
    return _repository.getCurrentServerUrl();
  }

  Future<void> updateServerUrl(String url) async {
    await _repository.updateServerUrl(url);
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
    await _repository.logout();
    state = const Unauthenticated();
  }

  Future<void> logoutWithReason(String reason) async {
    await _repository.logout();
    state = Unauthenticated(errorMessage: reason);
  }
}
