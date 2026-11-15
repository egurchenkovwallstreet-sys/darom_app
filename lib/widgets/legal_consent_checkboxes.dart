import 'package:flutter/material.dart';
import 'package:darom_app/theme/app_colors.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withOpacity(0.25)),
      ),
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
          const SizedBox(height: 4),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                activeColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                onChanged: enabled ? (v) => onChanged(v ?? false) : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: TextButton(
            onPressed: enabled ? onLink : null,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              linkLabel,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
