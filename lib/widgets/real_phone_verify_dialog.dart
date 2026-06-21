import 'package:flutter/material.dart';

import '../services/auth_api.dart';
import '../services/session_service.dart';
import '../services/users_api.dart';
import 'pin_code_fields.dart';
import 'primary_action_button.dart';

/// Диалог одноразового подтверждения реального номера (SMS).
/// Возвращает новый номер телефона, если подтверждение успешно.
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

  bool _codeSent = false;
  bool _loading = false;
  bool _success = false;
  String? _debugCode;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.phoneNumber;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    _codeFocus.dispose();
    for (final c in _codeControllers) {
      c.dispose();
    }
    super.dispose();
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
    });

    try {
      final result = await widget.authApi.sendActiveVerifyCode(
        accountPhone: widget.phoneNumber,
        verifyPhone: _phoneController.text,
      );

      if (!mounted) return;

      setState(() {
        _codeSent = true;
        _debugCode = result.debugCode;
        _loading = false;
      });

      _codeFocus.requestFocus();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
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
      );

      final profile = await widget.usersApi.fetchProfile(phone: result.phone);
      await SessionService.save(profile);

      if (!mounted) return;

      setState(() {
        _success = true;
        _loading = false;
      });

      await Future<void>.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      Navigator.pop(context, result.phone);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF001F3F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF00BFFF), width: 2),
      ),
      title: Text(
        _success ? 'Готово!' : 'Подтверждение номера',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                'актуальный номер телефона. Он не показывается другим пользователям — '
                'это нужно для безопасности активных участников.',
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.45),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                focusNode: _phoneFocus,
                enabled: !_codeSent && !_loading,
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
                    borderSide: BorderSide(color: const Color(0xFF00BFFF).withOpacity(0.5)),
                  ),
                ),
              ),
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
                        'Тестовый код (пока SMS не подключены)',
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
              if (_codeSent) ...[
                const SizedBox(height: 16),
                const Text(
                  'Код из SMS (4 цифры)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                PinCodeFields(
                  controllers: _codeControllers,
                  firstFocusNode: _codeFocus,
                  onCompleted: _confirmCode,
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
            ],
          ],
        ),
      ),
      actions: _success
          ? []
          : [
              TextButton(
                onPressed: _loading ? null : () => Navigator.pop(context),
                child: const Text('Отмена', style: TextStyle(color: Color(0xFF80DEEA))),
              ),
              if (!_codeSent)
                PrimaryActionButton(
                  label: 'Отправить SMS',
                  loading: _loading,
                  height: 44,
                  fontSize: 15,
                  borderRadius: 22,
                  onPressed: _sendCode,
                )
              else
                PrimaryActionButton(
                  label: 'Подтвердить',
                  loading: _loading,
                  height: 44,
                  fontSize: 15,
                  borderRadius: 22,
                  onPressed: _confirmCode,
                ),
            ],
    );
  }
}
