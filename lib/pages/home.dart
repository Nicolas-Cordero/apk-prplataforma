import 'package:flutter/material.dart';
import 'package:carmen_goudie/constants/app_colors.dart';
import 'package:carmen_goudie/models/tab_item.dart';
import 'package:carmen_goudie/pages/page0.dart';
import 'package:carmen_goudie/pages/page1.dart';
import 'package:carmen_goudie/pages/page2.dart';
import 'package:carmen_goudie/pages/page3.dart';
import 'package:carmen_goudie/pages/page4.dart';
import 'package:carmen_goudie/widgets/custom_top_bar.dart';
import 'package:carmen_goudie/widgets/app_background.dart';
import 'package:carmen_goudie/services/contacto_emergencia_service.dart';
import 'package:carmen_goudie/services/estudiante_service.dart';
import 'package:carmen_goudie/services/notification_service.dart';
import 'package:carmen_goudie/widgets/custom_bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  final Function(bool)? onThemeChanged;

  const HomePage({super.key, this.onThemeChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2; // Pestaña "Yo" por defecto
  bool _isDarkMode = false; // Estado local del tema

  /// Define todas las pestañas de navegación
  late final List<TabItem> tabs = [
    TabItem(
      icon: Icons.book,
      label: 'Mis Ramos',
      color: AppColors.misRamos,
      page: const Page0(),
    ),
    TabItem(
      icon: Icons.assignment,
      label: 'Mis Notas',
      color: AppColors.misNotas,
      page: const Page1(),
    ),
    TabItem(
      icon: Icons.person,
      label: 'Yo',
      color: AppColors.yo,
      page: const Page2(),
    ),
    TabItem(
      icon: Icons.group,
      label: 'Becarios',
      color: AppColors.becarios,
      page: const Page3(),
    ),
    TabItem(
      icon: Icons.description,
      label: 'Compromiso',
      color: AppColors.compromiso,
      page: const Page4(),
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _verificarContactosEmergencia();
  }

  Future<void> _verificarContactosEmergencia() async {
    try {
      final estudiante = await EstudianteService.obtenerEstudianteActual();
      final contacto = await ContactoEmergenciaService.obtenerPorRut(
        estudiante.rutEstudiante,
      );

      final tieneTelefono = (contacto?.telefono.trim().isNotEmpty ?? false);
      final tieneCorreo = (contacto?.correo.trim().isNotEmpty ?? false);

      if (!tieneTelefono && !tieneCorreo) {
        await NotificationService.agregarSiNoExiste(
          code: 'missing_emergency_contacts',
          title: 'Contactos de emergencia',
          body: 'Por favor, ingresa información de Contactos de Emergencia',
          type: 'warning',
          iconKey: 'emergency_contacts',
        );
      }
    } catch (_) {
      // No interrumpir la carga por fallos en notificaciones
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
        ),
      ),
      body: AppBackground(child: tabs[_selectedIndex].page),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        colors: tabs.map((tab) => tab.color).toList(),
        icons: tabs.map((tab) => tab.icon).toList(),
        labels: tabs.map((tab) => tab.label).toList(),
      ),
    );
  }
}


