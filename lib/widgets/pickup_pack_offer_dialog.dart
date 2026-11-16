import 'package:flutter/material.dart';
import 'package:darom_app/theme/app_colors.dart';

import '../models/pickup_limit_info.dart';
import '../services/users_api.dart';
import 'payment_flow.dart';
import 'primary_action_button.dart';

Future<bool?> showPickupPackOfferDialog(
  BuildContext context, {
  required PickupLimitInfo limitInfo,
  required String phoneNumber,
  UsersApi? usersApi,
}) {
  final upsell = limitInfo.upsell;
  if (upsell == null) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Лимит заборов', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(limitInfo.message, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  return showDialog<bool>(
    context: context,
    builder: (ctx) => _PickupPackDialog(
      limitInfo: limitInfo,
      upsell: upsell,
      phoneNumber: phoneNumber,
      usersApi: usersApi ?? UsersApi(),
    ),
  );
}

class _PickupPackDialog extends StatefulWidget {
  final PickupLimitInfo limitInfo;
  final PickupPackUpsell upsell;
  final String phoneNumber;
  final UsersApi usersApi;

  const _PickupPackDialog({
    required this.limitInfo,
    required this.upsell,
    required this.phoneNumber,
    required this.usersApi,
  });

  @override
  State<_PickupPackDialog> createState() => _PickupPackDialogState();
}

class _PickupPackDialogState extends State<_PickupPackDialog> {
  bool _isActivating = false;

  Future<void> _activate() async {
    setState(() => _isActivating = true);
    try {
      final activated = await startDaromPayment(
        context,
        phoneNumber: widget.phoneNumber,
        productType: 'pickup_pack',
        successSnackPrefix:
            '«${widget.upsell.title}»: +${widget.upsell.extraPickups} заборов',
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
            const Icon(Icons.shopping_bag_outlined, color: AppColors.accent, size: 40),
            const SizedBox(height: 12),
            Text(
              widget.limitInfo.message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
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
              '${upsell.priceRub}₽ — +${upsell.extraPickups} заборов (пакет ${upsell.tier}/${upsell.tiersTotal})',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              upsell.description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Оплата через Робокассу (карта, СБП).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withOpacity(0.85)),
            ),
            const SizedBox(height: 20),
            PrimaryActionButton(
              label: 'Купить ${upsell.priceRub}₽',
              height: 48,
              fontSize: 16,
              borderRadius: 24,
              loading: _isActivating,
              gradientColors: PrimaryActionButton.primaryShortGradient,
              onPressed: _activate,
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Не сейчас', style: TextStyle(color: AppColors.textSecondary.withOpacity(0.9))),
            ),
          ],
        ),
      ),
    );
  }
}
