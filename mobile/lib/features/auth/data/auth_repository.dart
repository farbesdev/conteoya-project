import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/network/api_client.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final ApiClient apiClient;
  final AppDatabase? db;

  static const String _sessionKey = 'conteoya_user_session';
  static const String _deviceUuidKey = 'conteoya_device_uuid';
  static const String _serverUrlKey = 'conteoya_server_url';

  AuthRepository({required this.apiClient, this.db});

  /// Inicializa la URL del servidor desde la configuración guardada
  Future<void> initServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_serverUrlKey);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      apiClient.setBaseUrl(savedUrl);
    }
  }

  /// Guarda una nueva URL base del servidor y limpia tokens/sesiones del servidor previo
  Future<void> updateServerUrl(String newUrl) async {
    apiClient.setBaseUrl(newUrl);
    apiClient.setAuthToken('');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, apiClient.baseUrl);
    await prefs.remove(_sessionKey);
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

  /// Inicia sesión en el backend Laravel o base de datos local SQLite (Offline-First)
  Future<UserSession> login({
    required String email,
    required String password,
    String? deviceModel,
  }) async {
    final deviceUuid = await getOrCreateDeviceUuid();

    // Limpiar token residual previo para evitar conflictos de autenticación
    apiClient.setAuthToken('');

    Object? dioOrServerException;
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
        final Map<String, dynamic> data = _normalizeToMap(response.data);
        final token = data['access_token']?.toString() ?? '';
        final userData = _normalizeToMap(data['user']);

        final session = UserSession.fromBackendResponse(
          userData: userData,
          token: token,
          deviceUuid: deviceUuid,
        );

        apiClient.setAuthToken(token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_sessionKey, jsonEncode(session.toJson()));

        return session;
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final rawErrorData = e.response?.data;

      String serverMessage = '';
      if (rawErrorData is Map) {
        serverMessage = rawErrorData['message']?.toString() ?? '';
      } else if (rawErrorData is String) {
        if (rawErrorData.contains('<html') || rawErrorData.contains('<!DOCTYPE')) {
          serverMessage = 'El servidor devolvió una página HTML (Código HTTP $statusCode).';
        } else {
          serverMessage = rawErrorData;
        }
      }

      if (statusCode == 401) {
        dioOrServerException = Exception('Credenciales incorrectas. Verifique su correo y contraseña.');
      } else if (statusCode == 403) {
        dioOrServerException = Exception('El usuario se encuentra inactivo en el sistema.');
      } else if (statusCode == 404) {
        dioOrServerException = Exception('Ruta no encontrada (404) en ${apiClient.baseUrl}/login. Verifique la URL del servidor.');
      } else if (statusCode == 500) {
        dioOrServerException = Exception(
          serverMessage.isNotEmpty
              ? 'Error interno del servidor (500): $serverMessage'
              : 'Error interno del servidor (500). Verifique los logs en el VPS.',
        );
      } else if (e.type == DioExceptionType.connectionError ||
                 e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.sendTimeout ||
                 e.type == DioExceptionType.receiveTimeout) {
        final detail = e.error?.toString() ?? e.message ?? '';
        dioOrServerException = Exception('Sin conexión con ${apiClient.baseUrl}. $detail');
      } else {
        dioOrServerException = Exception(
          serverMessage.isNotEmpty
              ? serverMessage
              : 'Error al conectar (${statusCode ?? 'sin respuesta'}): ${e.message ?? 'Desconocido'}',
        );
      }
    } catch (e) {
      dioOrServerException = e;
    }

    // Fallback Offline-First: Si falló por falta de red y existe base local SQLite, buscar personero local
    if (db != null && dioOrServerException != null) {
      final isConnectionError = dioOrServerException.toString().contains('Sin conexión') ||
          dioOrServerException.toString().contains('Connection refused') ||
          dioOrServerException.toString().contains('SocketException');

      if (isConnectionError) {
        final localPersonero = await db!.getPersoneroByEmailOrDni(email);
        if (localPersonero != null) {
          if (!localPersonero.isActive) {
            throw Exception('Su cuenta se encuentra inhabilitada. Comuníquese con el Administrador.');
          }
          final session = UserSession(
            id: localPersonero.id,
            name: '${localPersonero.firstName} ${localPersonero.lastName}',
            email: localPersonero.email ?? '${localPersonero.dni}@conteoya.pe',
            role: 'PERSONERO',
            personeroId: localPersonero.id,
            pollingStationCode: localPersonero.pollingStationCode,
            token: 'offline-token-${localPersonero.dni}',
            deviceUuid: deviceUuid,
          );

          apiClient.setAuthToken(session.token);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
          return session;
        }
      }
    }

    if (dioOrServerException != null) {
      if (dioOrServerException is Exception) throw dioOrServerException;
      throw Exception(dioOrServerException.toString());
    }

    throw Exception('Credenciales incorrectas o usuario no registrado. Verifique su correo o DNI.');
  }

  /// Convierte dinámicamente cualquier objeto a Map sin lanzar IndexExceptions
  static Map<String, dynamic> _normalizeToMap(dynamic input) {
    if (input == null) return <String, dynamic>{};
    if (input is Map<String, dynamic>) return input;
    if (input is Map) return Map<String, dynamic>.from(input);
    if (input is String) {
      try {
        final decoded = jsonDecode(input);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return <String, dynamic>{};
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
