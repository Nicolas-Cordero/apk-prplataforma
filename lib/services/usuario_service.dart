import 'package:carmen_goudie/models/usuario.dart';
import 'package:carmen_goudie/services/api_service.dart';

class UsuarioService {
  /// POST /auth/login
  static Future<Usuario> autenticar(String email, String password) async {
    final response = await ApiService.post('/auth/login', data: {
      'email': email,
      'password': password,
      'client': 'mobile',
    });

    final data = response.data as Map<String, dynamic>;

    await ApiService.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );

    print("hola");
    return Usuario.fromJson(data);
  }

  /// GET /auth/me
  static Future<Usuario> obtenerActual() async {
    final response = await ApiService.get('/auth/me');
    return Usuario.fromJson(response.data as Map<String, dynamic>);
  }

  /// PATCH /users/{rut}/password/change
  /// Usado cuando must_change_password == true al primer ingreso.
  static Future<void> cambiarPrimeraContrasena({
    required String rut,
    required String currentPassword,
    required String newPassword,
  }) async {
    await ApiService.patch(
      '/users/$rut/password/change',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  /// POST /auth/logout
  static Future<void> cerrarSesion() async {
    try {
      final refreshToken = await ApiService.getRefreshToken();
      await ApiService.post('/auth/logout', data: {'refreshToken': refreshToken});
    } catch (_) {
    } finally {
      await ApiService.clearTokens();
    }
  }
}
