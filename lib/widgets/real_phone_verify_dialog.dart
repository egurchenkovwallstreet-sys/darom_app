import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_api.dart';
import '../services/session_service.dart';
import '../services/users_api.dart';
import 'keyboard_inset_padding.dart';
import 'pin_code_fields.dart';
import 'primary_action_button.dart';

/// Диалог одноразового подтверждения реального номера (SMS Aero Mobile ID или SMS).
Future<String?> showRealPhoneVerifyDialog(
  BuildContext context, {
  required String phoneNumber,
  AuthApi? authApi,
  UsersApi? usersApi,
}) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _RealPhoneVerifyDialog(
      phoneNumber: phoneNumber,
      authApi: authApi ?? AuthApi(),
      usersApi: usersApi ?? UsersApi(),
    ),
  );
}

class _RealPhoneVerifyDialog extends StatefulWidget {
  const _RealPhoneVerifyDialog({
    required this.phoneNumber,
    required this.authApi,
    required this.usersApi,
  });

  final String phoneNumber;
  final AuthApi authApi;
  final UsersApi usersApi;

  @override
  State<_RealPhoneVerifyDialog> createState() => _RealPhoneVerifyDialogState();
}

class _RealPhoneVerifyDialogState extends State<_RealPhoneVerifyDialog> {
  final TextEditingController _phoneController = TextEditingController();
  final _codeControllers = PinCodeFields.createControllers();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _codeFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _phoneFieldKey = GlobalKey();
  final GlobalKey _codeFieldKey = GlobalKey();

