/// Modelo que representa un Usuario en el sistema
/// Entidad de autenticación y sesión
class Usuario {
  final String rut;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final String rol;
  final String contrasena;

  Usuario({
    required this.rut,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    required this.rol,
    required this.contrasena,
  });

  /// Crea un Usuario a partir de un JSON (desde API o archivo local)
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      rut: json['rut'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      email: json['email'] as String,
      telefono: json['telefono'] as String,
      rol: json['rol'] as String,
      contrasena: json['contraseña'] as String? ?? json['contrasena'] as String,
    );
  }

  /// Convierte el Usuario a JSON (para enviar a API)
  Map<String, dynamic> toJson() {
    return {
      'rut': rut,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'rol': rol,
      'contraseña': contrasena,
    };
  }

  /// Retorna el nombre completo
  String get nombreCompleto => '$nombre $apellido';

  @override
  String toString() => 'Usuario(nombre: $nombre, rol: $rol)';
}
