import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'add_listing_screen.dart';
import 'chats_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import '../services/chats_api.dart';
import '../services/push_service.dart';
import '../services/refresh_intervals.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/push_permission_dialog.dart';

/// Главная оболочка приложения с нижним меню на всех вкладках.
class MainShell extends StatefulWidget {
  final String userName;
  final String phoneNumber;
  final String? userId;
  final int initialIndex;

  const MainShell({
    super.key,
    required this.userName,
    required this.phoneNumber,
    this.userId,
    this.initialIndex = 0,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _pushPromptDismissedKey = 'push_prompt_dismissed_v1';

  late int _currentIndex;
  final ChatsApi _chatsApi = ChatsApi();
  int _unreadChatCount = 0;
  Timer? _unreadPollTimer;
  bool _unreadLoadInFlight = false;
  bool _pushSetupStarted = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _refreshUnreadCount();
    _unreadPollTimer = Timer.periodic(RefreshIntervals.chats, (_) => _refreshUnreadCount());
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupPushNotifications());
  }

  Future<void> _setupPushNotifications() async {
    if (_pushSetupStarted) return;
    _pushSetupStarted = true;

    final status = await PushService.instance.getPermissionStatus();
    if (status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional) {
      await PushService.instance.registerIfAlreadyAuthorized(phone: widget.phoneNumber);
      return;
    }

    if (status == AuthorizationStatus.denied) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_pushPromptDismissedKey) == true) {
      return;
    }

    if (!mounted) return;
    final enable = await showPushPermissionDialog(context);
    if (!mounted) return;

    if (enable == true) {
      final result = await PushService.instance.requestPermissionAndRegister(
        phone: widget.phoneNumber,
      );
      if (!mounted) return;
      _showPushResultSnackBar(result);
      return;
    }

    await prefs.setBool(_pushPromptDismissedKey, true);
  }

  void _showPushResultSnackBar(PushRegisterResult result) {
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case PushRegisterResult.success:
      case PushRegisterResult.alreadyRegistered:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Уведомления включены'),
            backgroundColor: Color(0xFF00BFFF),
          ),
        );
      case PushRegisterResult.denied:
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Уведомления выключены. Включите их в настройках браузера для darom-app.online',
            ),
            backgroundColor: Color(0xFFFF5722),
            duration: Duration(seconds: 6),
          ),
        );
      case PushRegisterResult.notConfigured:
      case PushRegisterResult.failed:
        final detail = PushService.lastErrorMessage;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              detail != null && detail.isNotEmpty
                  ? 'Не удалось включить уведомления: $detail'
                  : 'Не удалось включить уведомления. Попробуйте позже в профиле',
            ),
            backgroundColor: Color(0xFFFF5722),
            duration: Duration(seconds: 7),
          ),
        );
    }
  }

  @override
  void dispose() {
    _unreadPollTimer?.cancel();
    _chatsApi.dispose();
    super.dispose();
  }

  Future<void> _refreshUnreadCount() async {
    if (_unreadLoadInFlight) return;
    _unreadLoadInFlight = true;
    try {
      final count = await _chatsApi.fetchUnreadSummary(phone: widget.phoneNumber);
      if (!mounted || count == _unreadChatCount) return;
      setState(() => _unreadChatCount = count);
    } catch (_) {
      // Бейдж необязателен — не ломаем меню при ошибке сети.
    } finally {
      _unreadLoadInFlight = false;
    }
  }

  void _onTabTap(int index) {
    setState(() => _currentIndex = index);
    if (index == 3) {
      _refreshUnreadCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return MidnightGlowScreen(
      bottomNavigationBar: Container(
        clipBehavior: Clip.none,
        decoration: BoxDecoration(
          color: const Color(0xFF001F3F).withOpacity(0.95),
          border: Border(
            top: BorderSide(color: const Color(0xFF00BFFF).withOpacity(0.25)),
          ),
        ),
        padding: EdgeInsets.only(top: 8, bottom: bottomInset > 0 ? bottomInset : 8),
        child: SizedBox(
          height: 62,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Главная',
                selected: _currentIndex == 0,
                onTap: () => _onTabTap(0),
              ),
              _NavItem(
                icon: Icons.favorite_rounded,
                label: 'Избранное',
                selected: _currentIndex == 1,
                onTap: () => _onTabTap(1),
              ),
              _NavAddItem(
                selected: _currentIndex == 2,
                onTap: () => _onTabTap(2),
              ),
              _NavItem(
                icon: Icons.chat_bubble_rounded,
                label: 'Чаты',
                selected: _currentIndex == 3,
                badgeCount: _unreadChatCount,
                onTap: () => _onTabTap(3),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Профиль',
                selected: _currentIndex == 4,
                onTap: () => _onTabTap(4),
              ),
            ],
          ),
        ),
      ),
      child: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            userName: widget.userName,
            phoneNumber: widget.phoneNumber,
            userId: widget.userId,
            inShell: true,
            isActiveTab: _currentIndex == 0,
          ),
          FavoritesScreen(
            phoneNumber: widget.phoneNumber,
            currentUserId: widget.userId,
            inShell: true,
          ),
          AddListingScreen(
            phoneNumber: widget.phoneNumber,
            inShell: true,
            onPublished: () => setState(() => _currentIndex = 0),
          ),
          ChatsScreen(
            phoneNumber: widget.phoneNumber,
            currentUserId: widget.userId,
            inShell: true,
            isActiveTab: _currentIndex == 3,
          ),
          ProfileScreen(
            userName: widget.userName,
            phoneNumber: widget.phoneNumber,
            inShell: true,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF00BFFF) : const Color(0xFF80DEEA);
    final badgeLabel = badgeCount > 99 ? '99+' : '$badgeCount';

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              height: 30,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(icon, size: 22, color: color),
                  if (badgeCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5722),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x88000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          badgeLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              badgeCount > 0 ? '$label ($badgeCount)' : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: badgeCount > 0 ? const Color(0xFFFF5722) : color,
                fontWeight: badgeCount > 0 || selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavAddItem extends StatelessWidget {
  const _NavAddItem({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? const Color(0xFF00BFFF) : const Color(0xFF80DEEA);

    return Expanded(
      child: SizedBox(
        height: 58,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              top: -14,
              child: Material(
                elevation: 8,
                shadowColor: const Color(0xFF00BFFF).withOpacity(0.5),
                shape: const CircleBorder(),
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: Ink(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: selected
                            ? const [Color(0xFF66D9FF), Color(0xFF00BFFF), Color(0xFF0088CC)]
                            : const [Color(0xFF9AE6FF), Color(0xFF80DEEA), Color(0xFF4DB6AC)],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.45),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                'Добавить',
                style: TextStyle(
                  fontSize: 10,
                  color: accent,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
