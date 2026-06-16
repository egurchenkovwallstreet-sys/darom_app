import 'dart:async';

import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../services/chats_api.dart';
import '../services/listings_api.dart' show PickupLimitException;
import '../theme/app_colors.dart';
import '../widgets/keyboard_inset_padding.dart';
import '../widgets/primary_action_button.dart';
import '../widgets/pickup_pack_offer_dialog.dart';

class ChatThreadScreen extends StatefulWidget {
  final String phoneNumber;
  final String? currentUserId;
  final Conversation conversation;

  const ChatThreadScreen({
    super.key,
    required this.phoneNumber,
    this.currentUserId,
    required this.conversation,
  });

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final ChatsApi _api = ChatsApi();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  late Conversation _conversation;
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _reserving = false;
  bool _loadInFlight = false;
  Timer? _pollTimer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    _inputFocus.addListener(_onInputFocusChange);
    _bootstrap();
  }

  void _onInputFocusChange() {
    if (_inputFocus.hasFocus) {
      for (final delay in [100, 300, 500]) {
        Future<void>.delayed(Duration(milliseconds: delay), _scrollToBottom);
      }
    }
  }

  Future<void> _bootstrap() async {
    await _loadMessages(initial: true);
    if (!mounted) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputFocus.removeListener(_onInputFocusChange);
    _inputFocus.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    _api.dispose();
    super.dispose();
  }

  String? get _lastMessageId => _messages.isEmpty ? null : _messages.last.id;

  List<ChatMessage> _mergeMessages(
    List<ChatMessage> current,
    List<ChatMessage> incoming,
  ) {
    if (incoming.isEmpty) return current;

    final known = {for (final message in current) message.id};
    final merged = [...current];

    for (final message in incoming) {
      if (known.contains(message.id)) continue;
      merged.add(message);
      known.add(message.id);
    }

    merged.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return merged;
  }

  Future<void> _loadMessages({bool initial = false}) async {
    if (_loadInFlight || _sending || _reserving) return;

    _loadInFlight = true;
    try {
      final data = await _api.fetchMessages(
        phone: widget.phoneNumber,
        conversationId: _conversation.id,
        afterId: initial ? null : _lastMessageId,
      );

      if (!mounted) return;

      final merged = initial
          ? data.messages
          : _mergeMessages(_messages, data.messages);

      setState(() {
        _conversation = data.conversation;
        _loading = false;
        _error = null;
        _messages = merged;
      });

      if (initial || data.messages.isNotEmpty) {
        _scrollToBottom();
      }
    } catch (error) {
      if (!mounted || !initial) return;
      setState(() {
        _loading = false;
        _error = error is ChatsApiException ? error.message : '$error';
      });
    } finally {
      _loadInFlight = false;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;

    _sending = true;
    _inputController.clear();
    setState(() {});

    try {
      final message = await _api.sendMessage(
        phone: widget.phoneNumber,
        conversationId: _conversation.id,
        body: text,
      );
      if (!mounted) return;
      setState(() {
        _messages = _mergeMessages(_messages, [message]);
        _sending = false;
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error is ChatsApiException ? error.message : '$error'),
          backgroundColor: const Color(0xFFFF5722),
        ),
      );
    }
  }

  Future<void> _reserve() async {
    if (_reserving || !_conversation.canReserve) return;

    setState(() => _reserving = true);
    try {
      final result = await _api.reserveFromChat(
        phone: widget.phoneNumber,
        conversationId: _conversation.id,
      );
      if (!mounted) return;
      setState(() {
        _conversation = result.conversation;
        _reserving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: const Color(0xFF00BFFF),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _reserving = false);

      if (error is PickupLimitException) {
        final activated = await showPickupPackOfferDialog(
          context,
          limitInfo: error.limitInfo,
          phoneNumber: widget.phoneNumber,
        );
        if (activated == true && mounted) {
          await _reserve();
        }
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error is ChatsApiException ? error.message : '$error'),
          backgroundColor: const Color(0xFFFF5722),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBlue,
      resizeToAvoidBottomInset: false,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppColors.midnightGlowGradient,
        ),
        child: KeyboardInsetPadding(
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                if (_conversation.canReserve) _buildReserveBanner(),
                if (_conversation.isReservedByMe) _buildReservedBanner(),
                Expanded(child: _buildMessages()),
                _buildInput(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context, _conversation),
            icon: const Icon(Icons.arrow_back, color: Color(0xFF00BFFF)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _conversation.counterpartyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                Text(
                  _conversation.listingTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFFFFFFFF).withOpacity(0.65),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReserveBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: PrimaryActionButton(
        label: _reserving ? 'Бронируем...' : 'Забронировать на 24 ч',
        height: 48,
        fontSize: 15,
        borderRadius: 14,
        icon: Icons.schedule,
        loading: _reserving,
        gradientColors: PrimaryActionButton.primaryShortGradient,
        onPressed: _reserving ? null : _reserve,
      ),
    );
  }

  Widget _buildReservedBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF9E9E9E).withOpacity(0.25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF9E9E9E)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF9E9E9E)),
            SizedBox(width: 8),
            Text(
              'Вы забронировали это объявление',
              style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00BFFF)));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Напишите первое сообщение.\nКогда договоритесь — нажмите «Забронировать».',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFFFFFFF).withOpacity(0.7),
              height: 1.4,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMine = message.senderId == widget.currentUserId;
        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            decoration: BoxDecoration(
              color: isMine
                  ? const Color(0xFF00BFFF).withOpacity(0.85)
                  : const Color(0xFF001F3F).withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isMine ? const Color(0xFF80DEEA) : const Color(0xFF00BFFF),
                width: 1.5,
              ),
            ),
            child: Text(
              message.body,
              style: const TextStyle(color: Color(0xFFFFFFFF), height: 1.35),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF001F3F).withOpacity(0.95),
        border: Border(top: BorderSide(color: const Color(0xFF00BFFF).withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _inputFocus,
              enabled: !_sending,
              style: const TextStyle(color: Color(0xFFFFFFFF)),
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Сообщение...',
                hintStyle: TextStyle(color: const Color(0xFFFFFFFF).withOpacity(0.45)),
                filled: true,
                fillColor: const Color(0xFF001F3F),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFF00BFFF), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFF80DEEA), width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sending ? null : _sendMessage,
            icon: _sending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00BFFF)),
                  )
                : const Icon(Icons.send_rounded, color: Color(0xFF00BFFF), size: 28),
          ),
        ],
      ),
    );
  }
}
