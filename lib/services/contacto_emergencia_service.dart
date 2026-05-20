import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

/// Modelo para contacto de emergencia
class ContactoEmergencia {
  final String rutEstudiante;
  final String telefono;
  final String correo;

  ContactoEmergencia({
    required this.rutEstudiante,
    required this.telefono,
    required this.correo,
  });

  factory ContactoEmergencia.fromJson(
    String rutEstudiante,
    Map<String, dynamic> json,
  ) {
    return ContactoEmergencia(
      rutEstudiante: rutEstudiante,
      telefono: (json['telefono'] as String?) ?? '',
      correo: (json['correo'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'telefono': telefono,
      'correo': correo,
    };
  }
}

/// Servicio para gestionar contactos de emergencia
/// Guarda y lee desde un JSON local. En producción será una API.
class ContactoEmergenciaService {
  static const String _assetPath = 'assets/data/datos_contacto.json';
  static const String _fileName = 'datos_contacto.json';

  static Future<File> _localFile() async {
    final dir = Directory('${Directory.systemTemp.path}/test1');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File('${dir.path}/$_fileName');
  }

  static Future<Map<String, dynamic>> _leerMapa() async {
    final file = await _localFile();

    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.trim().isEmpty) return {};
      return jsonDecode(content) as Map<String, dynamic>;
    }

    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(jsonData));
      return jsonData;
    } catch (_) {
      await file.writeAsString('{}');
      return {};
    }
  }

  static Future<void> _guardarMapa(Map<String, dynamic> data) async {
    final file = await _localFile();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }

  /// Obtiene contacto por RUT del estudiante
  static Future<ContactoEmergencia?> obtenerPorRut(String rutEstudiante) async {
    final data = await _leerMapa();
    final entry = data[rutEstudiante];
    if (entry is Map<String, dynamic>) {
      return ContactoEmergencia.fromJson(rutEstudiante, entry);
    }
    if (entry is Map) {
      return ContactoEmergencia.fromJson(
        rutEstudiante,
        entry.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return null;
  }

  /// Guarda o actualiza contacto por RUT
  static Future<void> guardar({
    required String rutEstudiante,
    required String telefono,
    required String correo,
  }) async {
    final data = await _leerMapa();
    final telefonoFinal = telefono.trim();
    final correoFinal = correo.trim();

    if (telefonoFinal.isEmpty && correoFinal.isEmpty) {
      data.remove(rutEstudiante);
    } else {
      data[rutEstudiante] = {
        'telefono': telefonoFinal,
        'correo': correoFinal,
      };
    }

    await _guardarMapa(data);
  }
}
