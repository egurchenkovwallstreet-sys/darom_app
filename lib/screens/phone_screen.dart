import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_api.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/primary_action_button.dart';
import 'sms_screen.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final AuthApi _authApi = AuthApi();
  bool _isSending = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _authApi.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_isSending) return;

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

    setState(() => _isSending = true);

    try {
      final result = await _authApi.sendCode(phone: _phoneController.text);

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
      if (mounted) setState(() => _isSending = false);
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
                        .animate(
                          onPlay: (controller) => controller.repeat(reverse: true),
                        )
                        .animate()
                        .scale(
                          duration: const Duration(seconds: 2),
                          curve: Curves.easeInOut,
                        )
                        .then()
                        .scale(
                          duration: const Duration(seconds: 2),
                          curve: Curves.easeInOut,
                        ),
                    
                    const SizedBox(height: 40),
                    
                    const Text(
                      'Введите номер телефона',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFFFFF),
                        shadows: [
                          Shadow(
                            color: Color(0x6600BFFF),
                            offset: Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    )
                        .animate(
                          delay: const Duration(milliseconds: 300),
                        )
                        .fadeIn(duration: const Duration(milliseconds: 800))
                        .slideY(begin: 0.3, end: 0),
                    
                    const SizedBox(height: 15),
                    
                    Text(
                      'Мы отправим SMS с кодом для входа',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFFFFFFFF).withOpacity(0.7),
                      ),
                    )
                        .animate(
                          delay: const Duration(milliseconds: 500),
                        )
                        .fadeIn(duration: const Duration(milliseconds: 800))
                        .slideY(begin: 0.3, end: 0),
                    
                    const SizedBox(height: 40),
                    
                    Container(
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
                        keyboardType: TextInputType.phone,
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
                    )
                        .animate(
                          delay: const Duration(milliseconds: 500),
                        )
                        .fadeIn(duration: const Duration(milliseconds: 800))
                        .slideY(begin: 0.3, end: 0),
                    
                    const SizedBox(height: 40),
                    
                    PrimaryActionButton(
                      label: 'Получить код',
                      loading: _isSending,
                      onPressed: _sendCode,
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}
