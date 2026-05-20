import 'package:flutter/material.dart';
import 'package:test1/constants/app_colors.dart';

/// Página 1: Mis Notas
class Page1 extends StatelessWidget {
  const Page1({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment, size: 80, color: AppColors.misNotas),
          const SizedBox(height: 20),
          const Text(
            'Mis Notas',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
