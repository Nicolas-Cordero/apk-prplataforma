import 'dart:convert';
import 'package:flutter/services.dart';

/// Modelo que representa un liceo
class Liceo {
  final String rbdLiceo;
  final String nombre;
  final String comuna;
  final String especialidad;

  Liceo({
    required this.rbdLiceo,
    required this.nombre,
    required this.comuna,
    required this.especialidad,
  });

  factory Liceo.fromJson(Map<String, dynamic> json) {
    return Liceo(
      rbdLiceo: json['rbd_liceo'] as String,
      nombre: json['nombre'] as String,
      comuna: json['comuna'] as String,
      especialidad: json['especialidad'] as String,
    );
  }
}

/// Servicio de acceso a datos de liceos
/// Carga información de liceos desde assets (JSON) o API en producción
class LiceoService {
  static const String _liceoPath = 'assets/data/liceos.json';
  static Liceo? _liceoCache;

  /// Carga el liceo (con caché)
  static Future<Liceo> _cargarLiceo() async {
    if (_liceoCache != null) return _liceoCache!;

    try {
      final jsonString = await rootBundle.loadString(_liceoPath);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      _liceoCache = Liceo.fromJson(jsonData);
      return _liceoCache!;
    } catch (e) {
      throw Exception('Error al cargar liceo: $e');
    }
  }

  /// Obtiene el liceo actual
  static Future<Liceo> obtener() async {
    return _cargarLiceo();
  }

  /// Obtiene el liceo por su RBD (si coincide)
  static Future<Liceo?> obtenerPorRbd(String rbd) async {
    final liceo = await _cargarLiceo();
    if (liceo.rbdLiceo == rbd) {
      return liceo;
    }
    return null;
  }
}
