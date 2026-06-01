import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:io';

/// Modelo para universidad
class Universidad {
  final String codigo;
  final String nombre;
  final String comuna;

  Universidad({
    required this.codigo,
    required this.nombre,
    required this.comuna,
  });

  factory Universidad.fromJson(Map<String, dynamic> json) {
    return Universidad(
      codigo: (json['codigo'] as String?) ?? '',
      nombre: (json['nombre'] as String?) ?? '',
      comuna: (json['comuna'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'comuna': comuna,
    };
  }
}

/// Servicio para gestionar universidades
class UniversidadService {
  static const String _assetPath = 'assets/data/universidades.json';
  static const String _tempFileName = 'universidades.json';

  /// Obtiene una universidad por su código
  static Future<Universidad?> obtenerPorCodigo(String codigo) async {
    final universidades = await _obtenerTodas();
    try {
      return universidades.firstWhere(
        (universidad) => universidad.codigo == codigo,
      );
    } catch (e) {
      return null;
    }
  }

  /// Obtiene todas las universidades
  static Future<List<Universidad>> _obtenerTodas() async {
    final data = await _leerMapa();
    return (data as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((json) => Universidad.fromJson(json))
        .toList();
  }

  /// Lee el archivo de universidades desde temp o asset
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
