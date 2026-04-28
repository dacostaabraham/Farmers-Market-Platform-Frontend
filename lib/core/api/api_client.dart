import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

// Callback appelé quand un 401 est détecté → permet au AuthNotifier de se déconnecter
typedef OnUnauthorized = Future<void> Function();

class ApiClient {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  OnUnauthorized? onUnauthorized;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // Token expiré ou invalide → déconnexion automatique
        if (e.response?.statusCode == 401) {
          await _storage.delete(key: AppConstants.tokenKey);
          await _storage.delete(key: AppConstants.userKey);
          onUnauthorized?.call();
        }
        return handler.next(e);
      },
    ));
  }

  // ── Generic request helpers ─────────────────────────────────────────
  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) async {
    return await _dio.get(path, queryParameters: queryParams);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await _dio.patch(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }
}
