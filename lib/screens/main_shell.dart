import 'dart:async';

import 'package:flutter/material.dart';

import 'add_listing_screen.dart';
import 'chats_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'profile_screen.dart';
import '../services/auth_api.dart';
import '../services/chats_api.dart';
import '../services/refresh_intervals.dart';
import '../services/session_service.dart';
import '../services/users_api.dart';
import '../utils/responsive_layout.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/privacy_policy_update_dialog.dart';
import '../widgets/responsive_page_frame.dart';

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
  late int _currentIndex;
  final Set<int> _visitedTabs = {0};
  final ChatsApi _chatsApi = ChatsApi();
  final UsersApi _usersApi = UsersApi();
  final AuthApi _authApi = AuthApi();
  int _unreadChatCount = 0;
  Timer? _unreadPollTimer;
  bool _unreadLoadInFlight = false;
  bool _privacyCheckStarted = false;
  bool _privacyDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _refreshUnreadCount();
    _unreadPollTimer = Timer.periodic(RefreshIntervals.chats, (_) => _refreshUnreadCount());
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPrivacyConsent());
  }

  @override
  void dispose() {
    _unreadPollTimer?.cancel();
    _chatsApi.dispose();
    _usersApi.dispose();
    _authApi.dispose();
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

  Future<void> _checkPrivacyConsent() async {
    if (_privacyCheckStarted || _privacyDialogOpen || !mounted) return;
    _privacyCheckStarted = true;

    try {
      final user = await _usersApi.fetchProfile(phone: widget.phoneNumber);
      if (!mounted || user.hasCurrentPrivacyConsent) return;
      await _showPrivacyConsentDialog();
    } catch (_) {
      // Не блокируем приложение при ошибке сети — проверим при следующем входе.
    }
  }

  Future<void> _showPrivacyConsentDialog() async {
    if (_privacyDialogOpen || !mounted) return;
    _privacyDialogOpen = true;

    final accepted = await showPrivacyPolicyUpdateDialog(context);
    if (!mounted) {
      _privacyDialogOpen = false;
      return;
    }

    if (accepted == true) {
      try {
        await _usersApi.acceptPrivacyConsent(phone: widget.phoneNumber);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Согласие на обработку ПДн сохранено'),
            backgroundColor: Color(0xFF00BFFF),
          ),
        );
      } catch (error) {
        if (!mounted) return;
        _privacyCheckStarted = false;
        _privacyDialogOpen = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is UsersApiException ? error.message : 'Не удалось сохранить согласие',
            ),
            backgroundColor: const Color(0xFFFF5722),
          ),
        );
        await _showPrivacyConsentDialog();
        return;
      }
    } else {
      await _authApi.logout();
      await SessionService.clear();
      if (!mounted) return;
      _privacyDialogOpen = false;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        (_) => false,
      );
      return;
    }

    _privacyDialogOpen = false;
  }

  void _onTabTap(int index) {
    setState(() {
      _visitedTabs.add(index);
      _currentIndex = index;
    });
    if (index == 3) {
      _refreshUnreadCount();
    }
  }

  Widget _tabChild(int index) {
    if (!_visitedTabs.contains(index)) {
      return const SizedBox.shrink();
    }
    switch (index) {
      case 0:
        return HomeScreen(
          userName: widget.userName,
          phoneNumber: widget.phoneNumber,
          userId: widget.userId,
          inShell: true,
          isActiveTab: _currentIndex == 0,
        );
      case 1:
        return FavoritesScreen(
          phoneNumber: widget.phoneNumber,
          currentUserId: widget.userId,
          inShell: true,
          isActiveTab: _currentIndex == 1,
        );
      case 2:
        return AddListingScreen(
          phoneNumber: widget.phoneNumber,
          inShell: true,
          onPublished: () => setState(() => _currentIndex = 0),
        );
      case 3:
        return ChatsScreen(
          phoneNumber: widget.phoneNumber,
          currentUserId: widget.userId,
          inShell: true,
          isActiveTab: _currentIndex == 3,
        );
      case 4:
        return ProfileScreen(
          userName: widget.userName,
          phoneNumber: widget.phoneNumber,
          inShell: true,
          isActiveTab: _currentIndex == 4,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return MidnightGlowScreen(
      bottomNavigationBar: isDesktop ? null : _buildMobileBottomNav(context),
      child: isDesktop ? _buildDesktopBody(context) : _buildMobileBody(),
    );
  }

  Widget _buildMobileBody() {
    return IndexedStack(
      index: _currentIndex,
      children: List.generate(5, _tabChild),
    );
  }

  Widget _buildDesktopBody(BuildContext context) {
    return SafeArea(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DesktopSidebar(
            currentIndex: _currentIndex,
            unreadChatCount: _unreadChatCount,
            onTabTap: _onTabTap,
          ),
          Expanded(
            child: ResponsivePageFrame(
              child: IndexedStack(
                index: _currentIndex,
                children: List.generate(5, _tabChild),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBottomNav(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
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
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.currentIndex,
    required this.unreadChatCount,
    required this.onTabTap,
  });

  final int currentIndex;
  final int unreadChatCount;
  final ValueChanged<int> onTabTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: const Color(0xFF001F3F).withOpacity(0.95),
        border: Border(
          right: BorderSide(color: const Color(0xFF00BFFF).withOpacity(0.25)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF66D9FF), Color(0xFF00BFFF)],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.35)),
                  ),
                  child: const Center(
                    child: Text(
                      'D',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Даром',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _DesktopNavTile(
            icon: Icons.home_rounded,
            label: 'Главная',
            selected: currentIndex == 0,
            onTap: () => onTabTap(0),
          ),
          _DesktopNavTile(
            icon: Icons.favorite_rounded,
            label: 'Избранное',
            selected: currentIndex == 1,
            onTap: () => onTabTap(1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Material(
              elevation: 6,
              shadowColor: const Color(0xFF00BFFF).withOpacity(0.45),
              borderRadius: BorderRadius.circular(14),
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTabTap(2),
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: currentIndex == 2
                          ? const [Color(0xFF66D9FF), Color(0xFF00BFFF), Color(0xFF0088CC)]
                          : const [Color(0xFF9AE6FF), Color(0xFF80DEEA), Color(0xFF4DB6AC)],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.35)),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 26),
                      SizedBox(height: 6),
                      Text(
                        'Добавить\nобъявление',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _DesktopNavTile(
            icon: Icons.chat_bubble_rounded,
            label: 'Чаты',
            selected: currentIndex == 3,
            badgeCount: unreadChatCount,
            onTap: () => onTabTap(3),
          ),
          _DesktopNavTile(
            icon: Icons.person_rounded,
            label: 'Профиль',
            selected: currentIndex == 4,
            onTap: () => onTabTap(4),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Text(
              'darom-app.online',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopNavTile extends StatelessWidget {
  const _DesktopNavTile({
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: selected ? const Color(0xFF00BFFF).withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Icon(icon, size: 24, color: color),
                      if (badgeCount > 0)
                        Positioned(
                          right: -6,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5722),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: Text(
                              badgeLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    badgeCount > 0 ? '$label ($badgeCount)' : label,
                    style: TextStyle(
                      color: badgeCount > 0 ? const Color(0xFFFF5722) : color,
                      fontSize: 15,
                      fontWeight: selected || badgeCount > 0 ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
