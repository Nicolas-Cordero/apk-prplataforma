import 'dart:convert';
import 'dart:io';

class PromedioFinalRegistro {
  final String ramoId;
  final String semestreId;
  final String ramoNombre;
  final int intento;
  final double promedioFinal;

  PromedioFinalRegistro({
    required this.ramoId,
    required this.semestreId,
    required this.ramoNombre,
    required this.intento,
    required this.promedioFinal,
  });

  factory PromedioFinalRegistro.fromJson(Map<String, dynamic> json) {
    return PromedioFinalRegistro(
      ramoId: (json['ramo_id'] ?? '').toString(),
      semestreId: (json['semestre_id'] ?? '').toString(),
      ramoNombre: (json['ramo_nombre'] ?? '').toString(),
      intento: (json['intento'] ?? 1) as int,
      promedioFinal: (json['promedio_final'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ramo_id': ramoId,
      'semestre_id': semestreId,
      'ramo_nombre': ramoNombre,
      'intento': intento,
      'promedio_final': promedioFinal,
    };
  }
}

class PromedioFinalService {
  static File _file() {
    final dir = Directory('${Directory.systemTemp.path}/test1');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return File('${dir.path}/promedios_finales.json');
  }

  static Future<List<PromedioFinalRegistro>> leerPromedios() async {
    final file = _file();
    if (!file.existsSync()) {
      await file.writeAsString(jsonEncode([]));
    }

    try {
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(PromedioFinalRegistro.fromJson)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<void> guardarPromedios(List<PromedioFinalRegistro> promedios) async {
    final file = _file();
    final list = promedios.map((promedio) => promedio.toJson()).toList();
    await file.writeAsString(jsonEncode(list));
  }
}