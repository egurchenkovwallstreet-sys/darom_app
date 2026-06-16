import 'package:flutter/material.dart';

import '../models/listing_limit_info.dart';
import '../services/users_api.dart';
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
      backgroundColor: const Color(0xFF001F3F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: const Color(0xFF00BFFF).withOpacity(0.4)),
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
                color: Color(0xFFFFFFFF),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: const Color(0xFFFFFFFF).withOpacity(0.85),
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
      await widget.usersApi.activateSuperDonor(phone: widget.phoneNumber);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '«${widget.upsell.title}» активирован! ${widget.upsell.description}',
          ),
          backgroundColor: const Color(0xFF00BFFF),
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
      if (mounted) setState(() => _isActivating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final upsell = widget.upsell;

    return Dialog(
      backgroundColor: const Color(0xFF001F3F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: const Color(0xFF00BFFF).withOpacity(0.5), width: 2),
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
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFC107).withOpacity(0.3),
                    const Color(0xFF00BFFF).withOpacity(0.3),
                  ],
                ),
              ),
              child: const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              widget.limitInfo.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: const Color(0xFFFFFFFF).withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF00BFFF).withOpacity(0.4)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF00BFFF).withOpacity(0.15),
                    const Color(0xFF008C8C).withOpacity(0.1),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    upsell.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${upsell.priceRub}₽ / ${upsell.durationDays} дней',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00BFFF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    upsell.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFFFFFFFF).withOpacity(0.8),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Итого до ${upsell.newLimit} объявлений',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFFFC107),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Оплата через Робокассу — позже. Сейчас тестовая активация.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFFFFFFFF).withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryActionButton(
              label: 'Подключить ${upsell.priceRub}₽',
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
                style: TextStyle(color: const Color(0xFFFFFFFF).withOpacity(0.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
