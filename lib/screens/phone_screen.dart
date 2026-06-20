import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/auth_api.dart';
import '../widgets/auth_form_scroll.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/primary_action_button.dart';
import 'pin_login_screen.dart';
import 'sms_screen.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  final GlobalKey _formKey = GlobalKey();
  final AuthApi _authApi = AuthApi();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    _authApi.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_isLoading) return;

    final raw = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (raw.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите корректный номер'),
          backgroundColor: Color(0xFFFF5722),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final check = await _authApi.checkPhone(phone: _phoneController.text);

      if (!mounted) return;

      if (check.authMethod == 'pin') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PinLoginScreen(phoneNumber: check.phone),
          ),
        );
        return;
      }

      final purpose = check.authMethod == 'sms_reverify' ? 'reverify' : 'register';
      final result = await _authApi.sendCode(phone: check.phone, purpose: purpose);

      if (!mounted) return;

      if (result.mock && result.debugCode != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Тестовый режим: код ${result.debugCode}'),
            backgroundColor: const Color(0xFF00BFFF),
            duration: const Duration(seconds: 8),
          ),
        );
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SmsScreen(
            phoneNumber: result.phone,
            debugCode: result.debugCode,
            purpose: purpose == 'reverify'
                ? SmsPurpose.reverify
                : SmsPurpose.register,
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MidnightGlowScreen(
      child: AuthFormScroll(
        title: 'Введите номер телефона',
        subtitle:
            'Новым — SMS при регистрации.\n'
            'Повторный вход — пароль из 4 цифр.\n'
            'SMS ещё раз — раз в ~35 дней для подтверждения номера.',
        compactSubtitle: 'Проверьте номер перед продолжением',
        focusNode: _phoneFocus,
        formKey: _formKey,
        leading: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF001F3F),
                const Color(0xFF008C8C).withOpacity(0.3),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF00BFFF),
              width: 5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00BFFF).withOpacity(0.4),
                blurRadius: 40,
                spreadRadius: 10,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: const Icon(
            Icons.phone_android,
            size: 60,
            color: Color(0xFF00BFFF),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .animate()
            .scale(duration: const Duration(seconds: 2), curve: Curves.easeInOut)
            .then()
            .scale(duration: const Duration(seconds: 2), curve: Curves.easeInOut),
        form: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF001F3F).withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00BFFF),
              width: 3,
            ),
          ),
          child: TextField(
            controller: _phoneController,
            focusNode: _phoneFocus,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _continue(),
            style: const TextStyle(
              fontSize: 20,
              color: Color(0xFFFFFFFF),
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: '+7 (___) ___-__-__',
              hintStyle: TextStyle(
                color: const Color(0xFFFFFFFF).withOpacity(0.4),
                fontSize: 18,
              ),
              border: InputBorder.none,
              prefixIcon: const Icon(
                Icons.phone,
                color: Color(0xFF00BFFF),
                size: 24,
              ),
            ),
          ),
        ),
        footer: PrimaryActionButton(
          label: 'Продолжить',
          loading: _isLoading,
          onPressed: _continue,
        ),
      ),
    );
  }
}
