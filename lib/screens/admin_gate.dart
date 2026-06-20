import 'package:flutter/material.dart';

import '../services/admin_session_service.dart';
import '../theme/app_colors.dart';
import '../widgets/midnight_glow_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_login_screen.dart';

class AdminGate extends StatefulWidget {
  const AdminGate({super.key});

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  late final Future<AdminSessionData?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = AdminSessionService.load();
  }

  void _openDashboard(AdminSessionData session) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AdminDashboardScreen(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminSessionData?>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MidnightGlowScreen(
            child: Center(child: CircularProgressIndicator(color: AppColors.cyan)),
          );
        }

        final session = snapshot.data;
        if (session != null) {
          return AdminDashboardScreen(session: session);
        }

        return AdminLoginScreen(onLoggedIn: _openDashboard);
      },
    );
  }
}
