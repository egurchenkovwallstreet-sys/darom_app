import 'package:flutter/material.dart';

import '../services/auth_api.dart';
import '../services/session_service.dart';
import '../services/users_api.dart';
import '../widgets/auth_form_scroll.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/pin_code_fields.dart';
import '../widgets/primary_action_button.dart';
import 'main_shell.dart';

class PinSetupScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationToken;
  final String? userName;

  const PinSetupScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationToken,
    this.userName,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final AuthApi _authApi = AuthApi();
  final UsersApi _usersApi = UsersApi();
  final FocusNode _pinFocus = FocusNode();
  final GlobalKey _formKey = GlobalKey();
  final _pinControllers = PinCodeFields.createControllers();
  final _confirmControllers = PinCodeFields.createControllers();
  bool _isSaving = false;
  bool _obscure = true;

  @override
  void dispose() {
    for (final c in _pinControllers) {
      c.dispose();
    }
    for (final c in _confirmControllers) {
      c.dispose();
    }
    _pinFocus.dispose();
    _authApi.dispose();
    _usersApi.dispose();
    super.dispose();
  }

  Future<void> _savePin() async {
    if (_isSaving) return;

    final pin = PinCodeFields.readCode(_pinControllers);
    final confirm = PinCodeFields.readCode(_confirmControllers);

    if (pin.length < 4 || confirm.length < 4) {
      _showError('Введите пароль из 4 цифр два раза');
      return;
    }

    if (pin != confirm) {
      _showError('Пароли не совпадают');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _authApi.setPin(
        phone: widget.phoneNumber,
        pin: pin,
        verificationToken: widget.verificationToken,
      );

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
      _showError('$error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFFFF5722)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.userName != null
        ? '${widget.userName}, введите 4 цифры для входа в приложение'
        : '4 цифры — для входа без SMS';

    return MidnightGlowScreen(
      child: AuthFormScroll(
        title: 'Придумайте пароль',
        subtitle: subtitle,
        compactSubtitle: 'Введите и повторите 4 цифры',
        focusNode: _pinFocus,
        formKey: _formKey,
        leading: const Icon(Icons.lock_outline, size: 72, color: Color(0xFF00BFFF)),
        form: Column(
          children: [
            PinCodeFields(
              controllers: _pinControllers,
              firstFocusNode: _pinFocus,
              obscure: _obscure,
            ),
            const SizedBox(height: 16),
            const Text(
              'Повторите пароль',
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 16),
            ),
            const SizedBox(height: 12),
            PinCodeFields(controllers: _confirmControllers, obscure: _obscure),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              child: Text(
                _obscure ? 'Показать цифры' : 'Скрыть цифры',
                style: const TextStyle(color: Color(0xFF00BFFF)),
              ),
            ),
          ],
        ),
        footer: PrimaryActionButton(
          label: 'Сохранить пароль',
          loading: _isSaving,
          onPressed: _savePin,
        ),
      ),
    );
  }
}
