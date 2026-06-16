import 'package:flutter/material.dart';

import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../widgets/midnight_glow_screen.dart';
import 'home_screen.dart';
import 'main_shell.dart';
import 'onboarding_screen.dart';

/// Проверяет сохранённый вход и показывает главную или онбординг.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<SessionData?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = SessionService.load().catchError((_) => null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SessionData?>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MidnightGlowScreen(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.cyan),
            ),
          );
        }

        final session = snapshot.data;
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
