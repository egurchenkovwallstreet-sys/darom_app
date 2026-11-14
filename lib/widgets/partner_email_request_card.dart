import 'package:flutter/material.dart';
import 'package:darom_app/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const kPartnerRequestEmail = 'Darom.partner.ru@yandex.ru';

Future<void> openPartnerRequestEmail() async {
  final uri = Uri(
    scheme: 'mailto',
    path: kPartnerRequestEmail,
    query: _encodeQuery({
      'subject': 'Заявка на партнёрство «Дarom»',
    }),
  );

  final opened = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );

  if (!opened) {
    throw 'Не удалось открыть почту. Скопируйте адрес: $kPartnerRequestEmail';
  }
}

String? _encodeQuery(Map<String, String> params) {
  if (params.isEmpty) return null;
  return params.entries
      .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
}

class PartnerEmailRequestCard extends StatelessWidget {
  const PartnerEmailRequestCard({super.key});

  Future<void> _copyEmail(BuildContext context) async {
    try {
      await Clipboard.setData(const ClipboardData(text: kPartnerRequestEmail));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Адрес почты скопирован'),
          backgroundColor: AppColors.accent,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SelectableText(kPartnerRequestEmail),
          backgroundColor: AppColors.accent,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _openEmail(BuildContext context) async {
    try {
      await openPartnerRequestEmail();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$error'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Хотите стать нашим партнёром?\nНапишите запрос на почту',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.mail_outline, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openEmail(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            kPartnerRequestEmail,
                            maxLines: 1,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _copyEmail(context),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.copy_rounded, color: AppColors.accent, size: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Нажмите на почту — откроется приложение для письма',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary.withOpacity(0.55),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
