class Usuario {
  final String rutUsuario;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final String rol;
  final bool activo;
  final bool mustChangePassword;

  Usuario({
    required this.rutUsuario,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    required this.rol,
    required this.activo,
    required this.mustChangePassword,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      rutUsuario: json['rut_usuario'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      email: json['email'] as String,
      telefono: json['telefono'] as String? ?? '',
      rol: json['rol'] as String,
      activo: json['activo'] as bool? ?? true,
      mustChangePassword: json['must_change_password'] as bool? ?? false,
    );
  }

  String get nombreCompleto => '$nombre $apellido';

  @override
  String toString() => 'Usuario(nombre: $nombre, rol: $rol)';
}
