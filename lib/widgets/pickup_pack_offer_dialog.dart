import 'package:flutter/material.dart';

import '../models/pickup_limit_info.dart';
import '../services/users_api.dart';
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
        backgroundColor: const Color(0xFF001F3F),
        title: const Text('Лимит заборов', style: TextStyle(color: Colors.white)),
        content: Text(limitInfo.message, style: const TextStyle(color: Colors.white70)),
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
      await widget.usersApi.activatePickupPack(phone: widget.phoneNumber);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('«${widget.upsell.title}»: +${widget.upsell.extraPickups} заборов'),
          backgroundColor: const Color(0xFF00BFFF),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: const Color(0xFFFF5722)),
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
            const Icon(Icons.shopping_bag_outlined, color: Color(0xFF00BFFF), size: 40),
            const SizedBox(height: 12),
            Text(
              widget.limitInfo.message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.85)),
            ),
            const SizedBox(height: 16),
            Text(
              upsell.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${upsell.priceRub}₽ → +${upsell.extraPickups} заборов (пакет ${upsell.tier}/${upsell.tiersTotal})',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00BFFF),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              upsell.description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75)),
            ),
            const SizedBox(height: 8),
            Text(
              'Оплата через Робокассу — позже. Сейчас тестовая активация.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
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
              child: Text('Не сейчас', style: TextStyle(color: Colors.white.withOpacity(0.6))),
            ),
          ],
        ),
      ),
    );
  }
}
