import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

class Ramo {
  final String id;
  final String nombre;
  final int intento;
  final String rutEstudiante;
  final String semestreId;

  Ramo({
    required this.id,
    required this.nombre,
    required this.intento,
    this.rutEstudiante = '',
    this.semestreId = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'intento': intento,
        'rut_estudiante': rutEstudiante,
        'semestre_id': semestreId,
      };

  static Ramo fromJson(Map<String, dynamic> m) => Ramo(
        id: (m['id'] ?? '').toString(),
        nombre: (m['nombre'] ?? '').toString(),
        intento: (m['intento'] ?? 1) as int,
        rutEstudiante: (m['rut_estudiante'] ?? '').toString(),
        semestreId: (m['semestre_id'] ?? '').toString(),
      );
}

class RamoService {
  static File _file() {
    final dir = Directory('${Directory.systemTemp.path}/test1');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return File('${dir.path}/ramos.json');
  }

  static Future<List<Ramo>> leerRamos() async {
    final f = _file();
    if (!f.existsSync()) {
      // try to initialize from assets
      try {
        final data = await rootBundle.loadString('assets/data/ramos.json');
        await f.writeAsString(data);
      } catch (_) {
        await f.writeAsString(jsonEncode([]));
      }
    }

    try {
      final content = await f.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded.map<Ramo>((e) => Ramo.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<void> guardarRamos(List<Ramo> ramos) async {
    final f = _file();
    final list = ramos.map((r) => r.toJson()).toList();
    await f.writeAsString(jsonEncode(list));
  }
}
