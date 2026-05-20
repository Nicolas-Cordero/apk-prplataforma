import 'package:flutter/material.dart';
import 'package:test1/constants/app_colors.dart';

/// Página 0: Mis Ramos
class Page0 extends StatelessWidget {
  const Page0({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book, size: 80, color: AppColors.misRamos),
          const SizedBox(height: 20),
          const Text(
            'Mis Ramos',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