  Timer? _pollTimer;
  bool _started = false;
  bool _loading = false;
  bool _success = false;
  bool _mobileIdMode = false;
  bool _needsOtp = false;
  String? _debugCode;
  String? _sessionToken;
  String? _error;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.phoneNumber;
    _phoneFocus.addListener(_onPhoneFocus);
    _codeFocus.addListener(_onCodeFocus);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _phoneFocus.removeListener(_onPhoneFocus);
    _codeFocus.removeListener(_onCodeFocus);
    _phoneController.dispose();
    _phoneFocus.dispose();
    _codeFocus.dispose();
    _scrollController.dispose();
    for (final c in _codeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onPhoneFocus() {
    if (_phoneFocus.hasFocus) _scrollToKey(_phoneFieldKey);
  }

  void _onCodeFocus() {
    if (_codeFocus.hasFocus) _scrollToKey(_codeFieldKey);
  }

  void _scrollToKey(GlobalKey key) {
    for (final delay in [100, 300, 500]) {
      Future<void>.delayed(Duration(milliseconds: delay), () {
        if (!mounted) return;
        final target = key.currentContext;
        if (target == null) return;
        Scrollable.ensureVisible(
          target,
          alignment: 0.2,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendCode() async {
    if (_loading) return;

    final raw = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (raw.length < 10) {
      setState(() => _error = 'Введите корректный номер телефона');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _statusMessage = null;
    });

    try {
      final result = await widget.authApi.sendActiveVerifyCode(
        accountPhone: widget.phoneNumber,
        verifyPhone: _phoneController.text,
      );

      if (!mounted) return;

      setState(() {
        _started = true;
        _mobileIdMode = result.isMobileId;
        _sessionToken = result.sessionToken;
        _debugCode = result.debugCode;
        _loading = false;
        _statusMessage = result.isMobileId
            ? (result.hint ??
                'На телефон может прийти запрос «Подтвердить» или SMS с кодом.')
            : null;
        _needsOtp = !result.isMobileId;
      });

      if (result.isMobileId && result.sessionToken != null) {
        _startPolling(result.sessionToken!);
      } else if (!result.isMobileId) {
        _codeFocus.requestFocus();
        _scrollToKey(_codeFieldKey);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  void _startPolling(String sessionToken) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollOnce(sessionToken));
    _pollOnce(sessionToken);
  }

  Future<void> _pollOnce(String sessionToken) async {
    if (!mounted || _loading || _success) return;

    try {
      final poll = await widget.authApi.pollActiveVerifySession(
        accountPhone: widget.phoneNumber,
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
        final result = await widget.authApi.completeActiveVerifySession(
          accountPhone: widget.phoneNumber,
          sessionToken: sessionToken,
        );
        await _finishSuccess(result.phone);
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
      _scrollToKey(_codeFieldKey);
    } else if (!_needsOtp) {
      setState(() {
        _statusMessage =
            'Ожидаем подтверждение на телефоне… Можно нажать «Подтвердить» в уведомлении.';
      });
    }
  }

  Future<void> _confirmCode() async {
    if (_loading) return;

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
      final result = await widget.authApi.confirmActiveVerify(
        accountPhone: widget.phoneNumber,
        verifyPhone: _phoneController.text,
        code: code,
        sessionToken: _mobileIdMode ? _sessionToken : null,
      );
      await _finishSuccess(result.phone);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  Future<void> _finishSuccess(String phone) async {
    final profile = await widget.usersApi.fetchProfile(phone: phone);
    await SessionService.save(profile);

    if (!mounted) return;

    setState(() {
      _success = true;
      _loading = false;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    Navigator.pop(context, phone);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;
    final showOtp = _started && (_needsOtp || !_mobileIdMode);

    return Dialog(
      backgroundColor: const Color(0xFF001F3F),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF00BFFF), width: 2),
      ),
      child: KeyboardInsetPadding(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _success ? 'Готово!' : 'Подтверждение номера',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 16),
                if (_success) ...[
                  const Icon(Icons.check_circle, color: Color(0xFF00BFFF), size: 56),
                  const SizedBox(height: 12),
                  const Text(
                    'Теперь вам доступны все функции приложения!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
                  ),
                ] else ...[
                  const Text(
                    'Чтобы размещать объявления и писать в чате, один раз подтвердите '
                    'актуальный номер. Стоимость ~3–6 ₽ (Mobile ID), не обычное SMS.',
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.45),
                  ),
                  const SizedBox(height: 16),
                  KeyedSubtree(
                    key: _phoneFieldKey,
                    child: TextField(
                      controller: _phoneController,
                      focusNode: _phoneFocus,
                      enabled: !_started && !_loading,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      decoration: InputDecoration(
                        labelText: 'Номер телефона',
                        labelStyle: const TextStyle(color: Color(0xFF80DEEA)),
                        filled: true,
                        fillColor: const Color(0xFF00152A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF00BFFF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: const Color(0xFF00BFFF).withOpacity(0.5)),
                        ),
                      ),
                    ),
                  ),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _statusMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF80DEEA), fontSize: 14, height: 1.4),
                    ),
                  ],
                  if (_debugCode != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF004466),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF00BFFF), width: 2),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Тестовый код (режим SMS_MOCK)',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF80DEEA), fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _debugCode!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (showOtp) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Код из SMS',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    KeyedSubtree(
                      key: _codeFieldKey,
                      child: PinCodeFields(
                        controllers: _codeControllers,
                        firstFocusNode: _codeFocus,
                        onCompleted: _confirmCode,
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFFF5722), fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _loading ? null : () => Navigator.pop(context),
                        child: const Text(
                          'Отмена',
                          style: TextStyle(color: Color(0xFF80DEEA)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: !_started
                            ? PrimaryActionButton(
                                label: 'Подтвердить номер',
                                loading: _loading,
                                height: 44,
                                fontSize: 15,
                                borderRadius: 22,
                                onPressed: _sendCode,
                              )
                            : showOtp
                                ? PrimaryActionButton(
                                    label: 'Ввести код',
                                    loading: _loading,
                                    height: 44,
                                    fontSize: 15,
                                    borderRadius: 22,
                                    onPressed: _confirmCode,
                                  )
                                : PrimaryActionButton(
                                    label: 'Ждём телефон…',
                                    loading: true,
                                    height: 44,
                                    fontSize: 15,
                                    borderRadius: 22,
                                    onPressed: null,
                                  ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
