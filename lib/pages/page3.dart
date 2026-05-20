import 'package:flutter/material.dart';
import 'package:test1/constants/app_colors.dart';

/// Página 3: Becarios
class Page3 extends StatelessWidget {
  const Page3({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group, size: 80, color: AppColors.becarios),
          const SizedBox(height: 20),
          const Text(
            'Becarios',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
