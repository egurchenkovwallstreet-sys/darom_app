import 'package:flutter/material.dart';

import '../services/daily_reports_api.dart';
import '../theme/app_colors.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/primary_action_button.dart';

class AdminDailyReportsScreen extends StatefulWidget {
  const AdminDailyReportsScreen({super.key});

  @override
  State<AdminDailyReportsScreen> createState() => _AdminDailyReportsScreenState();
}

class _AdminDailyReportsScreenState extends State<AdminDailyReportsScreen> {
  final DailyReportsApi _api = DailyReportsApi();
  List<DailyReportSummary> _reports = [];
  bool _loading = true;
  bool _generating = false;
  String? _error;

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
      final items = await _api.fetchReports();
      if (!mounted) return;
      setState(() {
        _reports = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error is DailyReportsApiException ? error.message : '$error';
      });
    }
  }

  Future<void> _generateNow() async {
    setState(() => _generating = true);
    try {
      await _api.generateNow(force: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Отчёт сформирован'), backgroundColor: AppColors.cyan),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error is DailyReportsApiException ? error.message : '$error'),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _openReport(DailyReportSummary summary) async {
    try {
      final report = await _api.fetchReport(summary.id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.darkBlue,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      report.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Text(
                          report.bodyText,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            height: 1.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error is DailyReportsApiException ? error.message : '$error'),
          backgroundColor: AppColors.red,
        ),
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
                      'Ежедневная статистика',
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Новый отчёт каждый день в 21:00 (Москва) — здесь и на почте.',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
              ),
            ),
            Expanded(child: _buildBody()),
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryActionButton(
                label: _generating ? 'Формируем…' : 'Сформировать отчёт сейчас',
                loading: _generating,
                onPressed: _generating ? null : _generateNow,
              ),
            ),
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
            Text(_error!, style: const TextStyle(color: AppColors.red), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            PrimaryActionButton(label: 'Повторить', onPressed: _load),
          ],
        ),
      );
    }

    if (_reports.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Отчётов пока нет.\nПервый придёт сегодня в 21:00 — или нажмите «Сформировать отчёт сейчас».',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, height: 1.4),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        return Card(
          color: const Color(0xFF0A2A4A),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () => _openReport(report),
            title: Text(report.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              report.preview,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: report.emailSentAt != null
                ? const Icon(Icons.mail_outline, color: AppColors.cyan, size: 20)
                : null,
          ),
        );
      },
    );
  }
}
