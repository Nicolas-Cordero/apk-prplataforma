import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:test1/models/usuario.dart';

/// Servicio de acceso a datos de usuarios
/// 
/// Gestiona autenticación y datos de usuarios.
/// Capa de abstracción entre la app y la fuente de datos (JSON → API).
class UsuarioService {
  static const String _usuariosPath = 'assets/data/usuarios.json';

  /// Carga un archivo JSON desde assets (maneja Map o List)
  static Future<dynamic> _cargarJson(String path) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      return jsonDecode(jsonString);
    } catch (e) {
      throw Exception('Error al cargar $path: $e');
    }
  }

  /// Autentica un usuario con RUT y contraseña
  /// En producción: POST /api/auth/login con {rut, contrasena}
  /// Retorna token JWT para guardar en SharedPreferences
  static Future<Usuario> autenticar(String rut, String contrasena) async {
    final jsonData = await _cargarJson(_usuariosPath);
    List<Map<String, dynamic>> usuarios = [];

    if (jsonData is List) {
      usuarios = jsonData.whereType<Map<String, dynamic>>().toList();
    } else if (jsonData is Map<String, dynamic>) {
      usuarios = [jsonData];
    }

    final usuario = usuarios.firstWhere(
      (u) => u['rut'] == rut,
      orElse: () => throw Exception('RUT o contraseña incorrectos'),
    );

    final usuarioObj = Usuario.fromJson(usuario);
    if (usuarioObj.contrasena != contrasena) {
      throw Exception('RUT o contraseña incorrectos');
    }

    // En producción: guardar token en SharedPreferences
    // await _guardarToken(token);

    return usuarioObj;
  }

  /// Obtiene el usuario actual (requiere sesión activa)
  /// Retorna el primer usuario de la lista
  /// En producción: GET /api/usuarios/me con header Authorization
  static Future<Usuario> obtenerActual() async {
    final jsonData = await _cargarJson(_usuariosPath);
    if (jsonData is List && jsonData.isNotEmpty) {
      return Usuario.fromJson(jsonData[0] as Map<String, dynamic>);
    }
    if (jsonData is Map<String, dynamic>) {
      return Usuario.fromJson(jsonData);
    }
    throw Exception('Formato de usuarios inválido');
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
