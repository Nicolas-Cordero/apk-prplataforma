import 'package:flutter/material.dart';

/// Paleta de colores de la Fundación para la aplicación
/// Todos los colores están definidos aquí para fácil mantenimiento y temas futuros
abstract class AppColors {
  // Colores de las pestañas
  static const Color misRamos = Color.fromRGBO(87, 182, 167, 1);      // Verde: #57B6A7
  static const Color misNotas = Color.fromRGBO(213, 95, 63, 1);       // Rojo: #D55F3F
  static const Color yo = Color.fromRGBO(34, 76, 82, 1);              // Azul-Verde: #224C52
  static const Color becarios = Color.fromRGBO(236, 184, 118, 1);     // Amarillo: #ECB876
  static const Color compromiso = Color.fromARGB(255, 122, 113, 255); // Morado: #7A71FF

  // Color neutro para elementos no seleccionados
  static const Color inactiveIcon = Colors.grey;
  
  // Color de fondo general
  static const Color navBarBackground = Colors.white;
  static const Color pageBackground = Colors.white;
}
