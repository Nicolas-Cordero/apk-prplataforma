import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:carmen_goudie/models/estudiante.dart';
import 'package:carmen_goudie/services/estudiante_service.dart';
import 'package:carmen_goudie/services/usuario_service.dart';
import 'package:carmen_goudie/pages/notificaciones_page.dart';
import 'package:carmen_goudie/services/notification_service.dart';

/// Widget personalizado para la barra superior de la aplicación
class CustomAppBar extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  final VoidCallback onLogout;

  const CustomAppBar({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.onLogout,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _bellAnimationController;
  late Future<Estudiante> _estudianteFuture;

  // Cache compartido entre instancias del widget (navegación entre pantallas).
  // Evita el flash de 'CG' y llamadas redundantes a /estudiante/me.
  static Estudiante? _cachedEstudiante;

  /// Limpia el cache al cerrar sesión.
  static void clearCache() => _cachedEstudiante = null;

  @override
  void initState() {
    super.initState();
    _bellAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    // Si ya hay datos en cache, los usamos de forma síncrona (sin flash de 'CG').
    // Si no, hacemos el fetch y guardamos el resultado en cache.
    if (_cachedEstudiante != null) {
      _estudianteFuture = SynchronousFuture(_cachedEstudiante!);
    } else {
      _estudianteFuture = EstudianteService.obtenerPerfilPropio().then((est) {
        _cachedEstudiante = est;
        return est;
      });
    }
    NotificationService.refrescarContador();
  }

  @override
  void dispose() {
    _bellAnimationController.dispose();
    super.dispose();
  }

  Widget _buildLeadingAvatar(
    AsyncSnapshot<Estudiante> snapshot,
    Color circleBg,
    bool isDark,
  ) {
    final fotoUrl = snapshot.hasData ? snapshot.data!.fotoUrl : null;
    final tieneFoto = fotoUrl != null && fotoUrl.isNotEmpty;

    if (tieneFoto) {
      return ClipOval(
        child: Image.network(
          fotoUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) =>
              _buildInitiales(snapshot, circleBg, isDark),
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : _buildInitiales(snapshot, circleBg, isDark),
        ),
      );
    }
    return _buildInitiales(snapshot, circleBg, isDark);
  }

  Widget _buildInitiales(
    AsyncSnapshot<Estudiante> snapshot,
    Color circleBg,
    bool isDark,
  ) {
    String iniciales = 'CG';
    if (snapshot.hasData) {
      final est = snapshot.data!;
      final n = est.nombre.isNotEmpty ? est.nombre[0] : '';
      final a = est.apellido.isNotEmpty ? est.apellido[0] : '';
      iniciales = (n + a).toUpperCase();
      if (iniciales.isEmpty) iniciales = 'CG';
    }
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, color: circleBg),
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
  }

  void _onBellTap() {
    // Reproducir animación de campana
    _bellAnimationController.forward().then((_) {
      _bellAnimationController.reverse();
    });
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificacionesPageWrapper()),
    );
  }

  Future<void> _onLogoutTap() async {
    // cerrarSesion() limpia los tokens (y nunca lanza: maneja el error en su
    // finally). Luego avisamos a la app para volver al login.
    clearCache();
    await UsuarioService.cerrarSesion();
    if (!mounted) return;
    widget.onLogout();
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
          builder: (context, snapshot) => _buildLeadingAvatar(
            snapshot,
            circleBackgroundColor,
            isDark,
          ),
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
        // Botón de cerrar sesión
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: CircleAvatar(
            backgroundColor: circleBackgroundColor,
            child: IconButton(
              icon: Icon(
                Icons.logout,
                color: iconColor,
                size: 20,
              ),
              onPressed: _onLogoutTap,
              tooltip: 'Cerrar sesión',
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
