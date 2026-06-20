import 'package:flutter/material.dart';
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
          backgroundColor: Color(0xFF00BFFF),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SelectableText(kPartnerRequestEmail),
          backgroundColor: const Color(0xFF00BFFF),
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
          backgroundColor: const Color(0xFFFF5722),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF001F3F).withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF00BFFF), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BFFF).withOpacity(0.25),
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
              color: const Color(0xFF00BFFF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00BFFF), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.mail_outline, color: Color(0xFF00BFFF), size: 20),
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
                              color: Color(0xFF80DEEA),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF80DEEA),
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
                      child: Icon(Icons.copy_rounded, color: Color(0xFF00BFFF), size: 22),
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
              color: const Color(0xFFFFFFFF).withOpacity(0.55),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
