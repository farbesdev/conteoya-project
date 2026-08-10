import 'dart:io';
import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio;
  String? _authToken;

  ApiClient({String? baseUrl, Dio? customDio})
      : _dio = customDio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? 'http://10.0.2.2:8000/api/v1',
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
      ),
    );
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
    return Dio().put<void>(
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
