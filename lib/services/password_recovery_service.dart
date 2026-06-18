import 'package:carmen_goudie/services/api_service.dart';

class PasswordRecoveryService {
  /// POST /auth/forgot-password
  /// El backend siempre responde OK (no revela si el email existe).
  static Future<void> solicitarCodigo(String email) async {
    await ApiService.post('/auth/forgot-password', data: {'email': email});
  }

  /// POST /auth/verify-reset-code
  /// Devuelve true si el código de 6 dígitos es válido y no ha expirado.
  static Future<bool> verificarCodigo(String email, String code) async {
    final response = await ApiService.post(
      '/auth/verify-reset-code',
      data: {'email': email, 'code': code},
    );
    return response.data['valid'] as bool? ?? false;
  }

  /// POST /auth/reset-password
  /// Cambia la contraseña usando el código verificado previamente.
  static Future<void> cambiarContrasena({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await ApiService.post('/auth/reset-password', data: {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
  }
}
