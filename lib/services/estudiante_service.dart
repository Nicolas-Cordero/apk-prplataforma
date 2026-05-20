import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:test1/models/estudiante.dart';

/// Servicio de acceso a datos de estudiantes
/// 
/// Capa de abstracción entre la app y la fuente de datos (JSON → API).
/// Todos los cambios de backend se hacen SOLO aquí, sin tocar widgets.
class EstudianteService {
  static const String _estudiantesPath = 'assets/data/students_becarios.json';

  /// Carga un archivo JSON desde assets (maneja Map o List)
  static Future<dynamic> _cargarJson(String path) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      return jsonDecode(jsonString);
    } catch (e) {
      throw Exception('Error al cargar $path: $e');
    }
  }

  /// Obtiene el estudiante actual (del usuario en sesión)
  /// Retorna el primer estudiante de la lista
  /// En producción: GET /api/estudiantes/me
  static Future<Estudiante> obtenerEstudianteActual() async {
    final jsonData = await _cargarJson(_estudiantesPath);
    if (jsonData is List && jsonData.isNotEmpty) {
      return Estudiante.fromJson(jsonData[0] as Map<String, dynamic>);
    }
    if (jsonData is Map<String, dynamic>) {
      return Estudiante.fromJson(jsonData);
    }
    throw Exception('Formato de estudiantes inválido');
  }

  /// Obtiene todos los estudiantes
  /// En producción: GET /api/estudiantes
  static Future<List<Estudiante>> obtenerTodos() async {
    final jsonData = await _cargarJson(_estudiantesPath);
    if (jsonData is List) {
      return jsonData
          .whereType<Map<String, dynamic>>()
          .map(Estudiante.fromJson)
          .toList();
    }
    if (jsonData is Map<String, dynamic>) {
      return [Estudiante.fromJson(jsonData)];
    }
    return [];
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


