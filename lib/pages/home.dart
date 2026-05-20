import 'package:flutter/material.dart';
import 'package:test1/constants/app_colors.dart';
import 'package:test1/models/tab_item.dart';
import 'package:test1/pages/page0.dart';
import 'package:test1/pages/page1.dart';
import 'package:test1/pages/page2.dart';
import 'package:test1/pages/page3.dart';
import 'package:test1/pages/page4.dart';
import 'package:test1/widgets/custom_bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2; // Pestaña "Yo" por defecto

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: tabs[_selectedIndex].page,
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


