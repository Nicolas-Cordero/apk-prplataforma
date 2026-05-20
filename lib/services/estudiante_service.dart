import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:test1/models/estudiante.dart';

/// Servicio de acceso a datos de estudiantes
/// 
/// Capa de abstracción entre la app y la fuente de datos (JSON → API).
/// Todos los cambios de backend se hacen SOLO aquí, sin tocar widgets.
class EstudianteService {
  static const String _estudiantesPath = 'assets/data/students.json';

  /// Carga un archivo JSON desde assets
  static Future<Map<String, dynamic>> _cargarJson(String path) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error al cargar $path: $e');
    }
  }

  /// Obtiene el estudiante actual (del usuario en sesión)
  /// En producción: GET /api/estudiantes/me
  static Future<Estudiante> obtenerEstudianteActual() async {
    final jsonData = await _cargarJson(_estudiantesPath);
    return Estudiante.fromJson(jsonData);
  }

  /// Obtiene todos los estudiantes
  /// En producción: GET /api/estudiantes
  static Future<List<Estudiante>> obtenerTodos() async {
    final jsonData = await _cargarJson(_estudiantesPath);
    return [Estudiante.fromJson(jsonData)];
  }

  /// Actualiza datos del estudiante
  /// En producción: PUT /api/estudiantes/{rut}
  static Future<void> actualizar(Estudiante estudiante) async {
    // await http.put('/api/estudiantes/${estudiante.rutEstudiante}',
    //   body: jsonEncode(estudiante.toJson()),
    // );
  }

  /// Crea un nuevo estudiante
  /// En producción: POST /api/estudiantes
  static Future<Estudiante> crear(Estudiante estudiante) async {
    // await http.post('/api/estudiantes',
    //   body: jsonEncode(estudiante.toJson()),
    // );
    return estudiante;
  }

  /// Elimina un estudiante por RUT
  /// En producción: DELETE /api/estudiantes/{rut}
  static Future<void> eliminar(String rut) async {
    // await http.delete('/api/estudiantes/$rut');
  }
}


