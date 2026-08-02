import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/language_picker.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';

/// Проверяет сохранённый вход и показывает главную или онбординг.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<_BootstrapData> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();
  }

  Future<_BootstrapData> _bootstrap() async {
    await LocaleService.instance.load();
    final session = await SessionService.load().catchError((_) => null);
    if (session != null && !LocaleService.instance.hasChosenLocale) {
      await LocaleService.instance.ensureDefaultForExistingUser();
    }
    return _BootstrapData(
      session: session,
      showLanguageWelcome: session == null && !LocaleService.instance.hasChosenLocale,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BootstrapData>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MidnightGlowScreen(
            lightweight: true,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.cyan),
            ),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return const OnboardingScreen();
        }

        if (data.showLanguageWelcome) {
          return const LanguageWelcomeScreen();
        }

        final session = data.session;
        if (session != null) {
          return MainShell(
            userName: session.name,
            phoneNumber: session.phoneNumber,
            userId: session.userId,
          );
        }

        return const OnboardingScreen();
      },
    );
  }
}

class _BootstrapData {
  const _BootstrapData({
    required this.session,
    required this.showLanguageWelcome,
  });

  final SessionData? session;
  final bool showLanguageWelcome;
}
