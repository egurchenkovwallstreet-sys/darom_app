import 'package:flutter/material.dart';
import 'package:darom_app/theme/app_colors.dart';
import 'package:darom_app/theme/darom_decorations.dart';

import '../l10n/app_localizations.dart';
import '../services/locale_service.dart';
import '../utils/responsive_layout.dart';
import '../widgets/auth_header_icon.dart';
import '../widgets/responsive_page_frame.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/primary_action_button.dart';
import '../screens/onboarding_screen.dart';

/// Первый экран для новых пользователей — выбор языка интерфейса.
class LanguageWelcomeScreen extends StatefulWidget {
  const LanguageWelcomeScreen({super.key});

  @override
  State<LanguageWelcomeScreen> createState() => _LanguageWelcomeScreenState();
}

class _LanguageWelcomeScreenState extends State<LanguageWelcomeScreen> {
  late String _selectedCode;

  @override
  void initState() {
    super.initState();
    _selectedCode = LocaleService.instance.locale.languageCode;
  }

  Future<void> _continue() async {
    await LocaleService.instance.setLocale(Locale(_selectedCode));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return MidnightGlowScreen(
      child: SafeArea(
        child: ResponsivePageFrame(
          maxWidth: ResponsiveLayout.authFormMaxWidth(context),
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const AuthHeaderIcon(Icons.translate_rounded),
              const SizedBox(height: 24),
              Text(
                l10n.languageWelcomeTitle,
                textAlign: TextAlign.center,
                style: DaromDecorations.titleStyle(fontSize: 26),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.languageWelcomeSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 32),
              _LanguageOption(
                label: l10n.languageRussian,
                selected: _selectedCode == 'ru',
                onTap: () => setState(() => _selectedCode = 'ru'),
              ),
              const SizedBox(height: 12),
              _LanguageOption(
                label: l10n.languageEnglish,
                selected: _selectedCode == 'en',
                onTap: () => setState(() => _selectedCode = 'en'),
              ),
              const Spacer(flex: 2),
              PrimaryActionButton(
                label: l10n.continueButton,
                height: 56,
                fontSize: 17,
                onPressed: _continue,
              ),
              const SizedBox(height: 72),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DaromDecorations.buttonRadius),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : AppColors.surface,
            borderRadius: BorderRadius.circular(DaromDecorations.buttonRadius),
            boxShadow: selected ? null : DaromDecorations.cardShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.primary : AppColors.controlOutline,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Диалог смены языка из профиля.
Future<void> showLanguagePickerDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final current = LocaleService.instance.locale.languageCode;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      var selected = current;
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide.none,
            ),
            title: Text(
              l10n.languageTitle,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogLanguageTile(
                  label: l10n.languageRussian,
                  selected: selected == 'ru',
                  onTap: () => setDialogState(() => selected = 'ru'),
                ),
                const SizedBox(height: 8),
                _DialogLanguageTile(
                  label: l10n.languageEnglish,
                  selected: selected == 'en',
                  onTap: () => setDialogState(() => selected = 'en'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel, style: const TextStyle(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () async {
                  await LocaleService.instance.setLocale(Locale(selected));
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.languageChanged),
                        backgroundColor: AppColors.accent,
                      ),
                    );
                  }
                },
                child: Text(
                  l10n.continueButton,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

class _DialogLanguageTile extends StatelessWidget {
  const _DialogLanguageTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide.none,
      ),
      tileColor: AppColors.backgroundStart,
      leading: Icon(
        selected ? Icons.check_circle : Icons.circle_outlined,
        color: selected ? AppColors.accent : AppColors.textSecondary,
      ),
      title: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
    );
  }
}
