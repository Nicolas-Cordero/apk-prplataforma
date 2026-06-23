import 'package:carmen_goudie/services/api_service.dart';
import 'package:carmen_goudie/services/ramo_service.dart';

// ── Modelo ────────────────────────────────────────────────────────────────────

class Semestre {
  /// String del semestre_id (int del backend), para compat con mis_notas_page.
  final String id;
  final String nombre;    // Ej: "2025-1", "2025-2", "2025-Inv"
  final int anio;
  final int numeroSemestre; // 1=PRIMER, 2=SEGUNDO, 3=INVIERNO, 4=VERANO
  final bool esActual;
  final bool esRecuperativo;

  const Semestre({
    required this.id,
    required this.nombre,
    required this.anio,
    required this.numeroSemestre,
    required this.esActual,
    this.esRecuperativo = false,
  });

  factory Semestre.fromJson(Map<String, dynamic> json, {bool esActual = false}) {
    final semestreId = json['semestre_id'] as int;
    final year = json['year'] as int;
    final codigo = json['semestre'] as String;
    final tipo = json['tipo'] as String? ?? 'REGULAR';
    return Semestre(
      id: semestreId.toString(),
      nombre: _buildNombre(year, codigo),
      anio: year,
      numeroSemestre: _buildNumero(codigo),
      esActual: esActual,
      esRecuperativo: tipo == 'RECUPERATIVO',
    );
  }

  Semestre copyWith({bool? esActual}) => Semestre(
        id: id,
        nombre: nombre,
        anio: anio,
        numeroSemestre: numeroSemestre,
        esActual: esActual ?? this.esActual,
        esRecuperativo: esRecuperativo,
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
  /// Devuelve null si no hay ningún semestre abierto.
  static Future<Semestre?> obtenerSemestreActual() async {
    final ramos = await RamoService.obtenerMisRamos();
    final ids = ramos.map((r) => int.parse(r.semestreId)).toSet();
    final semestres = await obtenerPorIds(ids);
    return _determinarActual(semestres, ramos);
  }

  /// Devuelve semestres vinculados a una carrera vía la tabla pivot
  /// (incluye semestres vacíos creados por el admin).
  static Future<List<Semestre>> obtenerPorCarrera(int codigoCarrera) async {
    final response =
        await ApiService.get('/semestre/by-carrera/$codigoCarrera');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => Semestre.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Devuelve el semestre "abierto" siguiendo este orden de prioridad:
  /// 1. El semestre más reciente con al menos un ramo CURSANDO.
  /// 2. Si ninguno tiene CURSANDO, el semestre más reciente sin ningún ramo
  ///    (semestre vacío creado por el admin para el estudiante).
  /// 3. null si todos los semestres están cerrados.
  static Semestre? _determinarActual(
      List<Semestre> semestres, List<Ramo> ramos) {
    final cursandoIds = ramos
        .where((r) => r.estado == EstadoRamo.CURSANDO)
        .map((r) => r.semestreId)
        .toSet();

    for (final s in semestres.reversed) {
      if (cursandoIds.contains(s.id)) return s.copyWith(esActual: true);
    }

    // Semestre vacío (sin ningún ramo): el admin lo creó para que el
    // estudiante empiece a agregar ramos.
    final conRamosIds = ramos.map((r) => r.semestreId).toSet();
    for (final s in semestres.reversed) {
      if (!conRamosIds.contains(s.id)) return s.copyWith(esActual: true);
    }

    return null;
  }

  /// Aplica esActual a cada semestre de la lista según los ramos existentes.
  /// Si ningún semestre tiene ramos CURSANDO, todos quedan con esActual=false.
  static List<Semestre> marcarActual(
      List<Semestre> semestres, List<Ramo> ramos) {
    final actual = _determinarActual(semestres, ramos);
    if (actual == null) {
      return semestres.map((s) => s.copyWith(esActual: false)).toList();
    }
    return semestres
        .map((s) => s.copyWith(esActual: s.id == actual.id))
        .toList();
  }
}
