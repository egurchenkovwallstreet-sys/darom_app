import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_api.dart';
import '../widgets/auth_form_scroll.dart';
import '../widgets/keyboard_inset_padding.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/pin_code_fields.dart';
import '../widgets/primary_action_button.dart';
import 'pin_setup_screen.dart';

class ResetPinVerifyScreen extends StatefulWidget {
  const ResetPinVerifyScreen({
    super.key,
    required this.phoneNumber,
  });

  final String phoneNumber;

  @override
  State<ResetPinVerifyScreen> createState() => _ResetPinVerifyScreenState();
}

class _ResetPinVerifyScreenState extends State<ResetPinVerifyScreen> {
  final AuthApi _authApi = AuthApi();
  final _codeControllers = PinCodeFields.createControllers();
  final FocusNode _codeFocus = FocusNode();

  Timer? _pollTimer;
  bool _loading = true;
  bool _needsOtp = false;
  String? _sessionToken;
  String? _error;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _startVerify();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _codeFocus.dispose();
    for (final c in _codeControllers) {
      c.dispose();
    }
    _authApi.dispose();
    super.dispose();
  }

  Future<void> _startVerify() async {
    setState(() {
      _loading = true;
      _error = null;
      _statusMessage = 'Отправляем запрос на телефон…';
    });

    try {
      final result = await _authApi.sendResetPinVerify(phone: widget.phoneNumber);
      if (!mounted) return;

      setState(() {
        _loading = false;
        _sessionToken = result.sessionToken;
        _statusMessage = result.hint ??
            'На телефон может прийти push «Подтвердить» от оператора. '
            'Подождите или введите код из SMS.';
      });

      _startPolling(result.sessionToken);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$error';
        _statusMessage = null;
      });
    }
  }

  void _startPolling(String sessionToken) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollOnce(sessionToken));
    _pollOnce(sessionToken);
  }

  Future<void> _pollOnce(String sessionToken) async {
    if (!mounted || _loading) return;

    try {
      final poll = await _authApi.pollResetPinVerifySession(
        phone: widget.phoneNumber,
        sessionToken: sessionToken,
      );
      if (!mounted) return;
      await _handlePollResult(poll, sessionToken);
    } catch (_) {}
  }

  Future<void> _handlePollResult(ActiveVerifyPollResult poll, String sessionToken) async {
    if (poll.failed) {
      _pollTimer?.cancel();
      setState(() {
        _error = 'Подтверждение не удалось. Попробуйте ещё раз.';
        _statusMessage = null;
      });
      return;
    }

    if (poll.verified) {
      _pollTimer?.cancel();
      setState(() => _loading = true);
      try {
        final result = await _authApi.completeResetPinVerifySession(
          phone: widget.phoneNumber,
          sessionToken: sessionToken,
        );
        await _goToPinSetup(result);
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = '$error';
        });
      }
      return;
    }

    if (poll.needsOtp && !_needsOtp) {
      setState(() {
        _needsOtp = true;
        _statusMessage = 'Введите код из SMS (4 цифры)';
      });
      _codeFocus.requestFocus();
    } else if (!_needsOtp) {
      setState(() {
        _statusMessage =
            'На телефон может прийти push «Подтвердить» от оператора. '
            'Подождите или введите код из SMS.';
      });
    }
  }

  Future<void> _confirmCode() async {
    if (_loading || _sessionToken == null) return;

    final code = PinCodeFields.readCode(_codeControllers);
    if (code.length < 4) {
      setState(() => _error = 'Введите 4 цифры из SMS');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _authApi.confirmResetPinVerify(
        phone: widget.phoneNumber,
        code: code,
        sessionToken: _sessionToken!,
      );
      await _goToPinSetup(result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  Future<void> _goToPinSetup(ResetPinVerifyCompleteResult result) async {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PinSetupScreen(
          phoneNumber: result.phone,
          verificationToken: result.verificationToken,
          isPasswordReset: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MidnightGlowScreen(
      child: AuthFormScroll(
        title: 'Восстановление пароля',
        subtitle:
            'Один раз бесплатно подтвердите номер, указанный при регистрации — '
            'так мы убедимся, что аккаунт ваш. Дальше — подсказки на экране '
            '(push «Подтвердить» или SMS-код).\n\n'
            'Номер должен совпадать с регистрационным. '
            'Если он был указан неверно — восстановление может быть невозможно.',
        compactSubtitle: _statusMessage ?? 'Подтверждение номера…',
        focusNode: _codeFocus,
        form: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFFF5722), fontSize: 14),
                ),
              ),
            if (_needsOtp) ...[
              KeyboardInsetPadding(
                child: PinCodeFields(
                  controllers: _codeControllers,
                  firstFocusNode: _codeFocus,
                ),
              ),
              const SizedBox(height: 16),
              PrimaryActionButton(
                label: 'Подтвердить код',
                loading: _loading,
                onPressed: _confirmCode,
              ),
            ] else if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: Color(0xFF00BFFF)),
                ),
              )
            else
              PrimaryActionButton(
                label: 'Попробовать снова',
                onPressed: _startVerify,
              ),
          ],
        ),
      ),
    );
  }
}
