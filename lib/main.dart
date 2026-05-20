import 'package:flutter/material.dart';
import 'package:test1/app.dart';
import 'package:test1/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.inicializar();
  runApp(const MyApp());
}
