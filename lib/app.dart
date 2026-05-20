import 'package:flutter/material.dart';
import 'package:test1/themes/app_theme.dart';
import 'package:test1/pages/home.dart';

/// Widget que maneja el estado global del tema de la aplicación
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fundación Carmen Goudie',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomePage(
        onThemeChanged: (isDark) {
          setState(() {
            _isDarkMode = isDark;
          });
        },
      ),
    );
  }
}
