import 'package:flutter/material.dart';

import '../services/auth_api.dart';
import '../services/partners_api.dart';
import '../widgets/auth_form_scroll.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/partner_email_request_card.dart';
import '../widgets/primary_action_button.dart';
import 'sms_screen.dart';

class PartnerRegisterScreen extends StatefulWidget {
  const PartnerRegisterScreen({super.key});

  @override
  State<PartnerRegisterScreen> createState() => _PartnerRegisterScreenState();
}

class _PartnerRegisterScreenState extends State<PartnerRegisterScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _codeFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final GlobalKey _formKey = GlobalKey();
  final AuthApi _authApi = AuthApi();
  final PartnersApi _partnersApi = PartnersApi();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _phoneController.dispose();
    _codeFocus.dispose();
    _phoneFocus.dispose();
    _authApi.dispose();
    _partnersApi.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_isLoading) return;

    final code = normalizePartnerCode(_codeController.text);
    final rawPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    if (code.isEmpty) {
      _showError('Введите код партнёра: 0001–1000');
      return;
    }

    if (rawPhone.length < 10) {
      _showError('Введите корректный номер телефона');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _partnersApi.validateActivationCode(code: code);

      final check = await _authApi.checkPhone(phone: _phoneController.text);
      if (!mounted) return;

      if (check.registered) {
        _showError('Этот номер уже зарегистрирован. Войдите как обычный пользователь.');
        return;
      }

      final result = await _authApi.sendCode(
        phone: check.phone,
        purpose: 'partner',
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SmsScreen(
            phoneNumber: result.phone,
            debugCode: result.debugCode,
            purpose: SmsPurpose.partner,
            partnerActivationCode: code,
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
        title: 'Регистрация партнёра',
        compactSubtitle: 'Код партнёра и номер телефона',
        focusNode: _codeFocus,
        formKey: _formKey,
        leading: const Icon(Icons.handshake_rounded, size: 72, color: Color(0xFF00BFFF)),
        form: Column(
          children: [
            const PartnerEmailRequestCard(),
            const SizedBox(height: 18),
            Text(
              'Если код уже получен — введите ниже',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFFFFFFF).withOpacity(0.65),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF001F3F).withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00BFFF), width: 3),
              ),
              child: TextField(
                controller: _codeController,
                focusNode: _codeFocus,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _phoneFocus.requestFocus(),
                style: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFFFFFFFF),
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.vpn_key, color: Color(0xFF00BFFF)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF001F3F).withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00BFFF), width: 3),
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
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFF00BFFF)),
                ),
              ),
            ),
          ],
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
