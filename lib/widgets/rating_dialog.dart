import 'package:flutter/material.dart';

import '../services/deals_api.dart';
import 'primary_action_button.dart';

Future<void> showRatingDialog(
  BuildContext context, {
  required String dealId,
  required String counterpartyName,
  required String phoneNumber,
  DealsApi? dealsApi,
}) async {
  final api = dealsApi ?? DealsApi();
  var selected = 5;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: const Color(0xFF001F3F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: const Color(0xFF00BFFF).withOpacity(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Оцените сделку',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Как прошла передача с $counterpartyName?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: const Color(0xFFFFFFFF).withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      final filled = star <= selected;
                      return IconButton(
                        onPressed: () => setState(() => selected = star),
                        icon: Icon(
                          filled ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: filled ? const Color(0xFFFFC107) : const Color(0xFF9E9E9E),
                          size: 36,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  PrimaryActionButton(
                    label: 'Отправить',
                    height: 48,
                    fontSize: 16,
                    borderRadius: 24,
                    gradientColors: PrimaryActionButton.primaryShortGradient,
                    onPressed: () async {
                      try {
                        await api.rateDeal(
                          dealId: dealId,
                          phone: phoneNumber,
                          score: selected,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Спасибо за оценку!'),
                              backgroundColor: Color(0xFF00BFFF),
                            ),
                          );
                        }
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$error'),
                              backgroundColor: const Color(0xFFFF5722),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Пропустить',
                      style: TextStyle(color: const Color(0xFFFFFFFF).withOpacity(0.6)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  api.dispose();
}
