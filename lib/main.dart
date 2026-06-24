import 'package:flutter/material.dart';
import 'package:carmen_goudie/app.dart';
import 'package:carmen_goudie/services/api_service.dart';
import 'package:carmen_goudie/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  await NotificationService.inicializar();
  runApp(const MyApp());
}
