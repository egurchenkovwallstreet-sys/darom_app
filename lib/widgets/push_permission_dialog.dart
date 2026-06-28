import 'package:flutter/material.dart';

/// Спрашивает, включить ли push. Кнопка «Включить» — жест пользователя для браузера.
Future<bool?> showPushPermissionDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF001F3F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF00BFFF), width: 2),
      ),
      title: const Row(
        children: [
          Icon(Icons.notifications_active_rounded, color: Color(0xFF00BFFF)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Уведомления',
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
            ),
          ),
        ],
      ),
      content: const Text(
        'Разрешите уведомления, чтобы не пропустить сообщения в чате, '
        'бронирования и отметку «Отдал».\n\n'
        'После нажатия «Включить» браузер покажет свой запрос — выберите «Разрешить».',
        style: TextStyle(color: Color(0xFFFFFFFF), height: 1.45),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Не сейчас', style: TextStyle(color: Color(0xFF80DEEA))),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Включить', style: TextStyle(color: Color(0xFF00BFFF))),
        ),
      ],
    ),
  );
}
