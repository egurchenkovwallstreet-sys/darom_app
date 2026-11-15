import 'dart:async';

import 'package:flutter/material.dart';

import '../models/support_ticket.dart';
import '../services/support_api.dart';
import '../services/refresh_intervals.dart';
import '../theme/app_colors.dart';
import '../theme/darom_decorations.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/primary_action_button.dart';
import 'support_thread_screen.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({
    super.key,
    required this.phoneNumber,
    this.isAdminMode = false,
  });

  final String phoneNumber;
  final bool isAdminMode;

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final SupportApi _api = SupportApi();
  List<SupportTicket> _tickets = [];
  bool _loading = true;
  String? _error;
  bool _loadInFlight = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _api.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _refresh();
    if (!mounted) return;
    _pollTimer = Timer.periodic(RefreshIntervals.support, (_) => _refresh(silent: true));
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_loadInFlight) return;
    _loadInFlight = true;

    try {
      final items = widget.isAdminMode
          ? await _api.fetchAdminTickets()
          : await _api.fetchMyTickets(phone: widget.phoneNumber);
      if (!mounted) return;
      setState(() {
        _tickets = items;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted || silent) return;
      setState(() {
        _loading = false;
        _error = error is SupportApiException ? error.message : '$error';
      });
    } finally {
      _loadInFlight = false;
    }
  }

  Future<void> _openCreateDialog() async {
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Новое обращение', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                style: DaromDecorations.fieldText,
                decoration: DaromDecorations.lightFieldDecoration(labelText: 'Тема (необязательно)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                style: DaromDecorations.fieldText,
                maxLines: 5,
                decoration: DaromDecorations.lightFieldDecoration(labelText: 'Сообщение'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Отправить'),
          ),
        ],
      ),
    );

    if (created != true || !mounted) return;

    final body = bodyController.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите текст сообщения'), backgroundColor: AppColors.red),
      );
      return;
    }

    try {
      await _api.createTicket(
        phone: widget.phoneNumber,
        subject: subjectController.text.trim(),
        body: body,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Обращение отправлено'), backgroundColor: AppColors.cyan),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error is SupportApiException ? error.message : '$error'),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      subjectController.dispose();
      bodyController.dispose();
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final local = time.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isAdminMode ? 'Обращения пользователей' : 'Служба поддержки';

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
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _refresh(),
                    icon: const Icon(Icons.refresh, color: AppColors.cyan),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody()),
            if (!widget.isAdminMode)
              Padding(
                padding: const EdgeInsets.all(16),
                child: PrimaryActionButton(
                  label: 'Написать в поддержку',
                  icon: Icons.edit_outlined,
                  onPressed: _openCreateDialog,
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.red)),
              const SizedBox(height: 12),
              PrimaryActionButton(label: 'Повторить', onPressed: _refresh),
            ],
          ),
        ),
      );
    }

    if (_tickets.isEmpty) {
      return Center(
        child: Text(
          widget.isAdminMode ? 'Обращений пока нет' : 'У вас пока нет обращений',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tickets.length,
      itemBuilder: (context, index) {
        final ticket = _tickets[index];
        final unread = widget.isAdminMode ? ticket.unreadForAdmin : ticket.unreadForUser;

        return Card(
          color: AppColors.surface.withOpacity(0.95),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SupportThreadScreen(
                    phoneNumber: widget.phoneNumber,
                    ticket: ticket,
                    isAdminMode: widget.isAdminMode,
                  ),
                ),
              );
              if (mounted) await _refresh(silent: true);
            },
            title: Text(
              widget.isAdminMode
                  ? '${ticket.userName ?? 'Пользователь'} (${ticket.userPhone ?? '—'})'
                  : ticket.displayTitle,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isAdminMode)
                  Text(ticket.displayTitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                Text(
                  ticket.lastMessage ?? '—',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ticket.statusLabel} · ${_formatTime(ticket.lastMessageAt ?? ticket.updatedAt)}',
                  style: TextStyle(color: AppColors.textSecondary.withOpacity(0.75), fontSize: 12),
                ),
              ],
            ),
            trailing: unread > 0
                ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: AppColors.cyan, shape: BoxShape.circle),
                    child: Text('$unread', style: const TextStyle(color: AppColors.white, fontSize: 12)),
                  )
                : null,
          ),
        );
      },
    );
  }
}
