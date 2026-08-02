import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:darom_app/screens/admin_gate.dart';
import 'package:darom_app/screens/auth_gate.dart';
import 'package:darom_app/services/locale_service.dart';
import 'package:darom_app/services/planet_assets.dart';
import 'package:darom_app/services/session_service.dart';
import 'package:darom_app/theme/app_colors.dart';
import 'package:darom_app/screens/public_offer_screen.dart';
import 'package:darom_app/screens/privacy_policy_screen.dart';
import 'package:darom_app/widgets/payment_flow.dart';
import 'package:darom_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:darom_app/utils/hide_web_splash_stub.dart'
    if (dart.library.html) 'package:darom_app/utils/hide_web_splash_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocaleService.instance.load();
  unawaited(PlanetAssets.preload());
  unawaited(SessionService.migrateToRemoteServerIfNeeded());
  unawaited(SessionService.migrateToTokenSessionIfNeeded());
  unawaited(SessionService.migrateToHttpOnlyCookieIfNeeded());
  runApp(const DaromApp());
  hideWebSplashAfterFirstFrame();
}

class DaromApp extends StatefulWidget {
  const DaromApp({super.key});

  @override
  State<DaromApp> createState() => _DaromAppState();
}

class _DaromAppState extends State<DaromApp> {
  @override
  void initState() {
    super.initState();
    LocaleService.instance.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    LocaleService.instance.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() => setState(() {});

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
      if (path.startsWith('/privacy')) {
        return const PrivacyPolicyScreen();
      }
    }
    return const AuthGate();
  }

  @override
  Widget build(BuildContext context) {
    final locale = LocaleService.instance.locale;

    return MaterialApp(
      title: 'Darom',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        fontFamily: 'NotoSans',
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
