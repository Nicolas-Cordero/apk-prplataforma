import 'package:carmen_goudie/services/api_service.dart';

// ── Modelos ───────────────────────────────────────────────────────────────────

class Topico {
  final String? nombre;
  final List<String> puntos;

  const Topico({this.nombre, required this.puntos});

  factory Topico.fromJson(Map<String, dynamic> json) => Topico(
        nombre: json['nombre'] as String?,
        puntos: (json['puntos'] as List<dynamic>? ?? [])
            .map((p) => p as String)
            .toList(),
      );
}

class DocumentoCompromiso {
  final String titulo;
  final String subtitulo;
  final String abstract;
  final List<Topico> topicos;

  const DocumentoCompromiso({
    required this.titulo,
    required this.subtitulo,
    required this.abstract,
    required this.topicos,
  });

  factory DocumentoCompromiso.fromJson(Map<String, dynamic> json) =>
      DocumentoCompromiso(
        titulo:    json['titulo']    as String? ?? '',
        subtitulo: json['subtitulo'] as String? ?? '',
        abstract:  json['abstract']  as String? ?? '',
        topicos: (json['topicos'] as List<dynamic>? ?? [])
            .map((t) => Topico.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}

class AcuerdoVigente {
  final int id;
  final DateTime createdAt;
  final DocumentoCompromiso documento;

  const AcuerdoVigente({
    required this.id,
    required this.createdAt,
    required this.documento,
  });

  factory AcuerdoVigente.fromJson(Map<String, dynamic> json) => AcuerdoVigente(
        id: json['id'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        documento: DocumentoCompromiso.fromJson(
          json['documento'] as Map<String, dynamic>,
        ),
      );
}

/// Respuesta de GET /acuerdo/me/estado y POST /acuerdo/firmar.
/// Si no existe ningún acuerdo vigente, [hayAcuerdoVigente] es false y
/// los demás campos son nulos/false — el endpoint nunca lanza error por
/// estudiante sin firma previa.
class EstadoFirmaAcuerdo {
  final bool hayAcuerdoVigente;
  final int? acuerdoId;
  final bool firmado;
  final DateTime? firmadoAt;

  const EstadoFirmaAcuerdo({
    required this.hayAcuerdoVigente,
    required this.acuerdoId,
    required this.firmado,
    required this.firmadoAt,
  });

  factory EstadoFirmaAcuerdo.fromJson(Map<String, dynamic> json) =>
      EstadoFirmaAcuerdo(
        hayAcuerdoVigente: json['hayAcuerdoVigente'] as bool,
        acuerdoId: json['acuerdoId'] as int?,
        firmado: json['firmado'] as bool,
        firmadoAt: json['firmadoAt'] != null
            ? DateTime.parse(json['firmadoAt'] as String)
            : null,
      );
}

// ── Service ───────────────────────────────────────────────────────────────────

class AcuerdoService {
  /// GET /acuerdo/vigente
  /// Devuelve el acuerdo cuya fecha de creación está más cercana a hoy,
  /// incluyendo su documento (título, subtítulo, abstract y tópicos).
  static Future<AcuerdoVigente> obtenerAcuerdoVigente() async {
    final response = await ApiService.get('/acuerdo/vigente');
    return AcuerdoVigente.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /acuerdo/firmar
  /// Registra la firma del estudiante autenticado sobre el acuerdo vigente.
  /// No requiere body: el rut se infiere del token JWT.
  /// Es idempotente: firmar dos veces la misma versión no genera duplicados.
  static Future<EstadoFirmaAcuerdo> firmarAcuerdo() async {
    final response = await ApiService.post('/acuerdo/firmar');
    return EstadoFirmaAcuerdo.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /acuerdo/me/estado
  /// Devuelve si el estudiante autenticado ya firmó el acuerdo vigente.
  /// Nunca falla por ausencia de firma previa: retorna firmado=false si no ha firmado.
  static Future<EstadoFirmaAcuerdo> obtenerEstadoAcuerdo() async {
    final response = await ApiService.get('/acuerdo/me/estado');
    return EstadoFirmaAcuerdo.fromJson(response.data as Map<String, dynamic>);
  }
}
