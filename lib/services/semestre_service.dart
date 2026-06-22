import 'package:carmen_goudie/services/api_service.dart';
import 'package:carmen_goudie/services/ramo_service.dart';

// ── Modelo ────────────────────────────────────────────────────────────────────

class Semestre {
  /// String del semestre_id (int del backend), para compat con mis_notas_page
  /// y PromedioFinalService que comparan IDs como String.
  final String id;
  final String nombre;    // Ej: "2025-1", "2025-2", "2025-Inv"
  final int anio;
  final int numeroSemestre; // 1=PRIMER, 2=SEGUNDO, 3=INVIERNO, 4=VERANO
  final bool esActual;

  const Semestre({
    required this.id,
    required this.nombre,
    required this.anio,
    required this.numeroSemestre,
    required this.esActual,
  });

  factory Semestre.fromJson(Map<String, dynamic> json, {bool esActual = false}) {
    final semestreId = json['semestre_id'] as int;
    final year = json['year'] as int;
    final codigo = json['semestre'] as String;
    return Semestre(
      id: semestreId.toString(),
      nombre: _buildNombre(year, codigo),
      anio: year,
      numeroSemestre: _buildNumero(codigo),
      esActual: esActual,
    );
  }

  Semestre copyWith({bool? esActual}) => Semestre(
        id: id,
        nombre: nombre,
        anio: anio,
        numeroSemestre: numeroSemestre,
        esActual: esActual ?? this.esActual,
      );

  static String _buildNombre(int year, String codigo) {
    switch (codigo) {
      case 'PRIMER_SEMESTRE':  return '$year-1';
      case 'SEGUNDO_SEMESTRE': return '$year-2';
      case 'INVIERNO':         return '$year-Inv';
      case 'VERANO':           return '$year-Ver';
      default:                 return '$year ($codigo)';
    }
  }

  static int _buildNumero(String codigo) {
    switch (codigo) {
      case 'PRIMER_SEMESTRE':  return 1;
      case 'SEGUNDO_SEMESTRE': return 2;
      case 'INVIERNO':         return 3;
      case 'VERANO':           return 4;
      default:                 return 0;
    }
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class SemestreService {
  /// GET /semestre/:id — obtiene un semestre concreto.
  static Future<Semestre> obtenerPorId(int id) async {
    final response = await ApiService.get('/semestre/$id');
    return Semestre.fromJson(response.data as Map<String, dynamic>);
  }

  /// Obtiene en paralelo solo los semestres cuyo id está en [ids].
  /// Devuelve la lista ordenada cronológicamente.
  static Future<List<Semestre>> obtenerPorIds(Set<int> ids) async {
    if (ids.isEmpty) return [];
    final responses = await Future.wait(ids.map(obtenerPorId));
    responses.sort((a, b) {
      final cmp = a.anio.compareTo(b.anio);
      return cmp != 0 ? cmp : a.numeroSemestre.compareTo(b.numeroSemestre);
    });
    return responses;
  }

  /// Devuelve solo los semestres en los que el estudiante tiene ramos.
  /// Reemplaza el GET /semestre global para no traer cientos de semestres.
  static Future<List<Semestre>> obtenerTodosSemestres() async {
    final ramos = await RamoService.obtenerMisRamos();
    final ids = ramos.map((r) => int.parse(r.semestreId)).toSet();
    return obtenerPorIds(ids);
  }

  /// Determina el semestre actual obteniendo primero los ramos, luego los
  /// semestres correspondientes (sin traer semestres innecesarios).
  static Future<Semestre> obtenerSemestreActual() async {
    final ramos = await RamoService.obtenerMisRamos();
    final ids = ramos.map((r) => int.parse(r.semestreId)).toSet();
    final semestres = await obtenerPorIds(ids);
    return _determinarActual(semestres, ramos);
  }

  /// Marca como actual el semestre más reciente con al menos un ramo CURSANDO.
  /// Si ninguno cumple la condición, devuelve el más reciente con esActual=false.
  static Semestre _determinarActual(
      List<Semestre> semestres, List<Ramo> ramos) {
    final abiertoIds = ramos
        .where((r) => r.estado == EstadoRamo.CURSANDO)
        .map((r) => r.semestreId)
        .toSet();

    for (final s in semestres.reversed) {
      if (abiertoIds.contains(s.id)) return s.copyWith(esActual: true);
    }

    return semestres.isNotEmpty
        ? semestres.last.copyWith(esActual: false)
        : Semestre(
            id: '', nombre: 'Sin semestre', anio: 0,
            numeroSemestre: 0, esActual: false,
          );
  }

  /// Aplica esActual a cada semestre de la lista según los ramos existentes.
  static List<Semestre> marcarActual(
      List<Semestre> semestres, List<Ramo> ramos) {
    final actualId = _determinarActual(semestres, ramos).id;
    return semestres
        .map((s) => s.copyWith(esActual: s.id == actualId))
        .toList();
  }
}
