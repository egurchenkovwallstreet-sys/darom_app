import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/admin_api.dart';
import '../services/admin_session_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_form_scroll.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/pin_code_fields.dart';
import '../widgets/primary_action_button.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({
    super.key,
    required this.onLoggedIn,
    this.prefilledPhone,
    this.showBackButton = false,
  });

  final void Function(AdminSessionData session) onLoggedIn;

  /// Если задан — телефон уже известен (вход из профиля админа).
  final String? prefilledPhone;
  final bool showBackButton;

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final AdminApi _api = AdminApi();
  late final TextEditingController _phoneController;
  final TextEditingController _smsController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final _mobileIdCodeControllers = PinCodeFields.createControllers();
  final FocusNode _mobileIdCodeFocus = FocusNode();

  Timer? _pollTimer;
  bool _loading = false;
  bool _codesSent = false;
  bool _mobileIdMode = false;
  bool _phoneVerified = false;
  bool _needsOtp = false;
  String? _normalizedPhone;
  String? _emailHint;
  String? _sessionToken;
  String? _statusMessage;

  bool get _fromProfile => widget.prefilledPhone != null && widget.prefilledPhone!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(
      text: _fromProfile ? widget.prefilledPhone! : '+7',
    );
    if (_fromProfile) {
      _normalizedPhone = widget.prefilledPhone;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _phoneController.dispose();
    _smsController.dispose();
    _emailController.dispose();
    _mobileIdCodeFocus.dispose();
    for (final c in _mobileIdCodeControllers) {
      c.dispose();
    }
    _api.dispose();
    super.dispose();
  }

  Future<void> _requestCodes() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final phone = _fromProfile ? widget.prefilledPhone! : _phoneController.text;
      final result = await _api.startLogin(phone: phone);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _codesSent = true;
        _normalizedPhone = result.phone;
        _emailHint = result.emailHint;
        _mobileIdMode = result.isMobileId;
        _sessionToken = result.sessionToken;
        _phoneVerified = false;
        _needsOtp = false;
        _statusMessage = result.isMobileId
            ? (result.hint ??
                'На телефон может прийти запрос «Подтвердить» или SMS с кодом.')
            : null;
      });

      if (result.isEmailSmsFallback) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.emailDeliveryHint ??
                  'Код с почты отправлен SMS на ваш admin-номер (SMTP заблокирован).',
            ),
            backgroundColor: AppColors.cyan,
            duration: const Duration(seconds: 10),
          ),
        );
      }

      final hints = <String>[];
      if (result.smsMock && result.smsDebugCode != null) {
        hints.add('SMS: ${result.smsDebugCode}');
      }
      if (result.emailMock && result.emailDebugCode != null) {
        hints.add('Почта: ${result.emailDebugCode}');
      }
      if (hints.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Тест: ${hints.join(' | ')}'),
            backgroundColor: AppColors.cyan,
            duration: const Duration(seconds: 12),
          ),
        );
      }

      if (result.isMobileId && result.sessionToken != null) {
        _startPolling(result.sessionToken!);
      } else if (!result.smsMock && !result.isMobileId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Код из SMS отправлен на ваш номер'),
            backgroundColor: AppColors.cyan,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      final message = error is TimeoutException
          ? 'Сервер долго отвечает (почта + Mobile ID). Подождите минуту и нажмите «Получить коды» ещё раз — письмо могло уже уйти.'
          : '$error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.red),
      );
    }
  }

  void _startPolling(String sessionToken) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollOnce(sessionToken));
    _pollOnce(sessionToken);
  }

  Future<void> _pollOnce(String sessionToken) async {
    if (!mounted || _loading || _phoneVerified || _normalizedPhone == null) return;

    try {
      final poll = await _api.pollMobileId(
        phone: _normalizedPhone!,
        sessionToken: sessionToken,
      );
      if (!mounted || _phoneVerified) return;
      await _handlePollResult(poll, sessionToken);
    } catch (_) {}
  }

  Future<void> _handlePollResult(AdminMobileIdPollResult poll, String sessionToken) async {
    if (poll.failed) {
      _pollTimer?.cancel();
      setState(() {
        _statusMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Подтверждение не удалось. Запросите вход заново.'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    if (poll.verified) {
      _pollTimer?.cancel();
      setState(() => _loading = true);
      try {
        await _api.completeMobileIdPhone(
          phone: _normalizedPhone!,
          sessionToken: sessionToken,
        );
        if (!mounted) return;
        setState(() {
          _loading = false;
          _phoneVerified = true;
          _statusMessage = 'Телефон подтверждён. Введите код с почты.';
        });
      } catch (error) {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'), backgroundColor: AppColors.red),
        );
      }
      return;
    }

    if (poll.needsOtp && !_needsOtp) {
      setState(() {
        _needsOtp = true;
        _statusMessage = 'Введите код из SMS (4 цифры)';
      });
      _mobileIdCodeFocus.requestFocus();
    } else if (!_needsOtp) {
      setState(() {
        _statusMessage =
            'Ожидаем подтверждение на телефоне… Можно нажать «Подтвердить» в уведомлении.';
      });
    }
  }

  Future<void> _confirmMobileIdOtp() async {
    if (_loading || _sessionToken == null || _normalizedPhone == null) return;

    final code = PinCodeFields.readCode(_mobileIdCodeControllers);
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите 4 цифры из SMS'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _api.confirmMobileIdOtp(
        phone: _normalizedPhone!,
        sessionToken: _sessionToken!,
        code: code,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _phoneVerified = true;
        _statusMessage = 'Телефон подтверждён. Введите код с почты.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: AppColors.red),
      );
    }
  }

  Future<void> _verify() async {
    if (_loading || _normalizedPhone == null) return;

    if (_mobileIdMode && !_phoneVerified) {
      if (_needsOtp) {
        await _confirmMobileIdOtp();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сначала подтвердите телефон через Mobile ID'),
            backgroundColor: AppColors.red,
          ),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await _api.verifyLogin(
        phone: _normalizedPhone!,
        smsCode: _mobileIdMode ? null : _smsController.text.trim(),
        emailCode: _emailController.text.trim(),
        sessionToken: _mobileIdMode ? _sessionToken : null,
      );
      final session = AdminSessionData(token: result.token, role: result.role);
      await AdminSessionService.save(token: result.token, role: result.role);
      if (!mounted) return;
      setState(() => _loading = false);
      widget.onLoggedIn(session);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: AppColors.red),
      );
    }
  }

  String get _subtitle {
    if (!_codesSent) {
      return _fromProfile
          ? 'Подтвердите доступ: Mobile ID на телефон + код с почты'
          : 'Двухфакторный вход: Mobile ID на телефон + код с почты';
    }
    if (_mobileIdMode) {
      if (_phoneVerified) {
        return 'Телефон подтверждён. Введите код с ${_emailHint ?? 'почты'}';
      }
      return _statusMessage ?? 'Подтвердите телефон, затем введите код с ${_emailHint ?? 'почты'}';
    }
    return 'Введите код из SMS (4 цифры) и код с ${_emailHint ?? 'почты'}';
  }

  String get _primaryLabel {
    if (!_codesSent) return 'Получить коды';
    if (_mobileIdMode && _needsOtp && !_phoneVerified) return 'Подтвердить SMS-код';
    return 'Войти';
  }

  @override
  Widget build(BuildContext context) {
    return MidnightGlowScreen(
      child: AuthFormScroll(
        title: 'Админ-панель',
        subtitle: _subtitle,
        leading: widget.showBackButton
            ? Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: AppColors.cyan),
                ),
              )
            : null,
        form: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_fromProfile && !_codesSent)
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Телефон администратора',
                  labelStyle: TextStyle(color: AppColors.cyan),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.cyan, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.cyan, width: 2),
                  ),
                ),
              )
            else if (_codesSent) ...[
              if (_mobileIdMode && _needsOtp && !_phoneVerified) ...[
                PinCodeFields(
                  controllers: _mobileIdCodeControllers,
                  firstFocusNode: _mobileIdCodeFocus,
                ),
                const SizedBox(height: 12),
              ],
              if (!_mobileIdMode) ...[
                TextField(
                  controller: _smsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Код из SMS (4 цифры)',
                    counterText: '',
                    labelStyle: TextStyle(color: AppColors.cyan),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.cyan, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.cyan, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (!_mobileIdMode || _phoneVerified || _needsOtp)
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 6,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Код с почты',
                    counterText: '',
                    labelStyle: TextStyle(color: AppColors.cyan),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.cyan, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.cyan, width: 2),
                    ),
                  ),
                ),
              if (_mobileIdMode && !_phoneVerified && !_needsOtp)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _statusMessage ?? 'Ожидаем подтверждение на телефоне…',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      height: 1.4,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 24),
            PrimaryActionButton(
              label: _primaryLabel,
              loading: _loading,
              onPressed: _loading ? null : (_codesSent ? _verify : _requestCodes),
            ),
          ],
        ),
      ),
    );
  }
}
