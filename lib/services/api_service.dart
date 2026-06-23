import 'dart:async';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.100.13:3001',
  );

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  static bool _interceptorMounted = false;

  // Mutex para serializar refreshes concurrentes: solo uno corre a la vez,
  // los demás esperan su resultado en lugar de disparar otro POST /auth/refresh.
  static bool _isRefreshing = false;
  static Completer<bool>? _refreshCompleter;

  /// Llama a este método una vez al arrancar la app (en main.dart).
  static void init() {
    if (_interceptorMounted) return;
    _interceptorMounted = true;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Si el servidor devuelve 401 intentamos renovar el token.
          if (error.response?.statusCode == 401) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              // Reintentar la request original con el nuevo token.
              final opts = error.requestOptions;
              final token = await getAccessToken();
              opts.headers['Authorization'] = 'Bearer $token';
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  // ── Tokens ────────────────────────────────────────────────────────────────

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
  }

  static Future<bool> hasSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Intenta renovar el access token usando el refresh token guardado.
  /// Devuelve true si lo logró, false si hay que ir al login.
  ///
  /// Si hay un refresh en curso, espera su resultado en lugar de lanzar
  /// otro POST /auth/refresh (evita race condition con token rotation).
  static Future<bool> _tryRefresh() async {
    if (_isRefreshing) {
      return _refreshCompleter!.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_keyRefreshToken);
      if (refreshToken == null) {
        _refreshCompleter!.complete(false);
        return false;
      }

      // Usamos una instancia limpia para evitar que el interceptor
      // vuelva a dispararse en este request de refresh.
      final plainDio = Dio(BaseOptions(baseUrl: _baseUrl));
      final response = await plainDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final newAccess = response.data['accessToken'] as String?;
      final newRefresh = response.data['refreshToken'] as String?;
      if (newAccess == null || newRefresh == null) {
        _refreshCompleter!.complete(false);
        return false;
      }

      await saveTokens(accessToken: newAccess, refreshToken: newRefresh);
      _refreshCompleter!.complete(true);
      return true;
    } catch (_) {
      await clearTokens();
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  // ── Métodos HTTP ──────────────────────────────────────────────────────────

  static Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  static Future<Response> post(String path, {Object? data}) {
    return _dio.post(path, data: data);
  }

  static Future<Response> patch(String path, {Object? data}) {
    return _dio.patch(path, data: data);
  }

  static Future<Response> delete(String path) {
    return _dio.delete(path);
  }
}
