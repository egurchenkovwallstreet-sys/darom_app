import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/users_api.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/primary_action_button.dart';
import 'pin_setup_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationToken;

  const ProfileSetupScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationToken,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final UsersApi _usersApi = UsersApi();
  bool _isAvatarPressed = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usersApi.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите имя (минимум 2 символа)'),
          backgroundColor: Color(0xFFFF5722),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _usersApi.register(
        phone: widget.phoneNumber,
        name: name,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PinSetupScreen(
            phoneNumber: widget.phoneNumber,
            verificationToken: widget.verificationToken,
            userName: name,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось сохранить профиль: $error'),
          backgroundColor: const Color(0xFFFF5722),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
                  border: Border.all(color: const Color(0xFF00BFFF), width: 5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00BFFF).withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 10,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: const Icon(Icons.person, size: 60, color: Color(0xFF00BFFF)),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .animate()
                  .scale(duration: 2.seconds, curve: Curves.easeInOut)
                  .then()
                  .scale(duration: 2.seconds, curve: Curves.easeInOut),
              const SizedBox(height: 40),
              Text(
                'Как вас зовут?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFFFFF),
                  shadows: [
                    Shadow(
                      color: const Color(0xFF00BFFF).withOpacity(0.6),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ).animate(delay: 300.ms).fadeIn(duration: 800.ms).slideY(begin: 0.3, end: 0),
              const SizedBox(height: 15),
              Text(
                'Другие пользователи увидят только имя — не номер телефона',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFFFFFFFF).withOpacity(0.7),
                  height: 1.4,
                ),
              ).animate(delay: 500.ms).fadeIn(duration: 800.ms).slideY(begin: 0.3, end: 0),
              const SizedBox(height: 30),
              GestureDetector(
                onTapDown: (_) => setState(() => _isAvatarPressed = true),
                onTapUp: (_) {
                  setState(() => _isAvatarPressed = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Загрузка аватара — скоро'),
                      backgroundColor: Color(0xFF00BFFF),
                    ),
                  );
                },
                onTapCancel: () => setState(() => _isAvatarPressed = false),
                child: AnimatedScale(
                  scale: _isAvatarPressed ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF001F3F).withOpacity(0.85),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00BFFF), width: 2),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, color: Color(0xFF00BFFF), size: 28),
                        SizedBox(height: 4),
                        Text(
                          'Фото',
                          style: TextStyle(color: Color(0xFF00BFFF), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate(delay: 550.ms).fadeIn(duration: 800.ms).scale(begin: const Offset(0.9, 0.9)),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF001F3F).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00BFFF), width: 3),
                ),
                child: TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Color(0xFFFFFFFF),
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ваше имя',
                    hintStyle: TextStyle(
                      color: const Color(0xFFFFFFFF).withOpacity(0.4),
                      fontSize: 18,
                    ),
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.badge, color: Color(0xFF00BFFF), size: 24),
                  ),
                ),
              ).animate(delay: 600.ms).fadeIn(duration: 800.ms).slideY(begin: 0.3, end: 0),
              const SizedBox(height: 40),
              PrimaryActionButton(
                label: 'Продолжить',
                loading: _isSaving,
                onPressed: _continue,
              )
                  .animate(delay: 700.ms)
                  .fadeIn(duration: 800.ms)
                  .slideY(begin: 0.3, end: 0),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
