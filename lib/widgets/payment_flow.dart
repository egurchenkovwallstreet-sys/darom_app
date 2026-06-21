import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/auth_gate.dart';
import '../services/payments_api.dart';
import 'primary_action_button.dart';

Future<bool?> startDaromPayment(
  BuildContext context, {
  required String phoneNumber,
  required String productType,
  required String successSnackPrefix,
  PaymentsApi? paymentsApi,
}) async {
  final api = paymentsApi ?? PaymentsApi();
  try {
    final result = await api.createPayment(
      phone: phoneNumber,
      productType: productType,
    );

    if (!context.mounted) return false;

    if (result.mock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? successSnackPrefix),
          backgroundColor: const Color(0xFF00BFFF),
        ),
      );
      return true;
    }

    final paymentUrl = result.paymentUrl;
    if (paymentUrl == null || paymentUrl.isEmpty) {
      throw PaymentsApiException('Не получена ссылка на оплату');
    }

    final uri = Uri.parse(paymentUrl);
    final opened = await launchUrl(uri, webOnlyWindowName: '_self');
    if (!opened) {
      throw PaymentsApiException('Не удалось открыть страницу оплаты');
    }
    return false;
  } catch (error) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$error'),
        backgroundColor: const Color(0xFFFF5722),
      ),
    );
    return false;
  }
}

class PaymentResultScreen extends StatefulWidget {
  final bool success;
  final String? invId;

  const PaymentResultScreen({
    super.key,
    required this.success,
    this.invId,
  });

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  String _statusText = 'Проверяем оплату…';
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    if (widget.success) {
      _checkPayment();
    } else {
      _checking = false;
      _statusText = 'Оплата отменена или не прошла. Можно попробовать снова из приложения.';
    }
  }

  Future<void> _checkPayment() async {
    final invId = int.tryParse(widget.invId ?? '');
    if (invId == null) {
      setState(() {
        _checking = false;
        _statusText = 'Оплата прошла. Вернитесь в приложение — лимиты обновятся.';
      });
      return;
    }

    final api = PaymentsApi();
    for (var attempt = 0; attempt < 8; attempt++) {
      try {
        final status = await api.fetchStatus(invId: invId);
        if (!mounted) return;
        if (status.isPaid) {
          setState(() {
            _checking = false;
            _statusText = 'Оплата ${status.amountRub}₽ прошла успешно!';
          });
          api.dispose();
          return;
        }
      } catch (_) {
        // Result URL может прийти с задержкой — повторяем.
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    if (!mounted) return;
    setState(() {
      _checking = false;
      _statusText =
          'Оплата принята банком. Если лимит не обновился — подождите минуту и откройте профиль.';
    });
    api.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001F3F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.success ? Icons.check_circle_outline : Icons.error_outline,
                size: 72,
                color: widget.success ? const Color(0xFF00BFFF) : const Color(0xFFFF5722),
              ),
              const SizedBox(height: 24),
              Text(
                widget.success ? 'Спасибо!' : 'Оплата не завершена',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              if (_checking) const CircularProgressIndicator(color: Color(0xFF00BFFF)),
              if (_checking) const SizedBox(height: 16),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              PrimaryActionButton(
                label: 'На главную',
                height: 50,
                fontSize: 16,
                borderRadius: 25,
                gradientColors: PrimaryActionButton.primaryShortGradient,
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthGate()),
                    (_) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
