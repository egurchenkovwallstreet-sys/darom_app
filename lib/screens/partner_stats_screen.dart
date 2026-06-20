import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/partners_api.dart';
import '../widgets/midnight_glow_screen.dart';

class PartnerStatsScreen extends StatefulWidget {
  final String phoneNumber;

  const PartnerStatsScreen({super.key, required this.phoneNumber});

  @override
  State<PartnerStatsScreen> createState() => _PartnerStatsScreenState();
}

class _PartnerStatsScreenState extends State<PartnerStatsScreen> {
  final PartnersApi _api = PartnersApi();
  late Future<PartnerStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _api.fetchStats(phone: widget.phoneNumber);
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _statsFuture = _api.fetchStats(phone: widget.phoneNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MidnightGlowScreen(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF00BFFF)),
                  ),
                  const Expanded(
                    child: Text(
                      'Статистика партнёра',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<PartnerStats>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
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
                              '$snapshot.error',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFFFFFFFF)),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _retry,
                              child: const Text('Повторить', style: TextStyle(color: Color(0xFF00BFFF))),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final stats = snapshot.data!;
                  return RefreshIndicator(
                    color: const Color(0xFF00BFFF),
                    onRefresh: () async {
                      _retry();
                      await _statsFuture;
                    },
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        if (stats.partnerPublicCode != null) ...[
                          _shareCodeCard(stats.partnerPublicCode!),
                          const SizedBox(height: 16),
                        ],
                        _statCard(
                          icon: Icons.people_alt_rounded,
                          title: 'Активные рефералы',
                          value: '${stats.referredUsers}',
                          subtitle: 'привязаны к вам в течение ${stats.referralTtlDays} дней',
                        ),
                        const SizedBox(height: 12),
                        _statCard(
                          icon: Icons.payments_rounded,
                          title: 'Оплат от активных рефералов',
                          value: '${stats.paymentsCount}',
                          subtitle: 'на сумму ${stats.totalPaymentsRub} ₽ за ${stats.referralTtlDays} дней',
                        ),
                        const SizedBox(height: 12),
                        _statCard(
                          icon: Icons.account_balance_wallet_rounded,
                          title: 'К выплате (${stats.commissionPercent}%)',
                          value: '${stats.payoutRub} ₽',
                          subtitle: '${stats.commissionPercent}% от оплат активных рефералов за ${stats.referralTtlDays} дней',
                          accent: true,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Делитесь кодом ${stats.partnerPublicCode ?? ''} при регистрации. '
                          'Реферал привязан к вам ${stats.referralTtlDays} дней — '
                          'вы получаете ${stats.commissionPercent}% со всех его оплат в этот период. '
                          'После ${stats.referralTtlDays} дней реферал отключается.',
                          style: TextStyle(
                            color: const Color(0xFFFFFFFF).withOpacity(0.65),
                            height: 1.45,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shareCodeCard(String code) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF001F3F).withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00BFFF), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ваш код для аудитории',
            style: TextStyle(color: Color(0xFF80DEEA), fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  code,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Код скопирован'),
                      backgroundColor: Color(0xFF00BFFF),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, color: Color(0xFF00BFFF)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    bool accent = false,
  }) {
    final color = accent ? const Color(0xFFFFC107) : const Color(0xFF00BFFF);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF001F3F).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFFFFFFFF).withOpacity(0.75),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: const Color(0xFFFFFFFF).withOpacity(0.55),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
