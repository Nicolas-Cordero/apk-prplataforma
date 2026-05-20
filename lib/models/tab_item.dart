import 'package:flutter/material.dart';

/// Modelo que representa un item de la barra de navegación
class TabItem {
  final IconData icon;
  final String label;
  final Color color;
  final Widget page;

  const TabItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.page,
  });
}
