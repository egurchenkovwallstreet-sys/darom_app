import 'package:flutter/material.dart';

import '../services/auth_api.dart';
import '../services/session_service.dart';
import '../services/users_api.dart';
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
  final _controllers = PinCodeFields.createControllers();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
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
      await _authApi.loginWithPin(phone: widget.phoneNumber, pin: pin);
      final user = await _usersApi.fetchProfile(phone: widget.phoneNumber);
      await SessionService.save(user);

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
      final message = '$error';
      if (message.contains('Подтвердите номер по SMS')) {
        _showError(message);
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        _goToSmsReverify();
        return;
      }
      _showError(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _goToSmsReverify() async {
    try {
      final result = await _authApi.sendCode(
        phone: widget.phoneNumber,
        purpose: 'reverify',
      );
      if (!mounted) return;

      if (result.mock && result.debugCode != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Тестовый код: ${result.debugCode}'),
            backgroundColor: const Color(0xFF00BFFF),
            duration: const Duration(seconds: 8),
          ),
        );
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SmsScreen(
            phoneNumber: result.phone,
            debugCode: result.debugCode,
            purpose: SmsPurpose.reverify,
            resetPinAfterVerify: true,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showError('$error');
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
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.lock, size: 72, color: Color(0xFF00BFFF)),
              const SizedBox(height: 24),
              const Text(
                'Введите пароль',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFFFFF),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.infoMessage ??
                    '4 цифры, которые вы задали при регистрации',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFFFFFFFF).withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 36),
              PinCodeFields(
                controllers: _controllers,
                obscure: _obscure,
                onCompleted: _login,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                child: Text(
                  _obscure ? 'Показать цифры' : 'Скрыть цифры',
                  style: const TextStyle(color: Color(0xFF00BFFF)),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryActionButton(
                label: 'Войти',
                loading: _isLoading,
                onPressed: _login,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading ? null : _goToSmsReverify,
                child: const Text(
                  'Забыли пароль? Подтвердить номер по SMS',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF80DEEA), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
