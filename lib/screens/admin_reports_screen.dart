import 'package:flutter/material.dart';

import '../services/moderation_api.dart';
import '../theme/app_colors.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/primary_action_button.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final ModerationApi _api = ModerationApi();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _listingReports = [];
  List<Map<String, dynamic>> _chatReports = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final listingReports = await _api.fetchListingReports();
      final chatReports = await _api.fetchChatReports();
      if (!mounted) return;
      setState(() {
        _listingReports = listingReports;
        _chatReports = chatReports;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error is ModerationApiException ? error.message : '$error';
      });
    }
  }

  Future<void> _blockUser(String userId, {required bool permanent, int days = 3}) async {
    try {
      await _api.blockUser(userId: userId, permanent: permanent, days: permanent ? null : days, reason: 'profile_moderation');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь заблокирован'), backgroundColor: AppColors.cyan),
      );
      await _load();
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
        listingId: listingId,
        permanent: permanent,
        days: permanent ? null : days,
        reason: 'profile_moderation',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Объявление скрыто'), backgroundColor: AppColors.cyan),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: AppColors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MidnightGlowScreen(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.cyan),
                  ),
                  const Expanded(
                    child: Text(
                      'Жалобы',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh, color: AppColors.cyan),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.cyan));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: AppColors.red)),
            const SizedBox(height: 12),
            PrimaryActionButton(label: 'Повторить', onPressed: _load),
          ],
        ),
      );
    }

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
            Text(
              'Жалоб: ${r['reports_count'] ?? 0} | Статус: ${r['listing_status']}',
              style: const TextStyle(color: Colors.white54),
            ),
            Text(
              'От: ${r['reporter_name']} | Причина: ${r['reason'] ?? '—'}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _blockBtn('Скрыть 3 дня', () => _blockListing(listingId, permanent: false, days: 3)),
                _blockBtn('Навсегда', () => _blockListing(listingId, permanent: true)),
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
            Text(
              'Даритель: ${r['donor_name']} | Получатель: ${r['recipient_name']}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            Text(
              'Жалоба от: ${r['reporter_name']} — ${r['reason'] ?? '—'}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
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
}
