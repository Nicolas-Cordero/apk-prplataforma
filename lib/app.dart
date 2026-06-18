import 'package:flutter/material.dart';
import 'package:carmen_goudie/constants/app_colors.dart';
import 'package:carmen_goudie/themes/app_theme.dart';
import 'package:carmen_goudie/pages/home.dart';
import 'package:carmen_goudie/pages/login_page.dart';
import 'package:carmen_goudie/services/api_service.dart';
import 'package:carmen_goudie/services/notification_service.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  // null = comprobando sesión, true/false = resultado
  bool? _isAuthenticated;

  @override
  void initState() {
    super.initState();
    NotificationService.solicitarPermisos();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    final hasSession = await ApiService.hasSession();
    if (mounted) setState(() => _isAuthenticated = hasSession);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fundación Carmen Goudie',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_isAuthenticated == null) {
      return const Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isAuthenticated!) {
      return HomePage(
        onThemeChanged: (isDark) => setState(() => _isDarkMode = isDark),
      );
    }

    return LoginPage(
      onLoginSuccess: () => setState(() => _isAuthenticated = true),
    );
  }
}
