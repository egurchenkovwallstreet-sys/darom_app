import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:darom_app/screens/admin_gate.dart';
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

  Widget _homeWidget() {
    if (kIsWeb) {
      final path = Uri.base.path;
      if (path.startsWith('/admin')) {
        return const AdminGate();
      }
    }
    return const AuthGate();
  }

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
      home: _homeWidget(),
    );
  }
}
