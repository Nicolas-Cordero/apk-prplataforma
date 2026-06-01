/// Modelo para semestre
class Semestre {
  final String id;
  final String nombre; // Ej: "2025-1", "2025-2"
  final int anio;
  final int numeroSemestre;
  final bool esActual;

  Semestre({
    required this.id,
    required this.nombre,
    required this.anio,
    required this.numeroSemestre,
    required this.esActual,
  });

  factory Semestre.fromJson(Map<String, dynamic> json) {
    return Semestre(
      id: (json['id'] as String?) ?? '',
      nombre: (json['nombre'] as String?) ?? '',
      anio: (json['anio'] as int?) ?? 0,
      numeroSemestre: (json['numero_semestre'] as int?) ?? 0,
      esActual: (json['es_actual'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'anio': anio,
      'numero_semestre': numeroSemestre,
      'es_actual': esActual,
    };
  }
}

/// Servicio para gestionar semestres
class SemestreService {
  /// Obtiene el semestre actual del estudiante
  static Future<Semestre> obtenerSemestreActual() async {
    // Por ahora, retorna un semestre hardcodeado
    // En produccion, se consultaria desde la base de datos
    return Semestre(
      id: 'SEM-2025-2',
      nombre: '2025-2',
      anio: 2025,
      numeroSemestre: 2,
      esActual: true,
    );
  }

  /// Obtiene todos los semestres del estudiante (historico + actual)
  static Future<List<Semestre>> obtenerTodosSemestres() async {
    // Por ahora, retorna semestres hardcodeados
    // En produccion, se consultaria desde la base de datos
    return [
      Semestre(
        id: 'SEM-2023-1',
        nombre: '2023-1',
        anio: 2023,
        numeroSemestre: 1,
        esActual: false,
      ),
      Semestre(
        id: 'SEM-2023-2',
        nombre: '2023-2',
        anio: 2023,
        numeroSemestre: 2,
        esActual: false,
      ),
      Semestre(
        id: 'SEM-2024-1',
        nombre: '2024-1',
        anio: 2024,
        numeroSemestre: 1,
        esActual: false,
      ),
      Semestre(
        id: 'SEM-2024-2',
        nombre: '2024-2',
        anio: 2024,
        numeroSemestre: 2,
        esActual: false,
      ),
      Semestre(
        id: 'SEM-2025-1',
        nombre: '2025-1',
        anio: 2025,
        numeroSemestre: 1,
        esActual: false,
      ),
      Semestre(
        id: 'SEM-2025-2',
        nombre: '2025-2',
        anio: 2025,
        numeroSemestre: 2,
        esActual: true,
      ),
    ];
  }
}
