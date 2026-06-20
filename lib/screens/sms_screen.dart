import 'package:flutter/material.dart';

import '../services/auth_api.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/pin_code_fields.dart';
import '../widgets/primary_action_button.dart';
import 'pin_login_screen.dart';
import 'pin_setup_screen.dart';
import 'profile_setup_screen.dart';

enum SmsPurpose { register, reverify }

class SmsScreen extends StatefulWidget {
  final String phoneNumber;
  final String? debugCode;
  final SmsPurpose purpose;
  final bool resetPinAfterVerify;

  const SmsScreen({
    super.key,
    required this.phoneNumber,
    this.debugCode,
    this.purpose = SmsPurpose.register,
    this.resetPinAfterVerify = false,
  });

  @override
  State<SmsScreen> createState() => _SmsScreenState();
}

class _SmsScreenState extends State<SmsScreen> {
  final AuthApi _authApi = AuthApi();
  bool _isVerifying = false;
  final _controllers = PinCodeFields.createControllers();

  @override
  void initState() {
    super.initState();
    if (widget.debugCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Тестовый код: ${widget.debugCode}'),
            backgroundColor: const Color(0xFF00BFFF),
            duration: const Duration(seconds: 10),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
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
      );

      if (!mounted) return;

      if (widget.resetPinAfterVerify) {
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

      if (widget.purpose == SmsPurpose.reverify && result.hasPin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PinLoginScreen(
              phoneNumber: result.phone,
              infoMessage: 'Номер подтверждён. Введите пароль для входа',
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
      final purpose =
          widget.purpose == SmsPurpose.reverify ? 'reverify' : 'register';
      final result = await _authApi.sendCode(
        phone: widget.phoneNumber,
        purpose: purpose,
      );
      if (!mounted) return;
      final msg = result.mock && result.debugCode != null
          ? 'Новый тестовый код: ${result.debugCode}'
          : 'Код отправлен повторно';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: const Color(0xFF00BFFF)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: const Color(0xFFFF5722)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.purpose == SmsPurpose.reverify
        ? 'Подтверждение номера (раз в ~35 дней)'
        : 'Код для регистрации отправлен на ${widget.phoneNumber}';

    return MidnightGlowScreen(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
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
              const SizedBox(height: 40),
              const Text(
                'Введите код из SMS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFFFFF),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFFFFFFFF).withOpacity(0.7),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),
              PinCodeFields(controllers: _controllers, onCompleted: _verify),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _resend,
                child: const Text(
                  'Отправить код ещё раз',
                  style: TextStyle(color: Color(0xFF00BFFF)),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryActionButton(
                label: 'Подтвердить',
                loading: _isVerifying,
                onPressed: _verify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
