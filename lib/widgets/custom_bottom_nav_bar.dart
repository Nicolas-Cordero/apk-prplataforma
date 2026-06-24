import 'package:flutter/material.dart';

/// Widget personalizado para la barra de navegación inferior con estilo de burbuja
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<Color> colors;
  final List<IconData> icons;
  final List<String> labels;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.colors,
    required this.icons,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
    
      // Obtener el bottom padding del SafeArea (notch/home indicator del iPhone)
      final bottomPadding = MediaQuery.of(context).viewPadding.bottom * 0.5;
      // Usar mismo fondo global que AppBackground
      final lightBg = const Color.fromRGBO(255, 251, 242, 1);
      final darkBg = const Color.fromRGBO(22, 20, 18, 1);
      final navBackgroundColor = isDark ? darkBg : lightBg;

    return Container(
      color: navBackgroundColor,
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Navbar con burbujas e indicador superior
          Container(
            color: navBackgroundColor,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                icons.length,
                (index) => Flexible(
                  child: _buildNavItem(index, isDark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, bool isDark) {
    bool isSelected = index == currentIndex;
    Color tabColor = colors[index];

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador superior: tamaño fijo, solo se anima la opacidad.
          // AnimatedContainer con size 0→N dentro de Flexible dispara re-layout
          // durante la animación y corrompe el parentData del árbol de semántica.
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            opacity: isSelected ? 1.0 : 0.0,
            child: Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: tabColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Burbuja con ícono
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
                color: isSelected ? tabColor.withValues(alpha: 0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icons[index],
              color: isSelected ? tabColor : (isDark ? Colors.grey[500] : Colors.grey[400]),
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          // Etiqueta (con ajustes para evitar cortes)
          Container(
            constraints: const BoxConstraints(maxWidth: 70),
            child: Text(
              labels[index],
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? tabColor : (isDark ? Colors.grey[500] : Colors.grey[400]),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
