import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:darom_app/screens/admin_gate.dart';
import 'package:darom_app/screens/auth_gate.dart';
import 'package:darom_app/services/locale_service.dart';
import 'package:darom_app/services/planet_assets.dart';
import 'package:darom_app/services/session_service.dart';
import 'package:darom_app/theme/app_colors.dart';
import 'package:darom_app/theme/darom_decorations.dart';
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
        fontFamily: 'Inter',
        fontFamilyFallback: const ['NotoSans', 'system-ui', 'Segoe UI', 'sans-serif'],
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.danger,
          onPrimary: AppColors.white,
          onSurface: AppColors.textPrimary,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w400,
            fontSize: 16,
            letterSpacing: -0.01,
          ),
          bodyMedium: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w400,
            fontSize: 15,
          ),
          titleMedium: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.02,
          ),
          titleLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 24,
            letterSpacing: -0.02,
          ),
          labelLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        ),
        splashFactory: InkRipple.splashFactory,
        highlightColor: const Color(0x0A1B4B8F),
        checkboxTheme: CheckboxThemeData(
          side: const BorderSide(color: AppColors.controlOutline, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          fillColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? AppColors.primary : AppColors.surface,
          ),
          checkColor: const WidgetStatePropertyAll(AppColors.white),
        ),
        dropdownMenuTheme: const DropdownMenuThemeData(
          textStyle: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          contentTextStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          hintStyle: DaromDecorations.fieldHint(),
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          enabledBorder: DaromDecorations.fieldOutlineBorder(),
          focusedBorder: DaromDecorations.fieldOutlineBorder(focused: true),
          border: DaromDecorations.fieldOutlineBorder(),
        ),
        useMaterial3: true,
      ),
      home: _homeWidget(),
    );
  }
}
