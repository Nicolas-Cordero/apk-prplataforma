import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Wrapper que dibuja el fondo y marcos laterales sutiles.
///
/// Usa SvgPicture.asset() (con caché interno de flutter_svg) en vez de
/// FutureBuilder + rootBundle.load, evitando cambios estructurales en el árbol
/// que corrompen el parentData del árbol de semántica durante el startup.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lightBg = const Color.fromRGBO(255, 251, 242, 1);
    final darkBg  = const Color.fromRGBO(22, 20, 18, 1);

    return Container(
      color: isDark ? darkBg : lightBg,
      child: Stack(
        children: [
          // Marco izquierdo
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.08,
              child: SvgPicture.asset(
                'assets/data/graphics/marco-izquierda.svg',
                fit: BoxFit.fitHeight,
                allowDrawingOutsideViewBox: true,
              ),
            ),
          ),

          // Marco derecho
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.08,
              child: SvgPicture.asset(
                'assets/data/graphics/marco-derecha.svg',
                fit: BoxFit.fitHeight,
                allowDrawingOutsideViewBox: true,
              ),
            ),
          ),

          // Contenido principal
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
