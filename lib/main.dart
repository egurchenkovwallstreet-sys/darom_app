import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:darom_app/screens/admin_gate.dart';
import 'package:darom_app/screens/auth_gate.dart';
import 'package:darom_app/services/planet_assets.dart';
import 'package:darom_app/services/session_service.dart';
import 'package:darom_app/theme/app_colors.dart';
import 'package:darom_app/screens/public_offer_screen.dart';
import 'package:darom_app/widgets/payment_flow.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PlanetAssets.preload();
  await SessionService.migrateToRemoteServerIfNeeded();
  await SessionService.migrateToTokenSessionIfNeeded();
  runApp(const DaromApp());
}

class DaromApp extends StatelessWidget {
  const DaromApp({super.key});

  Widget _homeWidget() {
    if (kIsWeb) {
      final uri = Uri.base;
      final path = uri.path;
      if (path.startsWith('/admin')) {
        return const AdminGate();
      }
      if (path.startsWith('/payment/success')) {
        return PaymentResultScreen(
          success: true,
          invId: uri.queryParameters['inv_id'],
        );
      }
      if (path.startsWith('/payment/fail')) {
        return PaymentResultScreen(
          success: false,
          invId: uri.queryParameters['inv_id'],
        );
      }
      if (path.startsWith('/offer')) {
        return const PublicOfferScreen();
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
