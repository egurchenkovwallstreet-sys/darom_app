import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_api.dart';
import '../services/session_service.dart';
import '../widgets/auth_form_scroll.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/pin_code_fields.dart';
import '../widgets/primary_action_button.dart';
import 'main_shell.dart';
import 'reset_pin_verify_screen.dart';

class PinLoginScreen extends StatefulWidget {
  final String phoneNumber;
  final String? infoMessage;

  const PinLoginScreen({
    super.key,
    required this.phoneNumber,
    this.infoMessage,
  });

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  final AuthApi _authApi = AuthApi();
  final FocusNode _pinFocus = FocusNode();
  final GlobalKey _formKey = GlobalKey();
  final _controllers = PinCodeFields.createControllers();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _pinFocus.dispose();
    _authApi.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;

    final pin = PinCodeFields.readCode(_controllers);
    if (pin.length < 4) {
      _showError('Введите 4 цифры пароля');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final loginResult = await _authApi.loginWithPin(phone: widget.phoneNumber, pin: pin);
      final user = User(
        id: loginResult.id,
        name: loginResult.name,
        phoneNumber: loginResult.phone,
        donorLevel: 'новичок',
        rating: 0,
        isFounder: false,
        realPhoneVerified: loginResult.realPhoneVerified,
      );
      await SessionService.saveLogin(user: user, sessionToken: loginResult.sessionToken);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => MainShell(
            userName: user.name,
            phoneNumber: user.phoneNumber,
            userId: user.id,
          ),
        ),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      _showError('$error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPinViaMobileId() async {
    if (_isLoading) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResetPinVerifyScreen(phoneNumber: widget.phoneNumber),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFFFF5722)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MidnightGlowScreen(
      child: AuthFormScroll(
        title: 'Введите пароль',
        subtitle: widget.infoMessage ??
            '4 цифры, которые вы задали при регистрации',
        compactSubtitle: '4 цифры для входа',
        focusNode: _pinFocus,
        formKey: _formKey,
        leading: const Icon(Icons.lock, size: 72, color: Color(0xFF00BFFF)),
        form: Column(
          children: [
            PinCodeFields(
              controllers: _controllers,
              firstFocusNode: _pinFocus,
              obscure: _obscure,
              onCompleted: _login,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              child: Text(
                _obscure ? 'Показать цифры' : 'Скрыть цифры',
                style: const TextStyle(color: Color(0xFF00BFFF)),
              ),
            ),
          ],
        ),
        footer: Column(
          children: [
            PrimaryActionButton(
              label: 'Войти',
              loading: _isLoading,
              onPressed: _login,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading ? null : _resetPinViaMobileId,
              child: const Text(
                'Забыли пароль? Подтвердить номер',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF80DEEA), fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
