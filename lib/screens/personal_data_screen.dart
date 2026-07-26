import 'package:flutter/material.dart';

import '../services/users_api.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/primary_action_button.dart';

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({
    super.key,
    required this.phoneNumber,
  });

  final String phoneNumber;

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  final UsersApi _usersApi = UsersApi();
  Future<PersonalDataExport>? _future;

  @override
  void initState() {
    super.initState();
    _future = _usersApi.fetchPersonalData(phone: widget.phoneNumber);
  }

  @override
  void dispose() {
    _usersApi.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = _usersApi.fetchPersonalData(phone: widget.phoneNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MidnightGlowScreen(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF00BFFF)),
                  ),
                  const Expanded(
                    child: Text(
                      'Мои персональные данные',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<PersonalDataExport>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF00BFFF)),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white.withOpacity(0.8)),
                            ),
                            const SizedBox(height: 16),
                            PrimaryActionButton(
                              label: 'Повторить',
                              height: 44,
                              fontSize: 15,
                              borderRadius: 22,
                              gradientColors: PrimaryActionButton.primaryShortGradient,
                              onPressed: _reload,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data!;
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _section('Профиль', _profileLines(data.profile)),
                      const SizedBox(height: 12),
                      _section('Сколько данных хранится', _countLines(data.counts)),
                      const SizedBox(height: 12),
                      _section('Примечание', [data.note]),
                      if (data.exportedAt.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Выгрузка: ${data.exportedAt}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _profileLines(Map<String, dynamic> profile) {
    return [
      'ID: ${profile['id'] ?? '—'}',
      'Телефон: ${profile['phone'] ?? '—'}',
      'Имя: ${profile['name'] ?? '—'}',
      'Рейтинг: ${profile['rating'] ?? '—'}',
      'Уровень: ${profile['donor_level'] ?? '—'}',
      'Телефон подтверждён: ${_yesNo(profile['real_phone_verified'])}',
      'Согласие на ПДн: ${profile['privacy_consent_at'] ?? 'не зафиксировано'}',
      'Версия политики: ${profile['privacy_policy_version'] ?? '—'}',
      'Оферта принята: ${profile['offer_accepted_at'] ?? 'не зафиксировано'}',
      'Регистрация: ${profile['created_at'] ?? '—'}',
    ];
  }

  List<String> _countLines(Map<String, dynamic> counts) {
    return [
      'Объявлений всего: ${counts['listings_total'] ?? 0}',
      'Активных объявлений: ${counts['listings_active'] ?? 0}',
      'Чатов: ${counts['chat_conversations'] ?? 0}',
      'Сообщений в чатах: ${counts['chat_messages'] ?? 0}',
      'Избранное: ${counts['favorites'] ?? 0}',
      'Обращений в поддержку: ${counts['support_tickets'] ?? 0}',
      'Платежей: ${counts['payments'] ?? 0}',
    ];
  }

  String _yesNo(dynamic value) {
    if (value == true) return 'да';
    if (value == false) return 'нет';
    return '—';
  }

  Widget _section(String title, List<String> lines) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF001F3F).withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00BFFF).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF00BFFF),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                line,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
