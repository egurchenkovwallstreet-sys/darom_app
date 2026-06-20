import 'package:flutter/material.dart';

import '../utils/phone_detect.dart';

/// Предупреждение перед отправкой номера телефона в чате.
Future<bool> confirmPhoneSharing(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF001F3F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFF5722), width: 2),
      ),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5722)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Вы передаёте номер телефона',
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
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
        style: TextStyle(color: Color(0xFFFFFFFF), height: 1.45),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Отмена', style: TextStyle(color: Color(0xFF80DEEA))),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Отправить', style: TextStyle(color: Color(0xFFFF5722))),
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
      backgroundColor: Color(0xFFFF5722),
      duration: Duration(seconds: 8),
    ),
  );
}

bool messageMayContainPhone(String text) => containsPhoneNumber(text);
