import 'package:flutter/material.dart';
import 'package:test1/constants/app_colors.dart';

/// Página 4: Compromiso
class Page4 extends StatelessWidget {
  const Page4({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description, size: 80, color: AppColors.compromiso),
          const SizedBox(height: 20),
          const Text(
            'Compromiso',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
