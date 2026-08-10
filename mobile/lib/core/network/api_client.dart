import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static const String defaultProductionUrl = 'https://app.unifact.net.pe/api/v1';

  final Dio _dio;
  String? _authToken;

  ApiClient({String? baseUrl, Dio? customDio})
      : _dio = customDio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? defaultProductionUrl,
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 20),
                headers: {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            ) {
    if (!kIsWeb) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          // Permitir certificados válidos o autofirmados para el VPS de ConteoYA
          client.badCertificateCallback = (X509Certificate cert, String host, int port) {
            return true;
          };
          return client;
        },
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
      ),
    );
  }

  String get baseUrl => _dio.options.baseUrl;

  void setBaseUrl(String url) {
    var formatted = url.trim();
    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'https://$formatted';
    }
    if (!formatted.endsWith('/api/v1')) {
      if (formatted.endsWith('/')) {
        formatted = '${formatted}api/v1';
      } else {
        formatted = '$formatted/api/v1';
      }
    }
    _dio.options.baseUrl = formatted;
  }

  void setAuthToken(String token) {
    _authToken = token;
  }

  Future<Response<T>> get<T>(String path, {Map<String, Object?>? queryParameters}) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    String? idempotencyKey,
  }) {
    final options = Options();
    if (idempotencyKey != null) {
      options.headers = {'Idempotency-Key': idempotencyKey};
    }
    return _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  /// Sube un archivo binario a una URL presignada (Cloudflare R2) vía HTTP PUT
  Future<Response<void>> uploadToPresignedUrl({
    required String presignedUrl,
    required File file,
    required String fileMime,
    required String sha256Hash,
  }) async {
    final bytes = await file.readAsBytes();
    final uploadDio = Dio();
    if (!kIsWeb) {
      uploadDio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );
    }
    return uploadDio.put<void>(
      presignedUrl,
      data: bytes,
      options: Options(
        headers: {
          'Content-Type': fileMime,
          'Content-Length': bytes.length,
          'X-Amz-Content-Sha256': sha256Hash,
        },
      ),
    );
  }
}
