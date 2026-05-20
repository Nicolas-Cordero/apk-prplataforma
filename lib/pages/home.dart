import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2; // Pestaña "Yo" por defecto.

  // Las 5 páginas/vistas
  final List<Widget> _pages = [
    const Page0(),  // Mis Ramos
    const Page1(), // Mis Notas
    const Page2(), // Yo
    const Page3(), // Becarios
    const Page4(), // Compromiso
  ];

  // Definir colores para cada pestaña - Paleta Fundación
  final List<Color> _tabColors = [
    const Color.fromRGBO(87, 182, 167, 1),   // Verde: #65B39B
    const Color.fromRGBO(213, 95, 63, 1),    // Rojo: #C7654F
    const Color.fromARGB(255, 40, 89, 97),      // Hex: #224C52
    const Color.fromRGBO(236, 184, 118, 1),   // Amarillo: #ECB876      // Hex: #224C52
    const Color.fromARGB(255, 122, 113, 255),    // Hex: #F5EEDC
  ];

  final List<IconData> _tabIcons = [
    Icons.book,                // Mis Ramos
    Icons.assignment,          // Mis Notas
    Icons.person,              // Yo
    Icons.group,               // Becarios
    Icons.description,         // Compromiso
  ];

  final List<String> _tabLabels = [
    'Mis Ramos',
    'Mis Notas',
    'Yo',
    'Becarios',
    'Compromiso',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        colors: _tabColors,
        icons: _tabIcons,
        labels: _tabLabels,
      ),
    );
  }
}

// Highlight navbar
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

// -PÁGINAS-

// Página 0: Mis Ramos
class Page0 extends StatelessWidget {
  const Page0({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book, size: 80, color: const Color.fromRGBO(87, 182, 167, 1)),
          const SizedBox(height: 20),
          const Text('Mis Ramos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Página 1: Mis Notas
class Page1 extends StatelessWidget {
  const Page1({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment, size: 80, color: const Color.fromRGBO(213, 95, 63, 1)),
          const SizedBox(height: 20),
          const Text('Mis Notas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Página 2: Yo 
class Page2 extends StatelessWidget {
  const Page2({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 80, color:  const Color.fromRGBO(34, 76, 82, 1)),
          const SizedBox(height: 20),
          const Text('Mi Perfil', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Página 3: Becarios
class Page3 extends StatelessWidget {
  const Page3({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group, size: 80, color: const Color.fromRGBO(236, 184, 118, 1)),
          const SizedBox(height: 20),
          const Text('Becarios', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Página 4: Compromiso
class Page4 extends StatelessWidget {
  const Page4({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description, size: 80, color: const Color.fromARGB(255, 122, 113, 255)),
          const SizedBox(height: 20),
          const Text('Compromiso', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}


