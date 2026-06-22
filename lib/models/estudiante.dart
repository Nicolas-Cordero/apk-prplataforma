// Sub-modelos devueltos como relaciones anidadas en los endpoints
// `/estudiante/me` y `/estudiante/:rut/complete`.

class GeneracionRel {
  final int id;

  /// Año de la generación (campo `año` en el backend).
  final int anio;
  final String? descripcion;

  const GeneracionRel({required this.id, required this.anio, this.descripcion});

  factory GeneracionRel.fromJson(Map<String, dynamic> json) => GeneracionRel(
        id: json['id'] as int,
        anio: json['año'] as int,
        descripcion: json['descripcion'] as String?,
      );
}

class LiceoData {
  final String rbd;
  final String nombre;
  final String comuna;
  final String especialidad;

  const LiceoData({
    required this.rbd,
    required this.nombre,
    required this.comuna,
    required this.especialidad,
  });

  factory LiceoData.fromJson(Map<String, dynamic> json) => LiceoData(
        rbd: json['rbd'] as String? ?? '',
        nombre: json['nombre'] as String? ?? '',
        comuna: json['comuna'] as String? ?? '',
        especialidad: json['especialidad'] as String? ?? '',
      );
}

class UniversidadData {
  final int codigoUniversidad;
  final String nombre;
  final String comuna;

  const UniversidadData({
    required this.codigoUniversidad,
    required this.nombre,
    required this.comuna,
  });

  factory UniversidadData.fromJson(Map<String, dynamic> json) =>
      UniversidadData(
        codigoUniversidad: json['codigo_universidad'] as int? ?? 0,
        nombre: json['nombre'] as String? ?? '',
        comuna: json['comuna'] as String? ?? '',
      );
}

class CarreraData {
  final int codigoCarrera;
  final String nombre;
  final String rutEstudiante;
  final int duracionSem;
  final int codigoUniversidad;
  final String viaAcceso;
  final UniversidadData? universidad;

  const CarreraData({
    required this.codigoCarrera,
    required this.nombre,
    required this.rutEstudiante,
    required this.duracionSem,
    required this.codigoUniversidad,
    required this.viaAcceso,
    this.universidad,
  });

  factory CarreraData.fromJson(Map<String, dynamic> json) => CarreraData(
        codigoCarrera: json['codigo_carrera'] as int? ?? 0,
        nombre: json['nombre'] as String? ?? '',
        rutEstudiante: json['rut_estudiante'] as String? ?? '',
        duracionSem: json['duracion_sem'] as int? ?? 0,
        codigoUniversidad: json['codigo_universidad'] as int? ?? 0,
        viaAcceso: json['via_acceso'] as String? ?? '',
        universidad: json['universidad'] != null
            ? UniversidadData.fromJson(
                json['universidad'] as Map<String, dynamic>)
            : null,
      );
}

class FamiliarData {
  final int id;
  final String rutFamiliar;
  final String rutEstudiante;
  final String nombre;
  final String telefono;
  final String parentesco;
  final bool esContactoEmergencia;
  final String? observacion;

  const FamiliarData({
    required this.id,
    required this.rutFamiliar,
    required this.rutEstudiante,
    required this.nombre,
    required this.telefono,
    required this.parentesco,
    required this.esContactoEmergencia,
    this.observacion,
  });

  factory FamiliarData.fromJson(Map<String, dynamic> json) => FamiliarData(
        id: json['id'] as int? ?? 0,
        rutFamiliar: json['rut_familiar'] as String? ?? '',
        rutEstudiante: json['rut_estudiante'] as String? ?? '',
        nombre: json['nombre'] as String? ?? '',
        telefono: json['telefono'] as String? ?? '',
        parentesco: json['parentesco'] as String? ?? '',
        esContactoEmergencia:
            json['es_contacto_emergencia'] as bool? ?? false,
        observacion: json['observacion'] as String?,
      );
}

// Modelo principal del estudiante.
// Los campos anidados solo se populan en /me y /complete;
// /simple devuelve un subconjunto sin relaciones.
class Estudiante {
  final String rutEstudiante;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final DateTime fechaNacimiento;
  final String direccion;
  final String genero;
  final String rbdLiceo;
  final int? puntajePaes;
  final String? fotoUrl;
  final String estado;
  final double promediosMedia;
  final int generacionId;

  // Relaciones anidadas — presentes en /me y /complete.
  final GeneracionRel? generacionRel;
  final LiceoData? liceo;
  final List<CarreraData> carreras;
  final List<FamiliarData> familiares;

  const Estudiante({
    required this.rutEstudiante,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    required this.fechaNacimiento,
    required this.direccion,
    required this.genero,
    required this.rbdLiceo,
    required this.puntajePaes,
    required this.fotoUrl,
    required this.estado,
    required this.promediosMedia,
    required this.generacionId,
    this.generacionRel,
    this.liceo,
    this.carreras = const [],
    this.familiares = const [],
  });

  factory Estudiante.fromJson(Map<String, dynamic> json) {
    return Estudiante(
      rutEstudiante: json['rut_estudiante'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      email: json['email'] as String,
      telefono: json['telefono'] as String? ?? '',
      fechaNacimiento: DateTime.parse(json['fecha_nacimiento'] as String),
      direccion: json['direccion'] as String? ?? '',
      genero: json['genero'] as String? ?? '',
      rbdLiceo: json['rbd_liceo'] as String,
      puntajePaes: json['puntaje_paes'] as int?,
      fotoUrl: json['foto_url'] as String?,
      estado: json['estado'] as String,
      promediosMedia: _aDouble(json['promedios_media']),
      generacionId: json['generacion_id'] as int,
      generacionRel: json['generacion_rel'] != null
          ? GeneracionRel.fromJson(
              json['generacion_rel'] as Map<String, dynamic>)
          : null,
      liceo: json['liceo'] != null
          ? LiceoData.fromJson(json['liceo'] as Map<String, dynamic>)
          : null,
      carreras: (json['carreras'] as List<dynamic>? ?? [])
          .map((e) => CarreraData.fromJson(e as Map<String, dynamic>))
          .toList(),
      familiares: (json['familiares'] as List<dynamic>? ?? [])
          .map((e) => FamiliarData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static double _aDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String get nombreCompleto => '$nombre $apellido';

  bool get esActivo => estado.toUpperCase() == 'ACTIVO';

  /// Primer familiar con es_contacto_emergencia == true, o null si no existe.
  FamiliarData? get contactoEmergencia =>
      familiares.where((f) => f.esContactoEmergencia).firstOrNull;

  @override
  String toString() => 'Estudiante(nombre: $nombreCompleto, estado: $estado)';
}
