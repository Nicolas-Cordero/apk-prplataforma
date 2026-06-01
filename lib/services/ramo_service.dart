import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

class Ramo {
  final String id;
  final String nombre;
  final int intento;
  final String rutEstudiante;
  final String semestreId;
  final bool puedoAyudar;

  Ramo({
    required this.id,
    required this.nombre,
    required this.intento,
    this.rutEstudiante = '',
    this.semestreId = '',
    this.puedoAyudar = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'intento': intento,
        'rut_estudiante': rutEstudiante,
        'semestre_id': semestreId,
        'puedo_ayudar': puedoAyudar,
      };

  static Ramo fromJson(Map<String, dynamic> m) => Ramo(
        id: (m['id'] ?? '').toString(),
        nombre: (m['nombre'] ?? '').toString(),
        intento: (m['intento'] ?? 1) as int,
        rutEstudiante: (m['rut_estudiante'] ?? '').toString(),
        semestreId: (m['semestre_id'] ?? '').toString(),
        puedoAyudar: (m['puedo_ayudar'] ?? false) as bool,
      );
}

class RamoService {
  static const String _seedPath = 'assets/data/ramos.json';

  static File _file() {
    final dir = Directory('${Directory.systemTemp.path}/test1');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return File('${dir.path}/ramos.json');
  }

  static Future<List<Ramo>> _cargarSeed() async {
    try {
      final data = await rootBundle.loadString(_seedPath);
      final decoded = jsonDecode(data);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(Ramo.fromJson)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Ramo>> leerRamos() async {
    final f = _file();
    if (!f.existsSync()) {
      final seed = await _cargarSeed();
      await f.writeAsString(jsonEncode(seed.map((r) => r.toJson()).toList()));
    }

    try {
      final content = await f.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is List) {
        final ramos = decoded
            .whereType<Map<String, dynamic>>()
            .map(Ramo.fromJson)
            .toList();
        final seed = await _cargarSeed();
        final existentes = {for (final ramo in ramos) ramo.id: ramo};
        for (final ramo in seed) {
          existentes.putIfAbsent(ramo.id, () => ramo);
        }
        final merged = existentes.values.toList();
        if (merged.length != ramos.length) {
          await f.writeAsString(jsonEncode(merged.map((r) => r.toJson()).toList()));
        }
        return merged;
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Ramo>> leerRamosPorRut(String rutEstudiante) async {
    final ramos = await leerRamos();
    return ramos.where((ramo) => ramo.rutEstudiante == rutEstudiante).toList();
  }

  static Future<List<Ramo>> leerRamosPuedoAyudar() async {
    final ramos = await leerRamos();
    return ramos.where((ramo) => ramo.puedoAyudar).toList();
  }

  static Future<List<Ramo>> leerRamosPuedoAyudarPorRut(String rutEstudiante) async {
    final ramos = await leerRamos();
    return ramos
        .where((ramo) => ramo.rutEstudiante == rutEstudiante && ramo.puedoAyudar)
        .toList();
  }

  static Future<void> actualizarPuedoAyudar(String ramoId, bool value) async {
    final ramos = await leerRamos();
    final actualizados = ramos
        .map(
          (ramo) => ramo.id == ramoId
              ? Ramo(
                  id: ramo.id,
                  nombre: ramo.nombre,
                  intento: ramo.intento,
                  rutEstudiante: ramo.rutEstudiante,
                  semestreId: ramo.semestreId,
                  puedoAyudar: value,
                )
              : ramo,
        )
        .toList();
    await guardarRamos(actualizados);
  }

  static Future<void> guardarRamos(List<Ramo> ramos) async {
    final f = _file();
    final list = ramos.map((r) => r.toJson()).toList();
    await f.writeAsString(jsonEncode(list));
  }
}
