import 'package:flutter/material.dart';
import 'package:carmen_goudie/constants/app_colors.dart';

/// Página de Compromiso
class CompromisoPage extends StatelessWidget {
  const CompromisoPage({super.key});

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
