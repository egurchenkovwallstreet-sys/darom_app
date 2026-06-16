import 'package:flutter/material.dart';
import 'package:darom_app/screens/auth_gate.dart';
import 'package:darom_app/services/planet_assets.dart';
import 'package:darom_app/services/session_service.dart';
import 'package:darom_app/theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PlanetAssets.preload();
  await SessionService.migrateToRemoteServerIfNeeded();
  runApp(const DaromApp());
}

class DaromApp extends StatelessWidget {
  const DaromApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Даром',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.cyan,
        scaffoldBackgroundColor: AppColors.darkBlue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.cyan,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
