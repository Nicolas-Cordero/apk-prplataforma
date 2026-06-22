import 'package:carmen_goudie/models/estudiante.dart';
import 'package:carmen_goudie/services/api_service.dart';

/// Servicio de lectura de datos de estudiantes.
///
/// Solo expone operaciones de lectura (`GET`): un estudiante no edita la
/// información inherente a su propio perfil desde la apk. Los errores HTTP se
/// propagan tal cual los lanza `ApiService`/Dio, igual que el resto de los
/// services del proyecto.
class EstudianteService {
  /// GET /estudiante/me
  ///
  /// Devuelve los datos del estudiante autenticado actualmente (el rut se toma
  /// del token guardado, en el backend).
  static Future<Estudiante> obtenerPerfilPropio() async {
    final response = await ApiService.get('/estudiante/me');
    return Estudiante.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /estudiante?soloActivos=true
  ///
  /// Devuelve la lista de becarios activos con generación, liceo y carrera
  /// (incluida universidad) ya incluidos en la respuesta.
  static Future<List<Estudiante>> obtenerBecariosActivos() async {
    final response = await ApiService.get(
      '/estudiante',
      queryParameters: {'soloActivos': 'true'},
    );
    return (response.data as List<dynamic>)
        .map((e) => Estudiante.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /estudiante/:rut_estudiante/simple
  ///
  /// Devuelve un estudiante con información reducida, identificado por rut.
  static Future<Estudiante> obtenerEstudianteSimple(String rutEstudiante) async {
    final response = await ApiService.get('/estudiante/$rutEstudiante/simple');
    return Estudiante.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /estudiante/:rut_estudiante/complete
  ///
  /// Devuelve un estudiante con información completa, identificado por rut.
  static Future<Estudiante> obtenerEstudianteCompleto(
    String rutEstudiante,
  ) async {
    final response = await ApiService.get('/estudiante/$rutEstudiante/complete');
    return Estudiante.fromJson(response.data as Map<String, dynamic>);
  }
}
