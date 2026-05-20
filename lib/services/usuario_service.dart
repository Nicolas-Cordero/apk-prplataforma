import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:test1/models/usuario.dart';

/// Servicio de acceso a datos de usuarios
/// 
/// Gestiona autenticación y datos de usuarios.
/// Capa de abstracción entre la app y la fuente de datos (JSON → API).
class UsuarioService {
  static const String _usuariosPath = 'assets/data/usuarios.json';

  /// Carga un archivo JSON desde assets
  static Future<Map<String, dynamic>> _cargarJson(String path) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error al cargar $path: $e');
    }
  }

  /// Autentica un usuario con RUT y contraseña
  /// En producción: POST /api/auth/login con {rut, contrasena}
  /// Retorna token JWT para guardar en SharedPreferences
  static Future<Usuario> autenticar(String rut, String contrasena) async {
    final jsonData = await _cargarJson(_usuariosPath);
    final usuario = Usuario.fromJson(jsonData);

    if (usuario.rut != rut) {
      throw Exception('RUT o contraseña incorrectos');
    }

    // En producción: guardar token en SharedPreferences
    // await _guardarToken(token);

    return usuario;
  }

  /// Obtiene el usuario actual (requiere sesión activa)
  /// En producción: GET /api/usuarios/me con header Authorization
  static Future<Usuario> obtenerActual() async {
    final jsonData = await _cargarJson(_usuariosPath);
    return Usuario.fromJson(jsonData);
  }

  /// Actualiza perfil del usuario
  /// En producción: PUT /api/usuarios con body: usuario.toJson()
  static Future<void> actualizarPerfil(Usuario usuario) async {
    // await http.put('/api/usuarios',
    //   body: jsonEncode(usuario.toJson()),
    // );
  }

  /// Cierra la sesión del usuario
  /// En producción: POST /api/auth/logout + limpiar SharedPreferences
  static Future<void> cerrarSesion() async {
    // await http.post('/api/auth/logout');
    // await _eliminarToken();
  }
}
