class BecarioItem {
  final String rut;
  final String nombre;
  final String apellido;
  final String universidad;
  final String carrera;
  final String liceo;
  final int generacion;
  final String telefono;

  BecarioItem({
    required this.rut,
    required this.nombre,
    required this.apellido,
    required this.universidad,
    required this.carrera,
    required this.liceo,
    required this.generacion,
    required this.telefono,
  });

  String get nombreCompleto => '$nombre $apellido'.trim();

  String get iniciales {
    final n = nombre.isNotEmpty ? nombre[0] : '';
    final a = apellido.isNotEmpty ? apellido[0] : '';
    return (n + a).toUpperCase();
  }
}
