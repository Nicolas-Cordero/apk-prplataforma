import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';

  // Inicializado en init() tras leer env.json.
  static late String _baseUrl;
  static late Dio _dio;

  static bool _interceptorMounted = false;

  // Mutex para serializar refreshes concurrentes.
  static bool _isRefreshing = false;
  static Completer<bool>? _refreshCompleter;

  /// Lee la URL base desde el asset `env.json` y monta el cliente HTTP.
  /// Debe ser llamado con `await` en main() antes de runApp().
  /// Copia `env.example.json` → `env.json` y completa la URL antes de correr.
  static Future<void> init() async {
    if (_interceptorMounted) return;

    // Leer env.json en runtime — funciona sin flags extra en flutter run.
    String baseUrl = '';
    try {
      final raw = await rootBundle.loadString('env.json');
      final env = jsonDecode(raw) as Map<String, dynamic>;
      baseUrl = env['API_BASE_URL'] as String? ?? '';
    } catch (_) {
      // env.json no encontrado — el assert de abajo lo reporta en debug.
    }

    assert(
      baseUrl.isNotEmpty,
      '\n\n⚠️  API_BASE_URL no definida.\n'
      'Copia env.example.json → env.json y completa la URL del backend.\n',
    );

    _baseUrl = baseUrl;
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

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
          if (error.response?.statusCode == 401) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
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
