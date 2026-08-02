import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/locale_service.dart';
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Text(
                l10n.languageWelcomeTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.languageWelcomeSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              const Spacer(),
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
                onPressed: _continue,
              ),
              const SizedBox(height: 24),
            ],
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
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF001F3F).withOpacity(0.85),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFF00BFFF) : const Color(0xFF00BFFF).withOpacity(0.35),
              width: selected ? 2.5 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? const Color(0xFF00BFFF) : const Color(0xFF80DEEA),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 18,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
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
            backgroundColor: const Color(0xFF001F3F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF00BFFF), width: 2),
            ),
            title: Text(
              l10n.languageTitle,
              style: const TextStyle(color: Colors.white, fontSize: 18),
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
                child: Text(l10n.cancel, style: const TextStyle(color: Color(0xFF80DEEA))),
              ),
              TextButton(
                onPressed: () async {
                  await LocaleService.instance.setLocale(Locale(selected));
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.languageChanged),
                        backgroundColor: const Color(0xFF00BFFF),
                      ),
                    );
                  }
                },
                child: Text(
                  l10n.continueButton,
                  style: const TextStyle(
                    color: Color(0xFF00BFFF),
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
        side: BorderSide(
          color: selected ? const Color(0xFF00BFFF) : const Color(0xFF00BFFF).withOpacity(0.3),
        ),
      ),
      tileColor: const Color(0xFF001F3F),
      leading: Icon(
        selected ? Icons.check_circle : Icons.circle_outlined,
        color: selected ? const Color(0xFF00BFFF) : const Color(0xFF80DEEA),
      ),
      title: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}
