import 'package:flutter/material.dart';

import '../data/legal_consent.dart';
import '../screens/cookie_policy_screen.dart';
import '../screens/privacy_policy_screen.dart';

/// Блокирующий диалог повторного согласия на обработку ПДн (152-ФЗ).
Future<bool?> showPrivacyPolicyUpdateDialog(BuildContext context) {
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
          Icon(Icons.privacy_tip_outlined, color: Color(0xFF00BFFF)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Обновилась политика ПДн',
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Оператор обновил политику обработки персональных данных '
            '(ред. ${_formatPolicyDate(LegalConsent.privacyPolicyVersion)}). '
            'Ознакомьтесь с документами и подтвердите согласие, чтобы продолжить пользоваться сервисом.',
            style: TextStyle(color: Colors.white.withOpacity(0.9), height: 1.45),
          ),
          const SizedBox(height: 12),
          _DocLink(
            label: 'Политика ПДн',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
              );
            },
          ),
          _DocLink(
            label: 'Политика cookie',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CookiePolicyScreen()),
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Выйти из аккаунта',
            style: TextStyle(color: Color(0xFF80DEEA)),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Принимаю',
            style: TextStyle(color: Color(0xFF00BFFF), fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

String _formatPolicyDate(String isoDate) {
  final parts = isoDate.split('-');
  if (parts.length != 3) return isoDate;
  return '${parts[2]}.${parts[1]}.${parts[0]}';
}

class _DocLink extends StatelessWidget {
  const _DocLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF00BFFF),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
