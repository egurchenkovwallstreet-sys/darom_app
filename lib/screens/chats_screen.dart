import 'dart:async';

import 'package:flutter/material.dart';

import '../models/conversation.dart';
import '../services/chats_api.dart';
import '../services/refresh_intervals.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/primary_action_button.dart';
import 'chat_thread_screen.dart';

class ChatsScreen extends StatefulWidget {
  final String phoneNumber;
  final String? currentUserId;
  final bool inShell;
  final bool isActiveTab;

  const ChatsScreen({
    super.key,
    required this.phoneNumber,
    this.currentUserId,
    this.inShell = false,
    this.isActiveTab = true,
  });

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final ChatsApi _api = ChatsApi();
  List<Conversation> _conversations = [];
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
  void didUpdateWidget(ChatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActiveTab == oldWidget.isActiveTab) return;
    if (widget.isActiveTab) {
      _startPoll();
      _refresh(silent: true);
    } else {
      _stopPoll();
    }
  }

  @override
  void dispose() {
    _stopPoll();
    _api.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _refresh();
    if (!mounted) return;
    if (widget.isActiveTab) {
      _startPoll();
    }
  }

  void _startPoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(RefreshIntervals.chats, (_) => _refresh(silent: true));
  }

  void _stopPoll() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_loadInFlight) return;
    _loadInFlight = true;

    try {
      final items = await _api.fetchConversations(phone: widget.phoneNumber);
      if (!mounted) return;
      setState(() {
        _conversations = items;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted || silent) return;
      setState(() {
        _loading = false;
        _error = error is ChatsApiException ? error.message : '$error';
      });
    } finally {
      _loadInFlight = false;
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final local = time.toLocal();
    final now = DateTime.now();
    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      final h = local.hour.toString().padLeft(2, '0');
      final m = local.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Чаты',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );

    if (widget.inShell) return content;
    return MidnightGlowScreen(child: content);
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00BFFF)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFFFFFFF).withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryActionButton(
                label: 'Повторить',
                height: 48,
                fontSize: 16,
                borderRadius: 24,
                gradientColors: PrimaryActionButton.primaryShortGradient,
                onPressed: () => _refresh(),
              ),
            ],
          ),
        ),
      );
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: const Color(0xFF00BFFF).withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Пока нет переписок\nОткройте объявление и нажмите «Написать владельцу»',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFFFFFFF).withOpacity(0.7),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF00BFFF),
      onRefresh: () => _refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final chat = _conversations[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatThreadScreen(
                      phoneNumber: widget.phoneNumber,
                      currentUserId: widget.currentUserId,
                      conversation: chat,
                    ),
                  ),
                );
                await _refresh(silent: true);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF001F3F).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF00BFFF), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BFFF).withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF00BFFF)),
                      ),
                      child: const Icon(Icons.chat, color: Color(0xFF00BFFF)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chat.counterpartyName,
                            style: const TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            chat.listingTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF00BFFF).withOpacity(0.9),
                            ),
                          ),
                          if (chat.lastMessage != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              chat.lastMessage!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: const Color(0xFFFFFFFF).withOpacity(0.65),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTime(chat.lastMessageAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFFFFFFFF).withOpacity(0.5),
                          ),
                        ),
                        if (chat.unreadCount > 0) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5722),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
