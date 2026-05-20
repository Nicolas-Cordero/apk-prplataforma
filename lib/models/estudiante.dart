/// Modelo que representa un Estudiante en el sistema
/// Extensión del Usuario con información académica
class Estudiante {
  final String rutEstudiante;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final int puntajePaes;
  final int generacion;
  final String rbdLiceo;
  final Map<String, double> promediosMedia;
  final String estado;

  Estudiante({
    required this.rutEstudiante,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    required this.puntajePaes,
    required this.generacion,
    required this.rbdLiceo,
    required this.promediosMedia,
    required this.estado,
  });

  /// Crea un Estudiante a partir de un JSON (desde API o archivo local)
  factory Estudiante.fromJson(Map<String, dynamic> json) {
    return Estudiante(
      rutEstudiante: json['rut_estudiante'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      email: json['email'] as String,
      telefono: json['telefono'] as String,
      puntajePaes: json['puntaje_paes'] as int,
      generacion: json['generacion'] as int,
      rbdLiceo: json['rbd_liceo'] as String,
      promediosMedia: Map<String, double>.from(
        (json['promedios_media'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
      estado: json['estado'] as String,
    );
  }

  /// Convierte el Estudiante a JSON (para enviar a API)
  Map<String, dynamic> toJson() {
    return {
      'rut_estudiante': rutEstudiante,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'puntaje_paes': puntajePaes,
      'generacion': generacion,
      'rbd_liceo': rbdLiceo,
      'promedios_media': promediosMedia,
      'estado': estado,
    };
  }

  /// Retorna el nombre completo del estudiante
  String get nombreCompleto => '$nombre $apellido';

  /// Calcula el promedio general de todas las asignaturas
  double get promedioGeneral {
    if (promediosMedia.isEmpty) return 0.0;
    final suma = promediosMedia.values.fold<double>(0, (a, b) => a + b);
    return suma / promediosMedia.length;
  }

  /// Retorna información académica del estudiante
  String get infoAcademica =>
      'PAES: $puntajePaes | Promedio: ${promedioGeneral.toStringAsFixed(2)}';

  /// Verifica si el estudiante está activo
  bool get esActivo => estado.toLowerCase() == 'activo';

  @override
  String toString() =>
      'Estudiante(nombre: $nombre, puntajePaes: $puntajePaes, estado: $estado)';
}

