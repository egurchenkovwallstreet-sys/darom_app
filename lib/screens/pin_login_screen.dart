import 'package:flutter/material.dart';

import '../services/auth_api.dart';
import '../services/session_service.dart';
import '../services/users_api.dart';
import '../widgets/auth_form_scroll.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/pin_code_fields.dart';
import '../widgets/primary_action_button.dart';
import 'main_shell.dart';
import 'sms_screen.dart';

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
  final UsersApi _usersApi = UsersApi();
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
    _usersApi.dispose();
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
      await SessionService.saveToken(loginResult.sessionToken);
      final user = await _usersApi.fetchProfile(phone: widget.phoneNumber);
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

  Future<void> _resetPinViaSms() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authApi.sendCode(
        phone: widget.phoneNumber,
        purpose: 'reset_pin',
      );
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SmsScreen(
            phoneNumber: result.phone,
            debugCode: result.debugCode,
            purpose: SmsPurpose.resetPin,
            resetPinAfterVerify: true,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showError('$error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              onPressed: _isLoading ? null : _resetPinViaSms,
              child: const Text(
                'Забыли пароль? Подтвердить номер по SMS',
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
