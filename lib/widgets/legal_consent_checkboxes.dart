import 'package:flutter/material.dart';
import 'package:darom_app/theme/app_colors.dart';
import 'package:darom_app/theme/darom_decorations.dart';

import '../data/legal_consent.dart';
import '../l10n/app_localizations.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/public_offer_screen.dart';

/// Чекбоксы оферты и согласия на обработку ПДn (156-ФЗ — отдельно от оферты).
class LegalConsentCheckboxes extends StatelessWidget {
  const LegalConsentCheckboxes({
    super.key,
    required this.offerAccepted,
    required this.privacyAccepted,
    required this.onOfferChanged,
    required this.onPrivacyChanged,
    this.enabled = true,
  });

  final bool offerAccepted;
  final bool privacyAccepted;
  final ValueChanged<bool> onOfferChanged;
  final ValueChanged<bool> onPrivacyChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: DaromDecorations.solidCard(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ConsentRow(
            value: offerAccepted,
            enabled: enabled,
            onChanged: onOfferChanged,
            label: l10n.offerCheckboxLabel,
            linkLabel: l10n.readOfferLink,
            onLink: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PublicOfferScreen()),
              );
            },
          ),
          const Divider(color: AppColors.borderDivider, height: 1, thickness: 1, indent: 56),
          _ConsentRow(
            value: privacyAccepted,
            enabled: enabled,
            onChanged: onPrivacyChanged,
            label: l10n.privacyCheckboxLabel(LegalConsent.privacyPolicyVersion),
            linkLabel: l10n.readPrivacyLink,
            onLink: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.label,
    required this.linkLabel,
    required this.onLink,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final String label;
  final String linkLabel;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConsentBox(checked: value),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton(
                    onPressed: enabled ? onLink : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      linkLabel,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Крупный квадрат-галочка: пустой — с заметной обводкой, отмеченный — синий с белой галкой.
class _ConsentBox extends StatelessWidget {
  const _ConsentBox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: DaromDecorations.interactionDuration,
      curve: DaromDecorations.interactionCurve,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: checked ? null : AppColors.surface,
        gradient: checked ? AppColors.brandGradient : null,
        borderRadius: BorderRadius.circular(7),
        border: checked ? null : Border.all(color: AppColors.controlOutline, width: 2),
      ),
      child: checked
          ? const Icon(Icons.check_rounded, color: AppColors.white, size: 20)
          : null,
    );
  }
}
