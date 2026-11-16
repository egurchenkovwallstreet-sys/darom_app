import 'package:flutter/material.dart';
import 'package:darom_app/theme/app_colors.dart';

import '../utils/phone_detect.dart';

/// Предупреждение перед отправкой номера телефона в чате.
Future<bool> confirmPhoneSharing(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide.none,
      ),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.danger),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Вы передаёте номер телефона',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
            ),
          ),
        ],
      ),
      content: const Text(
        'Вы сами решили написать номер в чате. «Даром» никому не показывает '
        'ваш телефон автоматически.\n\n'
        'Остерегайтесь мошенников:\n'
        '• не переводите деньги\n'
        '• не сообщайте коды из SMS и банков\n'
        '• не передавайте паспортные и другие личные данные',
        style: TextStyle(color: AppColors.textPrimary, height: 1.45),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Отмена', style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Отправить', style: TextStyle(color: AppColors.danger)),
        ),
      ],
    ),
  ).then((value) => value ?? false);
}

/// Показать напоминание после отправки сообщения с номером.
void showPhoneSharingReminder(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Вы передали номер сами. Не переводите деньги и не сообщайте личные данные незнакомцам.',
      ),
      backgroundColor: AppColors.danger,
      duration: Duration(seconds: 8),
    ),
  );
}

bool messageMayContainPhone(String text) => containsPhoneNumber(text);
