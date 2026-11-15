import 'package:flutter/material.dart';
import 'package:darom_app/theme/app_colors.dart';

/// Спрашивает, включить ли push. Кнопка «Включить» — жест пользователя для браузера.
Future<bool?> showPushPermissionDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.accent, width: 2),
      ),
      title: const Row(
        children: [
          Icon(Icons.notifications_active_rounded, color: AppColors.accent),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Уведомления',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
            ),
          ),
        ],
      ),
      content: const Text(
        'Разрешите уведомления, чтобы не пропустить сообщения в чате, '
        'бронирования и отметку «Отдал».\n\n'
        'После нажатия «Включить» браузер покажет свой запрос — выберите «Разрешить».',
        style: TextStyle(color: AppColors.textPrimary, height: 1.45),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Не сейчас', style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Включить', style: TextStyle(color: AppColors.accent)),
        ),
      ],
    ),
  );
}
