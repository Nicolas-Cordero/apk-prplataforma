import 'package:flutter/material.dart';
import 'package:test1/models/estudiante.dart';
import 'package:test1/services/estudiante_service.dart';
import 'package:test1/pages/page5.dart';
import 'package:test1/services/notification_service.dart';

/// Widget personalizado para la barra superior de la aplicación
class CustomAppBar extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const CustomAppBar({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _bellAnimationController;
  late Future<Estudiante> _estudianteFuture;

  @override
  void initState() {
    super.initState();
    _bellAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    // Cargar datos del estudiante
    _estudianteFuture = EstudianteService.obtenerEstudianteActual();
    NotificationService.refrescarContador();
  }

  @override
  void dispose() {
    _bellAnimationController.dispose();
    super.dispose();
  }

  void _onBellTap() {
    // Reproducir animación de campana
    _bellAnimationController.forward().then((_) {
      _bellAnimationController.reverse();
    });
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const Page5Wrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    // Usar el mismo fondo global definido en AppBackground
    final lightBg = const Color.fromRGBO(255, 251, 242, 1);
    final darkBg = const Color.fromRGBO(22, 20, 18, 1);
    final backgroundColor = isDark ? darkBg : lightBg;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white70 : Colors.grey[600];
    final circleBackgroundColor = isDark ? darkBg.withValues(alpha: 0.6) : lightBg.withValues(alpha: 0.92);

    return AppBar(
      elevation: 0,
      backgroundColor: backgroundColor,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<Estudiante>(
          future: _estudianteFuture,
          builder: (context, snapshot) {
            String iniciales = 'CG';
            if (snapshot.hasData) {
              final estudiante = snapshot.data!;
              iniciales =
                  '${estudiante.nombre[0]}${estudiante.apellido[0]}'
                      .toUpperCase();
            }
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleBackgroundColor,
              ),
              child: Center(
                child: Text(
                  iniciales,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      title: FutureBuilder<Estudiante>(
        future: _estudianteFuture,
        builder: (context, snapshot) {
          // Estado de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cargando...',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Text(
                  'Estudiante',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          }

          // Error al cargar
          if (snapshot.hasError) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Text(
                  'No disponible',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          }

          // Datos cargados exitosamente
          if (snapshot.hasData) {
            final estudiante = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estudiante',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Text(
                  estudiante.nombreCompleto,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          }

          // Por defecto
          return const SizedBox.shrink();
        },
      ),
      actions: [
        // Botón de cambio de tema
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: CircleAvatar(
            backgroundColor: circleBackgroundColor,
            child: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 100),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  key: ValueKey<bool>(widget.isDarkMode),
                  color: widget.isDarkMode ? Colors.amber : Colors.orange,
                  size: 20,
                ),
              ),
              onPressed: widget.onThemeToggle,
              tooltip: 'Cambiar tema',
            ),
          ),
        ),
        // Botón de notificaciones (campana)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ValueListenableBuilder<int>(
            valueListenable: NotificationService.contador,
            builder: (context, count, _) {
              final badgeText = count > 99 ? '99+' : '$count';
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    backgroundColor: circleBackgroundColor,
                    child: RotationTransition(
                      turns: Tween(begin: 0.0, end: 0.1)
                          .animate(_bellAnimationController),
                      alignment: Alignment.topCenter,
                      child: IconButton(
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: iconColor,
                          size: 20,
                        ),
                        onPressed: _onBellTap,
                        tooltip: 'Notificaciones',
                      ),
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        constraints: const BoxConstraints(minWidth: 18),
                        child: Text(
                          badgeText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
