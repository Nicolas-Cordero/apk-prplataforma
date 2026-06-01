import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:io';

/// Modelo para carrera
class Carrera {
  final String codigoCarrera;
  final String rutEstudiante;
  final String codigoUniversidad;
  final int duracionSemestres;
  final String nombre;
  final String viaAcceso;

  Carrera({
    required this.codigoCarrera,
    required this.rutEstudiante,
    required this.codigoUniversidad,
    required this.duracionSemestres,
    required this.nombre,
    required this.viaAcceso,
  });

  factory Carrera.fromJson(Map<String, dynamic> json) {
    return Carrera(
      codigoCarrera: (json['codigo_carrera'] as String?) ?? '',
      rutEstudiante: (json['rut_estudiante'] as String?) ?? '',
      codigoUniversidad: (json['codigo_universidad'] as String?) ?? '',
      duracionSemestres: (json['duracion_semestres'] as int?) ?? 0,
      nombre: (json['nombre'] as String?) ?? '',
      viaAcceso: (json['via_acceso'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo_carrera': codigoCarrera,
      'rut_estudiante': rutEstudiante,
      'codigo_universidad': codigoUniversidad,
      'duracion_semestres': duracionSemestres,
      'nombre': nombre,
      'via_acceso': viaAcceso,
    };
  }
}

/// Servicio para gestionar carreras
class CarreraService {
  static const String _assetPath = 'assets/data/carreras.json';
  static const String _tempFileName = 'carreras.json';

  /// Obtiene la carrera del estudiante por su RUT
  static Future<Carrera?> obtenerPorRut(String rutEstudiante) async {
    final carreras = await _obtenerTodas();
    try {
      return carreras.firstWhere(
        (carrera) => carrera.rutEstudiante == rutEstudiante,
      );
    } catch (e) {
      return null;
    }
  }

  /// Obtiene todas las carreras
  static Future<List<Carrera>> _obtenerTodas() async {
    final data = await _leerMapa();
    return (data as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((json) => Carrera.fromJson(json))
        .toList();
  }

  /// Lee el archivo de carreras desde temp o asset
  static Future<dynamic> _leerMapa() async {
    try {
      final tempDir = Directory.systemTemp.path;
      final tempFile = File('$tempDir/test1/$_tempFileName');

      if (await tempFile.exists()) {
        final contenido = await tempFile.readAsString();
        return jsonDecode(contenido);
      }
    } catch (e) {
      // Si falla, intenta desde asset
    }

    // Intenta cargar desde asset
    try {
      final contenido = await rootBundle.loadString(_assetPath);
      return jsonDecode(contenido);
    } catch (e) {
      return [];
    }
  }
}
