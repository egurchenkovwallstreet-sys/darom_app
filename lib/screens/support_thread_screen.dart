import 'dart:async';

import 'package:flutter/material.dart';

import '../models/support_message.dart';
import '../models/support_ticket.dart';
import '../services/support_api.dart';
import '../services/refresh_intervals.dart';
import '../theme/app_colors.dart';
import '../widgets/keyboard_inset_padding.dart';
import '../widgets/midnight_glow_screen.dart';

class SupportThreadScreen extends StatefulWidget {
  const SupportThreadScreen({
    super.key,
    required this.phoneNumber,
    required this.ticket,
    this.isAdminMode = false,
  });

  final String phoneNumber;
  final SupportTicket ticket;
  final bool isAdminMode;

  @override
  State<SupportThreadScreen> createState() => _SupportThreadScreenState();
}

class _SupportThreadScreenState extends State<SupportThreadScreen> {
  final SupportApi _api = SupportApi();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late SupportTicket _ticket;
  List<SupportMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _statusBusy = false;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
    _bootstrap();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _loadMessages(initial: true);
    if (!mounted) return;
    _pollTimer = Timer.periodic(RefreshIntervals.support, (_) => _loadMessages());
  }

  Future<void> _loadMessages({bool initial = false}) async {
    try {
      final data = widget.isAdminMode
          ? await _api.fetchAdminThread(ticketId: _ticket.id)
          : await _api.fetchThread(phone: widget.phoneNumber, ticketId: _ticket.id);

      if (!mounted) return;
      setState(() {
        _ticket = data.ticket;
        _messages = data.messages;
        _loading = false;
        _error = null;
      });

      if (initial || _messages.isNotEmpty) {
        _scrollToBottom();
      }
    } catch (error) {
      if (!mounted || !initial) return;
      setState(() {
        _loading = false;
        _error = error is SupportApiException ? error.message : '$error';
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending || _ticket.isClosed) return;

    setState(() => _sending = true);
    try {
      final message = widget.isAdminMode
          ? await _api.sendAdminMessage(ticketId: _ticket.id, body: text)
          : await _api.sendUserMessage(
              phone: widget.phoneNumber,
              ticketId: _ticket.id,
              body: text,
            );

      if (!mounted) return;
      setState(() {
        _messages = [..._messages, message];
        _inputController.clear();
      });
      _scrollToBottom();
      await _loadMessages();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error is SupportApiException ? error.message : '$error'),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _setStatus(String status) async {
    if (!widget.isAdminMode || _statusBusy) return;

    setState(() => _statusBusy = true);
    try {
      final updated = await _api.updateTicketStatus(ticketId: _ticket.id, status: status);
      if (!mounted) return;
      setState(() => _ticket = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Статус: ${updated.statusLabel}'),
          backgroundColor: AppColors.cyan,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error is SupportApiException ? error.message : '$error'),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _statusBusy = false);
    }
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return MidnightGlowScreen(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (widget.isAdminMode) _buildAdminActions(),
            Expanded(child: _buildMessages()),
            if (!_ticket.isClosed) _buildInput(),
            if (_ticket.isClosed)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Обращение закрыто',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context, _ticket),
            icon: const Icon(Icons.arrow_back, color: AppColors.cyan),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isAdminMode
                      ? '${_ticket.userName ?? 'Пользователь'} · ${_ticket.userPhone ?? ''}'
                      : _ticket.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  _ticket.statusLabel,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (_ticket.status != 'in_progress')
            OutlinedButton(
              onPressed: _statusBusy ? null : () => _setStatus('in_progress'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.cyan),
              child: const Text('В работе'),
            ),
          if (!_ticket.isClosed)
            OutlinedButton(
              onPressed: _statusBusy ? null : () => _setStatus('closed'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.red),
              child: const Text('Закрыть'),
            ),
          if (_ticket.isClosed)
            OutlinedButton(
              onPressed: _statusBusy ? null : () => _setStatus('in_progress'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.cyan),
              child: const Text('Открыть снова'),
            ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.cyan));
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: AppColors.red)),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMine = widget.isAdminMode ? message.isFromAdmin : message.isFromUser;

        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
            decoration: BoxDecoration(
              color: isMine ? const Color(0xFF007AA3) : const Color(0xFF001F3F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isMine ? const Color(0xFF80DEEA) : AppColors.cyan,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.isFromAdmin ? 'Поддержка' : (widget.isAdminMode ? 'Пользователь' : 'Вы'),
                  style: TextStyle(
                    color: isMine ? AppColors.cyan : Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(message.body, style: const TextStyle(color: Colors.white, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.createdAt),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInput() {
    return KeyboardInsetPadding(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: widget.isAdminMode ? 'Ответить...' : 'Написать сообщение...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF0A2A4A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.cyan),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: AppColors.cyan.withOpacity(0.5)),
                  ),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan),
                    )
                  : const Icon(Icons.send, color: AppColors.cyan),
            ),
          ],
        ),
      ),
    );
  }
}
