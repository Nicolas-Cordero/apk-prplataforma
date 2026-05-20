import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Wrapper que dibuja el fondo y marcos laterales sutiles.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  Future<ByteData?> _tryLoadAsset(String path) async {
    try {
      return await rootBundle.load(path);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colores solicitados
    final lightBg = const Color.fromRGBO(255, 251, 242, 1); // RGB(255,251,242)
    final darkBg = const Color.fromRGBO(22, 20, 18, 1); // grisáceo con tinte muy sutil amarillo

    return Container(
      color: isDark ? darkBg : lightBg,
      child: Stack(
        children: [
          // Marco izquierdo (SVG) — cargado de forma segura
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.08,
              child: FutureBuilder<ByteData?>(
                future: _tryLoadAsset('assets/data/graphics/marco-izquierda.svg'),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) return const SizedBox.shrink();
                  return SvgPicture.memory(
                    snapshot.data!.buffer.asUint8List(),
                    fit: BoxFit.fitHeight,
                    height: double.infinity,
                    allowDrawingOutsideViewBox: true,
                  );
                },
              ),
            ),
          ),

          // Marco derecho (SVG) — cargado de forma segura
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.08,
              child: FutureBuilder<ByteData?>(
                future: _tryLoadAsset('assets/data/graphics/marco-derecha.svg'),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) return const SizedBox.shrink();
                  return SvgPicture.memory(
                    snapshot.data!.buffer.asUint8List(),
                    fit: BoxFit.fitHeight,
                    height: double.infinity,
                    allowDrawingOutsideViewBox: true,
                  );
                },
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
