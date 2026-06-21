import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/admin_api.dart';
import '../services/admin_session_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_form_scroll.dart';
import '../widgets/midnight_glow_screen.dart';
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

  bool _loading = false;
  bool _codesSent = false;
  String? _normalizedPhone;
  String? _emailHint;

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
    _phoneController.dispose();
    _smsController.dispose();
    _emailController.dispose();
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
      });

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
      } else if (!result.smsMock) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: AppColors.red),
      );
    }
  }

  Future<void> _verify() async {
    if (_loading || _normalizedPhone == null) return;
    setState(() => _loading = true);
    try {
      final result = await _api.verifyLogin(
        phone: _normalizedPhone!,
        smsCode: _smsController.text.trim(),
        emailCode: _emailController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return MidnightGlowScreen(
      child: AuthFormScroll(
        title: 'Админ-панель',
        subtitle: _codesSent
            ? 'Введите код из SMS (4 цифры) и код с ${_emailHint ?? 'почты'}'
            : _fromProfile
                ? 'Подтвердите доступ: SMS на телефон + код с почты'
                : 'Двухфакторный вход: SMS на телефон + код с почты',
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
            ],
            const SizedBox(height: 24),
            PrimaryActionButton(
              label: _codesSent ? 'Войти' : 'Получить коды',
              loading: _loading,
              onPressed: _loading ? null : (_codesSent ? _verify : _requestCodes),
            ),
          ],
        ),
      ),
    );
  }
}
