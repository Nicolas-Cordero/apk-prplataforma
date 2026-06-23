import 'package:flutter/material.dart';
import 'package:carmen_goudie/constants/app_colors.dart';
import 'package:carmen_goudie/models/tab_item.dart';
import 'package:carmen_goudie/pages/mis_ramos_page.dart';
import 'package:carmen_goudie/pages/mis_notas_page.dart';
import 'package:carmen_goudie/pages/perfil_estudiante_page.dart';
import 'package:carmen_goudie/pages/becarios_page.dart';
import 'package:carmen_goudie/pages/compromiso_page.dart';
import 'package:carmen_goudie/widgets/custom_top_bar.dart';
import 'package:carmen_goudie/widgets/app_background.dart';
import 'package:carmen_goudie/widgets/custom_bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  final Function(bool)? onThemeChanged;
  final VoidCallback onLogout;

  const HomePage({super.key, this.onThemeChanged, required this.onLogout});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2; // Pestaña "Yo" por defecto
  bool _isDarkMode = false;

  // Incrementa con cada tap. Al cambiar la key, Flutter destruye y recrea
  // el State de la página → initState() → datos siempre frescos.
  int _tapCount = 0;

  /// Metadatos de las pestañas (solo para la barra de navegación).
  static const List<TabItem> _tabMeta = [
    TabItem(icon: Icons.book,        label: 'Mis Ramos',   color: AppColors.misRamos,   page: SizedBox.shrink()),
    TabItem(icon: Icons.assignment,  label: 'Mis Notas',   color: AppColors.misNotas,   page: SizedBox.shrink()),
    TabItem(icon: Icons.person,      label: 'Yo',          color: AppColors.yo,         page: SizedBox.shrink()),
    TabItem(icon: Icons.group,       label: 'Becarios',    color: AppColors.becarios,   page: SizedBox.shrink()),
    TabItem(icon: Icons.description, label: 'Compromiso',  color: AppColors.compromiso, page: SizedBox.shrink()),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _tapCount++;
    });
  }

  Widget _buildCurrentPage() {
    final key = ValueKey(_tapCount);
    switch (_selectedIndex) {
      case 0:  return MisRamosPage(key: key);
      case 1:  return MisNotasPage(key: key);
      case 2:  return PerfilEstudiantePage(key: key);
      case 3:  return BecariosPage(key: key);
      case 4:  return CompromisoPage(key: key);
      default: return PerfilEstudiantePage(key: key);
    }
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    // Notificar al widget padre para que cambie el tema global
    widget.onThemeChanged?.call(_isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(
          isDarkMode: _isDarkMode,
          onThemeToggle: _toggleTheme,
          onLogout: widget.onLogout,
        ),
      ),
      body: AppBackground(child: _buildCurrentPage()),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        colors: _tabMeta.map((t) => t.color).toList(),
        icons: _tabMeta.map((t) => t.icon).toList(),
        labels: _tabMeta.map((t) => t.label).toList(),
      ),
    );
  }
}


