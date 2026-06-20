import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/admin_api.dart';
import '../services/admin_session_service.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_action_button.dart';
import 'admin_login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, required this.session});

  final AdminSessionData session;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final AdminApi _api = AdminApi();
  late TabController _tabs;
  String _period = 'all';
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _listingReports = [];
  List<Map<String, dynamic>> _chatReports = [];
  Map<String, dynamic> _platformStats = {};
  AdminBloggersData? _bloggers;

  @override
  void initState() {
    super.initState();
    final tabCount = widget.session.isSuperAdmin ? 3 : 1;
    _tabs = TabController(length: tabCount, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final token = widget.session.token;
    var listingReports = <Map<String, dynamic>>[];
    var chatReports = <Map<String, dynamic>>[];
    var stats = <String, dynamic>{};
    AdminBloggersData? bloggers;
    String? loadError;

    try {
      listingReports = await _api.fetchListingReports(token: token);
      chatReports = await _api.fetchChatReports(token: token);
    } catch (error) {
      loadError = '$error';
    }

    if (widget.session.isSuperAdmin) {
      try {
        stats = await _api.fetchPlatformStats(token: token, period: _period);
      } catch (error) {
        loadError ??= '$error';
      }
      try {
        bloggers = await _api.fetchBloggers(token: token, period: _period);
      } catch (error) {
        loadError ??= '$error';
      }
    }

    if (!mounted) return;
    setState(() {
      _listingReports = listingReports;
      _chatReports = chatReports;
      _platformStats = stats;
      _bloggers = bloggers;
      _loading = false;
      _error = loadError;
    });
  }

  Future<void> _logout() async {
    await AdminSessionService.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AdminLoginScreen(
          onLoggedIn: (session) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => AdminDashboardScreen(session: session)),
            );
          },
        ),
      ),
    );
  }

  Future<void> _blockUser(String userId, {required bool permanent, int days = 3}) async {
    try {
      await _api.blockUser(
        token: widget.session.token,
        userId: userId,
        permanent: permanent,
        days: permanent ? null : days,
        reason: 'admin_panel',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь заблокирован'), backgroundColor: AppColors.cyan),
      );
      await _loadAll();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: AppColors.red),
      );
    }
  }

  Future<void> _blockListing(String listingId, {required bool permanent, int days = 3}) async {
    try {
      await _api.blockListing(
        token: widget.session.token,
        listingId: listingId,
        permanent: permanent,
        days: permanent ? null : days,
        reason: 'admin_panel',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Объявление скрыто'), backgroundColor: AppColors.cyan),
      );
      await _loadAll();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: AppColors.red),
      );
    }
  }

  Future<void> _payPartner(String partnerId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBlue,
        title: const Text('Оплатить партнёру?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Сумма «за месяц» обнулится. «Всего заработано» останется.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Оплатить')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _api.payPartner(token: widget.session.token, partnerId: partnerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выплата отмечена'), backgroundColor: AppColors.cyan),
      );
      await _loadAll();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: AppColors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      appBar: AppBar(
        backgroundColor: AppColors.darkBlue,
        foregroundColor: Colors.white,
        title: const Text('Админ-панель «Даром»'),
        actions: [
          IconButton(onPressed: _loadAll, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.cyan,
          labelColor: AppColors.cyan,
          unselectedLabelColor: Colors.white54,
          tabs: [
            const Tab(text: 'Жалобы'),
            if (widget.session.isSuperAdmin) const Tab(text: 'Статистика'),
            if (widget.session.isSuperAdmin) const Tab(text: 'Блогеры'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
          : _error != null && _listingReports.isEmpty && _chatReports.isEmpty && _bloggers == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: AppColors.red)),
                      const SizedBox(height: 12),
                      PrimaryActionButton(label: 'Повторить', onPressed: _loadAll),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (_error != null)
                      Material(
                        color: AppColors.red.withOpacity(0.15),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 12)),
                        ),
                      ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _buildReportsTab(),
                          if (widget.session.isSuperAdmin) _buildStatsTab(),
                          if (widget.session.isSuperAdmin) _buildBloggersTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildReportsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Жалобы на объявления (${_listingReports.length})'),
        if (_listingReports.isEmpty)
          const Text('Нет жалоб', style: TextStyle(color: Colors.white54))
        else
          ..._listingReports.map(_listingReportCard),
        const SizedBox(height: 24),
        _sectionTitle('Жалобы на чаты (${_chatReports.length})'),
        if (_chatReports.isEmpty)
          const Text('Нет жалоб', style: TextStyle(color: Colors.white54))
        else
          ..._chatReports.map(_chatReportCard),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _listingReportCard(Map<String, dynamic> r) {
    final listingId = r['listing_id'] as String? ?? '';
    final ownerPhone = r['owner_phone'] as String? ?? '';
    return Card(
      color: const Color(0xFF0A2A4A),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r['listing_title'] as String? ?? '—', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(r['listing_description'] as String? ?? '', style: const TextStyle(color: Colors.white70)),
            Text('Жалоб: ${r['reports_count'] ?? 0} | Статус: ${r['listing_status']}', style: const TextStyle(color: Colors.white54)),
            Text('От: ${r['reporter_name']} | Причина: ${r['reason'] ?? '—'}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _blockBtn('Скрыть 3 дня', () => _blockListing(listingId, permanent: false, days: 3)),
                _blockBtn('Навсегда', () => _blockListing(listingId, permanent: true)),
                if (ownerPhone.isNotEmpty)
                  _blockBtn('Блок владельца', () => _blockUser(r['owner_id'] as String? ?? '', permanent: false, days: 7)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatReportCard(Map<String, dynamic> r) {
    final messages = (r['messages'] as List<dynamic>? ?? []);
    final listingId = r['listing_id'] as String? ?? '';
    return Card(
      color: const Color(0xFF0A2A4A),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Чат: ${r['listing_title']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text('Даритель: ${r['donor_name']} | Получатель: ${r['recipient_name']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            Text('Жалоба от: ${r['reporter_name']} — ${r['reason'] ?? '—'}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView(
                shrinkWrap: true,
                children: messages.map((m) {
                  final map = m as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${map['created_at']}: ${map['body']}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _blockBtn('Скрыть объявление', () => _blockListing(listingId, permanent: false, days: 7)),
                _blockBtn('Блок дарителя', () => _blockUser(r['donor_id'] as String? ?? '', permanent: false, days: 7)),
                _blockBtn('Блок получателя', () => _blockUser(r['recipient_id'] as String? ?? '', permanent: false, days: 7)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _blockBtn(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(foregroundColor: AppColors.red, side: const BorderSide(color: AppColors.red)),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildStatsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _periodPicker(onChanged: (p) async {
          setState(() => _period = p);
          await _loadAll();
        }),
        const SizedBox(height: 16),
        _statTile('Пользователи', '${_platformStats['users_count'] ?? 0}'),
        _statTile('Активные объявления', '${_platformStats['active_listings'] ?? 0}'),
        _statTile('Оплат (шт.)', '${_platformStats['payments_count'] ?? 0}'),
        _statTile('Оплат (₽)', '${_platformStats['payments_rub'] ?? 0}'),
        _statTile('Супер даритель', '${_platformStats['super_donor_activations'] ?? 0}'),
      ],
    );
  }

  Widget _buildBloggersTab() {
    final data = _bloggers;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _periodPicker(onChanged: (p) async {
          setState(() => _period = p);
          await _loadAll();
        }),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFF0A2A4A),
          child: ListTile(
            title: const Text('Следующий код партнёра', style: TextStyle(color: Colors.white)),
            subtitle: Text(data?.nextCode ?? '—', style: const TextStyle(color: AppColors.cyan, fontSize: 22)),
            trailing: IconButton(
              icon: const Icon(Icons.copy, color: AppColors.cyan),
              onPressed: data?.nextCode.isNotEmpty == true
                  ? () {
                      Clipboard.setData(ClipboardData(text: data!.nextCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Код скопирован')),
                      );
                    }
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...(data?.bloggers ?? []).map((b) {
          final id = b['id'] as String? ?? '';
          return Card(
            color: const Color(0xFF0A2A4A),
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${b['name']} (${b['partner_public_code']})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('Тел: ${b['phone']}', style: const TextStyle(color: Colors.white54)),
                  Text('Рефералов: ${b['referred_users']} | Оплат: ${b['payments_count']} (${b['payments_rub']} ₽)', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  Text('К выплате: ${b['payout_pending_rub']} ₽ | Бонус за период: ${b['bonus_rub']} ₽', style: const TextStyle(color: AppColors.cyan, fontSize: 12)),
                  const SizedBox(height: 8),
                  PrimaryActionButton(
                    label: 'Оплатить',
                    height: 40,
                    fontSize: 14,
                    onPressed: () => _payPartner(id),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _periodPicker({required ValueChanged<String> onChanged}) {
    const periods = [
      ('day', 'День'),
      ('week', 'Неделя'),
      ('month', 'Месяц'),
      ('all', 'Всего'),
    ];
    return Wrap(
      spacing: 8,
      children: periods.map((p) {
        final selected = _period == p.$1;
        return ChoiceChip(
          label: Text(p.$2),
          selected: selected,
          onSelected: (_) => onChanged(p.$1),
          selectedColor: AppColors.cyan,
          labelStyle: TextStyle(color: selected ? AppColors.darkBlue : Colors.white),
        );
      }).toList(),
    );
  }

  Widget _statTile(String label, String value) {
    return Card(
      color: const Color(0xFF0A2A4A),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label, style: const TextStyle(color: Colors.white70)),
        trailing: Text(value, style: const TextStyle(color: AppColors.cyan, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
