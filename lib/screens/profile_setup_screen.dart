import 'package:flutter/material.dart';
import 'package:darom_app/theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/users_api.dart';
import '../services/partners_api.dart';
import '../widgets/auth_form_scroll.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/primary_action_button.dart';
import 'pin_setup_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String phoneNumber;
  final String? verificationToken;
  final String? partnerActivationCode;
  final String? initialUserName;
  final bool offerAccepted;
  final bool privacyAccepted;

  const ProfileSetupScreen({
    super.key,
    required this.phoneNumber,
    this.verificationToken,
    this.partnerActivationCode,
    this.initialUserName,
    this.offerAccepted = false,
    this.privacyAccepted = false,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final GlobalKey _formKey = GlobalKey();
  final UsersApi _usersApi = UsersApi();
  bool _isSaving = false;
  bool _showReferralField = false;
  final TextEditingController _referralController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialUserName?.trim();
    if (initial != null && initial.isNotEmpty) {
      _nameController.text = initial;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _referralController.dispose();
    _nameFocus.dispose();
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
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final result = await _usersApi.register(
        phone: widget.phoneNumber,
        name: name,
        partnerActivationCode: widget.partnerActivationCode,
        referralCode: widget.partnerActivationCode == null
            ? _referralController.text.trim()
            : null,
        offerAccepted: widget.offerAccepted,
        privacyConsent: widget.privacyAccepted,
      );

      final pinToken = widget.verificationToken ?? result.verificationToken;
      if (pinToken == null || pinToken.isEmpty) {
        throw UsersApiException('Не удалось продолжить регистрацию. Попробуйте снова.');
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PinSetupScreen(
            phoneNumber: widget.phoneNumber,
            verificationToken: pinToken,
            userName: name,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось сохранить профиль: $error'),
          backgroundColor: AppColors.danger,
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
      child: AuthFormScroll(
        title: 'Как вас зовут?',
        subtitle: widget.partnerActivationCode != null
            ? 'Партнёрский аккаунт — другие увидят только имя'
            : 'Другие пользователи увидят только имя — не номер телефона',
        compactSubtitle: 'Введите имя для профиля',
        focusNode: _nameFocus,
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
                AppColors.textPrimary,
                AppColors.accentDark.withOpacity(0.3),
              ],
            ),
            border: Border.all(color: AppColors.accent, width: 5),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.4),
                blurRadius: 40,
                spreadRadius: 10,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: const Icon(Icons.person, size: 60, color: AppColors.accent),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .animate()
            .scale(duration: 2.seconds, curve: Curves.easeInOut)
            .then()
            .scale(duration: 2.seconds, curve: Curves.easeInOut),
        form: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent, width: 3),
              ),
              child: TextField(
                controller: _nameController,
                focusNode: _nameFocus,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _continue(),
                style: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFFFFFFFF),
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: 'Ваше имя',
                  hintStyle: TextStyle(
                    color: AppColors.textPrimary.withOpacity(0.4),
                    fontSize: 18,
                  ),
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.badge, color: AppColors.accent, size: 24),
                ),
              ),
            ),
            if (widget.partnerActivationCode == null) ...[
              const SizedBox(height: 14),
              PrimaryActionButton(
                label: _showReferralField
                    ? 'Скрыть код блогера'
                    : 'Есть код блогера? Получить расширенные возможности',
                height: 52,
                fontSize: 15,
                borderRadius: 26,
                icon: _showReferralField ? Icons.expand_less : Icons.auto_awesome,
                gradientColors: _showReferralField
                    ? PrimaryActionButton.tealGradient
                    : PrimaryActionButton.warningGradient,
                onPressed: () => setState(() => _showReferralField = !_showReferralField),
              ),
              if (_showReferralField)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.textSecondary, width: 1.5),
                  ),
                  child: TextField(
                    controller: _referralController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color(0xFFFFFFFF),
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.handshake, color: AppColors.textSecondary),
                    ),
                  ),
                ),
            ],
          ],
        ),
        footer: PrimaryActionButton(
          label: 'Продолжить',
          loading: _isSaving,
          onPressed: _continue,
        ),
      ),
    );
  }
}
