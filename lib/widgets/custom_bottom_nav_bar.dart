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
    // Obtener el bottom padding del SafeArea 
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom * 0.5;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Navbar con burbujas e indicador superior
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                icons.length,
                (index) => Flexible(
                  child: _buildNavItem(index),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index) {
    bool isSelected = index == currentIndex;
    Color tabColor = colors[index];

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador superior animado con bordes redondeados
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: isSelected ? 4 : 0,
            width: isSelected ? 40 : 0,
            decoration: BoxDecoration(
              color: isSelected ? tabColor : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          // Burbuja con ícono
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? tabColor.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icons[index],
              color: isSelected ? tabColor : Colors.grey[400],
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
                color: isSelected ? tabColor : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
