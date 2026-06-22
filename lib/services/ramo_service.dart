import 'package:carmen_goudie/services/api_service.dart';

// ── Enum ─────────────────────────────────────────────────────────────────────

// ignore_for_file: constant_identifier_names
enum EstadoRamo { APROBADO, REPROBADO, CURSANDO, ELIMINADO }

extension EstadoRamoX on EstadoRamo {
  String get etiqueta {
    switch (this) {
      case EstadoRamo.APROBADO:  return 'Aprobado';
      case EstadoRamo.REPROBADO: return 'Reprobado';
      case EstadoRamo.CURSANDO:  return 'Cursando';
      case EstadoRamo.ELIMINADO: return 'Eliminado';
    }
  }
}

// ── Modelo ────────────────────────────────────────────────────────────────────

class Ramo {
  /// id y semestreId se guardan como String para compatibilidad con
  /// mis_notas_page y PromedioFinalService (que los comparan como String).
  final String id;
  final String semestreId;
  final String rutEstudiante;
  final int codigoCarrera;
  final String nombre;
  final EstadoRamo estado;
  final String comentario;
  final int intento;
  final double? notaFinal;
  /// Local únicamente: no viene del backend ni se envía en ningún DTO.
  final bool puedoAyudar;

  const Ramo({
    required this.id,
    required this.semestreId,
    required this.rutEstudiante,
    required this.codigoCarrera,
    required this.nombre,
    required this.estado,
    required this.comentario,
    required this.intento,
    this.notaFinal,
    this.puedoAyudar = false,
  });

  factory Ramo.fromJson(Map<String, dynamic> json) => Ramo(
        id: (json['id'] as int).toString(),
        semestreId: (json['semestre_id'] as int).toString(),
        rutEstudiante: json['rut_estudiante'] as String? ?? '',
        codigoCarrera: json['codigo_carrera'] as int? ?? 0,
        nombre: json['nombre'] as String? ?? '',
        estado: _parseEstado(json['estado'] as String? ?? 'CURSANDO'),
        comentario: json['comentario'] as String? ?? '',
        intento: json['intento'] as int? ?? 1,
        notaFinal: json['nota_final'] != null
            ? (json['nota_final'] as num).toDouble()
            : null,
      );

  Ramo copyWith({
    String? nombre,
    EstadoRamo? estado,
    bool? puedoAyudar,
  }) =>
      Ramo(
        id: id,
        semestreId: semestreId,
        rutEstudiante: rutEstudiante,
        codigoCarrera: codigoCarrera,
        nombre: nombre ?? this.nombre,
        estado: estado ?? this.estado,
        comentario: comentario,
        intento: intento,
        notaFinal: notaFinal,
        puedoAyudar: puedoAyudar ?? this.puedoAyudar,
      );

  static EstadoRamo _parseEstado(String s) {
    switch (s) {
      case 'APROBADO':  return EstadoRamo.APROBADO;
      case 'REPROBADO': return EstadoRamo.REPROBADO;
      case 'ELIMINADO': return EstadoRamo.ELIMINADO;
      default:          return EstadoRamo.CURSANDO;
    }
  }
}

// ── DTOs ─────────────────────────────────────────────────────────────────────

class CreateRamoDto {
  final int semestreId;
  final int codigoCarrera;
  final String nombre;

  const CreateRamoDto({
    required this.semestreId,
    required this.codigoCarrera,
    required this.nombre,
  });

  Map<String, dynamic> toJson() => {
        'semestre_id':    semestreId,
        'codigo_carrera': codigoCarrera,
        'nombre':         nombre,
        'estado':         'CURSANDO',
      };
}

class UpdateRamoDto {
  final String? nombre;
  final EstadoRamo? estado;

  const UpdateRamoDto({this.nombre, this.estado});

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    if (nombre != null) m['nombre'] = nombre;
    if (estado != null) m['estado'] = estado!.name;
    return m;
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class RamoService {
  /// GET /ramo/me — devuelve todos los ramos del estudiante autenticado.
  static Future<List<Ramo>> obtenerMisRamos() async {
    final response = await ApiService.get('/ramo/me');
    return (response.data as List<dynamic>)
        .map((e) => Ramo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Alias para backward-compat con mis_notas_page que llama leerRamos().
  static Future<List<Ramo>> leerRamos() => obtenerMisRamos();

  /// POST /ramo/me — crea un ramo en el semestre actual del estudiante.
  /// El rut_estudiante lo inyecta el backend desde el JWT.
  static Future<Ramo> crearRamo(CreateRamoDto dto) async {
    final response = await ApiService.post('/ramo/me', data: dto.toJson());
    return Ramo.fromJson(response.data as Map<String, dynamic>);
  }

  /// PATCH /ramo/me/:id_ramo — actualiza nombre o estado de un ramo propio.
  static Future<Ramo> actualizarRamo(int idRamo, UpdateRamoDto dto) async {
    final response =
        await ApiService.patch('/ramo/me/$idRamo', data: dto.toJson());
    return Ramo.fromJson(response.data as Map<String, dynamic>);
  }
}
