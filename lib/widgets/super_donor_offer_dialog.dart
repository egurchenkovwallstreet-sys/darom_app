import 'package:flutter/material.dart';
import 'package:darom_app/theme/app_colors.dart';
import 'package:darom_app/theme/darom_decorations.dart';

import '../models/listing_limit_info.dart';
import '../services/users_api.dart';
import 'payment_flow.dart';
import 'primary_action_button.dart';

Future<bool?> showSuperDonorOfferDialog(
  BuildContext context, {
  required ListingLimitInfo limitInfo,
  required String phoneNumber,
  UsersApi? usersApi,
}) {
  final upsell = limitInfo.upsell;
  if (upsell == null) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => _LimitDialog(
        title: 'Лимит объявлений',
        message: limitInfo.message,
        primaryLabel: 'Понятно',
        onPrimary: () => Navigator.pop(ctx, false),
      ),
    );
  }

  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _SuperDonorDialog(
      limitInfo: limitInfo,
      upsell: upsell,
      phoneNumber: phoneNumber,
      usersApi: usersApi ?? UsersApi(),
    ),
  );
}

class _LimitDialog extends StatelessWidget {
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;

  const _LimitDialog({
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary.withOpacity(0.85),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            PrimaryActionButton(
              label: primaryLabel,
              height: 50,
              fontSize: 16,
              borderRadius: 25,
              gradientColors: PrimaryActionButton.primaryShortGradient,
              onPressed: onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuperDonorDialog extends StatefulWidget {
  final ListingLimitInfo limitInfo;
  final SuperDonorUpsell upsell;
  final String phoneNumber;
  final UsersApi usersApi;

  const _SuperDonorDialog({
    required this.limitInfo,
    required this.upsell,
    required this.phoneNumber,
    required this.usersApi,
  });

  @override
  State<_SuperDonorDialog> createState() => _SuperDonorDialogState();
}

class _SuperDonorDialogState extends State<_SuperDonorDialog> {
  bool _isActivating = false;

  Future<void> _activate() async {
    setState(() => _isActivating = true);
    try {
      final activated = await startDaromPayment(
        context,
        phoneNumber: widget.phoneNumber,
        productType: 'super_donor',
        successSnackPrefix:
            '«${widget.upsell.title}» активирован! ${widget.upsell.description}',
      );
      if (!mounted) return;
      if (activated) {
        Navigator.pop(context, true);
      } else {
        Navigator.pop(context, false);
      }
    } finally {
      if (mounted) setState(() => _isActivating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final upsell = widget.upsell;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.badgeFounderBg,
              ),
              child: const Icon(Icons.star_rounded, color: AppColors.gold, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              widget.limitInfo.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DaromDecorations.cardRadius),
                color: AppColors.badgeNewbieBg,
              ),
              child: Column(
                children: [
                  Text(
                    upsell.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${upsell.priceRub}₽ / ${upsell.durationDays} дней',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    upsell.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary.withOpacity(0.8),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Итого до ${upsell.newLimit} объявлений',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Оплата через Робокассу (карта, СБП).',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryActionButton(
              label: 'Оплатить ${upsell.priceRub}₽',
              height: 50,
              fontSize: 16,
              borderRadius: 25,
              loading: _isActivating,
              gradientColors: PrimaryActionButton.primaryShortGradient,
              onPressed: _activate,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Не сейчас',
                style: TextStyle(color: AppColors.textPrimary.withOpacity(0.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
