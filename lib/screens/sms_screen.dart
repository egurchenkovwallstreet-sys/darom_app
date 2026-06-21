import 'package:flutter/material.dart';

import '../services/auth_api.dart';
import '../widgets/auth_form_scroll.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/pin_code_fields.dart';
import '../widgets/primary_action_button.dart';
import 'pin_setup_screen.dart';
import 'profile_setup_screen.dart';

enum SmsPurpose { register, resetPin, partner }

class SmsScreen extends StatefulWidget {
  final String phoneNumber;
  final String? debugCode;
  final SmsPurpose purpose;
  final bool resetPinAfterVerify;
  final String? partnerActivationCode;

  const SmsScreen({
    super.key,
    required this.phoneNumber,
    this.debugCode,
    this.purpose = SmsPurpose.register,
    this.resetPinAfterVerify = false,
    this.partnerActivationCode,
  });

  @override
  State<SmsScreen> createState() => _SmsScreenState();
}

class _SmsScreenState extends State<SmsScreen> {
  final AuthApi _authApi = AuthApi();
  final FocusNode _codeFocus = FocusNode();
  final GlobalKey _formKey = GlobalKey();
  bool _isVerifying = false;
  String? _debugCode;
  final _controllers = PinCodeFields.createControllers();

  String get _apiPurpose {
    switch (widget.purpose) {
      case SmsPurpose.partner:
        return 'partner';
      case SmsPurpose.resetPin:
        return 'reset_pin';
      case SmsPurpose.register:
        return 'register';
    }
  }

  @override
  void initState() {
    super.initState();
    _debugCode = widget.debugCode;
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _codeFocus.dispose();
    _authApi.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_isVerifying) return;

    final code = PinCodeFields.readCode(_controllers);
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите 4 цифры кода'),
          backgroundColor: Color(0xFFFF5722),
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final result = await _authApi.verifyCode(
        phone: widget.phoneNumber,
        code: code,
        purpose: _apiPurpose,
      );

      if (!mounted) return;

      if (widget.resetPinAfterVerify || widget.purpose == SmsPurpose.resetPin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PinSetupScreen(
              phoneNumber: result.phone,
              verificationToken: result.verificationToken,
              userName: result.userName,
            ),
          ),
        );
        return;
      }

      final needsProfile = result.isNewUser ||
          (result.userName == null || result.userName!.trim().length < 2);

      if (needsProfile) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileSetupScreen(
              phoneNumber: result.phone,
              verificationToken: result.verificationToken,
              partnerActivationCode: widget.partnerActivationCode,
            ),
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PinSetupScreen(
            phoneNumber: result.phone,
            verificationToken: result.verificationToken,
            userName: result.userName,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$error'),
          backgroundColor: const Color(0xFFFF5722),
        ),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    try {
      final result = await _authApi.sendCode(
        phone: widget.phoneNumber,
        purpose: _apiPurpose,
      );
      if (!mounted) return;
      setState(() => _debugCode = result.debugCode);
      if (result.debugCode != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Новый тестовый код: ${result.debugCode}'),
            backgroundColor: const Color(0xFF00BFFF),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Код отправлен повторно'),
            backgroundColor: Color(0xFF00BFFF),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: const Color(0xFFFF5722)),
      );
    }
  }

  String get _subtitle {
    switch (widget.purpose) {
      case SmsPurpose.partner:
        return 'Подтверждение номера партнёра: ${widget.phoneNumber}';
      case SmsPurpose.resetPin:
        return 'Код для смены пароля отправлен на ${widget.phoneNumber}';
      case SmsPurpose.register:
        return 'Тестовый код для регистрации (номер ${widget.phoneNumber})';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MidnightGlowScreen(
      child: AuthFormScroll(
        title: 'Введите код из SMS',
        subtitle: _subtitle,
        compactSubtitle: 'Введите 4 цифры из сообщения',
        focusNode: _codeFocus,
        formKey: _formKey,
        leading: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF001F3F),
                const Color(0xFF008C8C).withOpacity(0.3),
              ],
            ),
            border: Border.all(color: const Color(0xFF00BFFF), width: 5),
          ),
          child: const Icon(Icons.sms, size: 60, color: Color(0xFF00BFFF)),
        ),
        form: Column(
          children: [
            if (_debugCode != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF004466),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00BFFF), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00BFFF).withOpacity(0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Тестовый код регистрации',
                      style: TextStyle(
                        color: Color(0xFF80DEEA),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _debugCode!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            PinCodeFields(
              controllers: _controllers,
              firstFocusNode: _codeFocus,
              onCompleted: _verify,
            ),
          ],
        ),
        footer: Column(
          children: [
            TextButton(
              onPressed: _resend,
              child: const Text(
                'Отправить код ещё раз',
                style: TextStyle(color: Color(0xFF00BFFF)),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryActionButton(
              label: 'Подтвердить',
              loading: _isVerifying,
              onPressed: _verify,
            ),
          ],
        ),
      ),
    );
  }
}
