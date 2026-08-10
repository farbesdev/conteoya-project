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
  static const String _serverUrlKey = 'conteoya_server_url';

  AuthRepository({required this.apiClient});

  /// Inicializa la URL del servidor desde la configuración guardada
  Future<void> initServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_serverUrlKey);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      apiClient.setBaseUrl(savedUrl);
    }
  }

  /// Guarda una nueva URL base del servidor
  Future<void> updateServerUrl(String newUrl) async {
    apiClient.setBaseUrl(newUrl);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, apiClient.baseUrl);
  }

  /// Obtiene la URL actual configurada
  String getCurrentServerUrl() {
    return apiClient.baseUrl;
  }

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
      final response = await apiClient.post<dynamic>(
        '/login',
        data: {
          'email': email.trim(),
          'password': password,
          'device_uuid': deviceUuid,
          'device_model': deviceModel ?? 'Flutter Mobile Device',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        Map<String, dynamic> data;
        if (response.data is Map<String, dynamic>) {
          data = response.data as Map<String, dynamic>;
        } else if (response.data is Map) {
          data = Map<String, dynamic>.from(response.data as Map);
        } else if (response.data is String) {
          data = jsonDecode(response.data as String) as Map<String, dynamic>;
        } else {
          throw Exception('Formato de respuesta inesperado del servidor');
        }

        final token = data['access_token']?.toString() ?? '';
        
        Map<String, dynamic> userData = {};
        if (data['user'] is Map<String, dynamic>) {
          userData = data['user'] as Map<String, dynamic>;
        } else if (data['user'] is Map) {
          userData = Map<String, dynamic>.from(data['user'] as Map);
        }

        final session = UserSession.fromBackendResponse(
          userData: userData,
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
                 e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.sendTimeout ||
                 e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Sin conexión al servidor (${apiClient.baseUrl}). Verifique que el VPS esté accesible y su conexión de red.',
        );
      }
      throw Exception(e.response?.data?['message'] ?? 'Error al iniciar sesión: ${e.message}');
    }
  }

  /// Restaura la sesión persistida para soporte Offline-First
  Future<UserSession?> restoreSession() async {
    await initServerUrl();
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
