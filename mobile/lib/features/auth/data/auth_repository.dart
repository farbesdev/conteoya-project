import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_client.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final ApiClient apiClient;

  static const String _sessionKey = 'conteoya_user_session';
  static const String _deviceUuidKey = 'conteoya_device_uuid';

  AuthRepository({required this.apiClient});

  /// Obtiene o genera un UUID persistente para este dispositivo móvil
  Future<String> getOrCreateDeviceUuid() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceUuid = prefs.getString(_deviceUuidKey);
    if (deviceUuid == null) {
      deviceUuid = const Uuid().v4();
      await prefs.setString(_deviceUuidKey, deviceUuid);
    }
    return deviceUuid;
  }

  /// Inicia sesión en el backend Laravel y guarda el token localmente
  Future<UserSession> login({
    required String email,
    required String password,
    String? deviceModel,
  }) async {
    final deviceUuid = await getOrCreateDeviceUuid();

    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        '/login',
        data: {
          'email': email.trim(),
          'password': password,
          'device_uuid': deviceUuid,
          'device_model': deviceModel ?? 'Flutter Mobile Device',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final token = data['access_token'] as String;
        final userData = data['user'] as Map<String, dynamic>;

        final session = UserSession(
          id: userData['id'] as int,
          name: userData['name'] as String,
          email: userData['email'] as String,
          role: userData['role'] as String,
          personeroId: userData['personero_id'] as int?,
          token: token,
          deviceUuid: deviceUuid,
        );

        // Guardar sesión y configurar token en el cliente HTTP
        apiClient.setAuthToken(token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_sessionKey, jsonEncode(session.toJson()));

        return session;
      } else {
        throw Exception('Respuesta inválida del servidor');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Credenciales incorrectas. Verifique su email y contraseña.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('El usuario se encuentra inactivo.');
      } else if (e.type == DioExceptionType.connectionError ||
                 e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Sin conexión al servidor. Verifique su red.');
      }
      throw Exception(e.response?.data?['message'] ?? 'Error al iniciar sesión.');
    }
  }

  /// Restaura la sesión persistida para soporte Offline-First
  Future<UserSession?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionString = prefs.getString(_sessionKey);
    if (sessionString == null) return null;

    try {
      final sessionJson = jsonDecode(sessionString) as Map<String, dynamic>;
      final session = UserSession.fromJson(sessionJson);
      apiClient.setAuthToken(session.token);
      return session;
    } catch (_) {
      await prefs.remove(_sessionKey);
      return null;
    }
  }

  /// Cierra sesión localmente y en el backend
  Future<void> logout() async {
    try {
      await apiClient.post<void>('/logout');
    } catch (_) {
      // Ignorar errores de red en logout offline
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      apiClient.setAuthToken('');
    }
  }
}
