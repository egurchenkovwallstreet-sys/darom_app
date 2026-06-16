import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_api.dart';
import '../widgets/midnight_glow_screen.dart';
import 'profile_setup_screen.dart';

class SmsScreen extends StatefulWidget {
  final String phoneNumber;
  final String? debugCode;

  const SmsScreen({
    super.key,
    required this.phoneNumber,
    this.debugCode,
  });

  @override
  State<SmsScreen> createState() => _SmsScreenState();
}

class _SmsScreenState extends State<SmsScreen> {
  final AuthApi _authApi = AuthApi();
  bool _isButtonPressed = false;
  bool _isVerifying = false;
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());

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
    for (var controller in _controllers) {
      controller.dispose();
    }
    _authApi.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_isVerifying) return;

    final code = _controllers.map((c) => c.text).join();
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
      final phone = await _authApi.verifyCode(
        phone: widget.phoneNumber,
        code: code,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileSetupScreen(phoneNumber: phone),
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
      final result = await _authApi.sendCode(phone: widget.phoneNumber);
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
                      'Код отправлен на ${widget.phoneNumber}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFFFFFFFF).withOpacity(0.7),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        return Container(
                          width: 60,
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFF001F3F).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: const Color(0xFF00BFFF), width: 2),
                          ),
                          child: TextField(
                            controller: _controllers[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              color: Color(0xFFFFFFFF),
                              fontWeight: FontWeight.bold,
                            ),
                            maxLength: 1,
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && index < 3) {
                                FocusScope.of(context).nextFocus();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    
                    const SizedBox(height: 24),

                    TextButton(
                      onPressed: _resend,
                      child: const Text(
                        'Отправить код ещё раз',
                        style: TextStyle(color: Color(0xFF00BFFF)),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    GestureDetector(
                      onTapDown: (_) => setState(() => _isButtonPressed = true),
                      onTapUp: (_) {
                        setState(() => _isButtonPressed = false);
                        _verify();
                      },
                      onTapCancel: () => setState(() => _isButtonPressed = false),
                      child: AnimatedScale(
                        scale: _isButtonPressed ? 1.08 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          width: double.infinity,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF00BFFF),
                                Color(0xFF008C8C),
                                Color(0xFF001F3F),
                              ],
                            ),
                          ),
                          child: Center(
                            child: _isVerifying
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Подтвердить',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFFFFFF),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}
