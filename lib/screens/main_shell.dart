import 'dart:async';

import 'package:flutter/material.dart';
import 'package:darom_app/theme/app_colors.dart';
import 'package:darom_app/theme/darom_decorations.dart';

import 'add_listing_screen.dart';
import 'chats_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'profile_screen.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_api.dart';
import '../services/chats_api.dart';
import '../services/refresh_intervals.dart';
import '../services/session_service.dart';
import '../services/users_api.dart';
import '../utils/responsive_layout.dart';
import '../widgets/glass_surface.dart';
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
    _startUnreadPoll();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPrivacyConsent());
  }

  Duration get _unreadPollInterval => _currentIndex == 3
      ? RefreshIntervals.chatsList
      : RefreshIntervals.chatsBackground;

  void _startUnreadPoll() {
    _unreadPollTimer?.cancel();
    _unreadPollTimer = Timer.periodic(_unreadPollInterval, (_) => _refreshUnreadCount());
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
          SnackBar(
            content: Text(AppLocalizations.of(context).privacyConsentSaved),
            backgroundColor: AppColors.accent,
          ),
        );
      } catch (error) {
        if (!mounted) return;
        _privacyCheckStarted = false;
        _privacyDialogOpen = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is UsersApiException
                  ? error.message
                  : AppLocalizations.of(context).errPrivacyConsentSave,
            ),
            backgroundColor: AppColors.danger,
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
    _startUnreadPoll();
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
    final l10n = AppLocalizations.of(context);

    return MidnightGlowScreen(
      bottomNavigationBar: isDesktop ? null : _buildMobileBottomNav(context, l10n),
      child: isDesktop ? _buildDesktopBody(context, l10n) : _buildMobileBody(),
    );
  }

  Widget _buildMobileBody() {
    return IndexedStack(
      index: _currentIndex,
      children: List.generate(5, _tabChild),
    );
  }

  Widget _buildDesktopBody(BuildContext context, AppLocalizations l10n) {
    return SafeArea(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DesktopSidebar(
            currentIndex: _currentIndex,
            unreadChatCount: _unreadChatCount,
            onTabTap: _onTabTap,
            l10n: l10n,
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

  Widget _buildMobileBottomNav(BuildContext context, AppLocalizations l10n) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(DaromDecorations.screenPaddingH, 0, DaromDecorations.screenPaddingH, 8),
        child: GlassSurface(
          borderRadius: DaromDecorations.navBarRadius,
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 10),
          child: SizedBox(
            height: 72,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: l10n.navHome,
                selected: _currentIndex == 0,
                onTap: () => _onTabTap(0),
              ),
              _NavItem(
                icon: Icons.favorite_rounded,
                label: l10n.navFavorites,
                selected: _currentIndex == 1,
                onTap: () => _onTabTap(1),
              ),
              _NavAddItem(
                selected: _currentIndex == 2,
                onTap: () => _onTabTap(2),
              ),
              _NavItem(
                icon: Icons.chat_bubble_rounded,
                label: l10n.navChats,
                selected: _currentIndex == 3,
                badgeCount: _unreadChatCount,
                onTap: () => _onTabTap(3),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: l10n.navProfile,
                selected: _currentIndex == 4,
                onTap: () => _onTabTap(4),
              ),
              ],
            ),
          ),
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
    required this.l10n,
  });

  final int currentIndex;
  final int unreadChatCount;
  final ValueChanged<int> onTabTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 10, 16),
      child: GlassSurface(
        borderRadius: DaromDecorations.navBarRadius,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
        width: 232,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.brandGradient,
                  ),
                  child: const Center(
                    child: Text(
                      'D',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        letterSpacing: -0.02,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Даром',
                  style: DaromDecorations.titleStyle(fontSize: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _DesktopNavTile(
            icon: Icons.home_rounded,
            label: l10n.navHome,
            selected: currentIndex == 0,
            onTap: () => onTabTap(0),
          ),
          _DesktopNavTile(
            icon: Icons.favorite_rounded,
            label: l10n.navFavorites,
            selected: currentIndex == 1,
            onTap: () => onTabTap(1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTabTap(2),
                borderRadius: BorderRadius.circular(DaromDecorations.buttonRadius),
                child: Ink(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DaromDecorations.buttonRadius),
                    gradient: AppColors.brandGradient,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded, color: AppColors.white, size: 22),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          l10n.navAddListing,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            height: 1.2,
                            letterSpacing: -0.01,
                          ),
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
            label: l10n.navChats,
            selected: currentIndex == 3,
            badgeCount: unreadChatCount,
            onTap: () => onTabTap(3),
          ),
          _DesktopNavTile(
            icon: Icons.person_rounded,
            label: l10n.navProfile,
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
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
        ),
        ),
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
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    final badgeLabel = badgeCount > 99 ? '99+' : '$badgeCount';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Material(
        color: selected ? AppColors.navActiveTint : Colors.transparent,
        borderRadius: BorderRadius.circular(DaromDecorations.buttonRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DaromDecorations.buttonRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Icon(icon, size: 22, color: color),
                      if (badgeCount > 0)
                        Positioned(
                          right: -6,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badgeLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.white,
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
                      color: badgeCount > 0 ? AppColors.primary : color,
                      fontSize: 14,
                      fontWeight: selected || badgeCount > 0 ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: -0.01,
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
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    final badgeLabel = badgeCount > 99 ? '99+' : '$badgeCount';

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
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
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badgeLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.white,
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
                fontSize: 11,
                color: badgeCount > 0 ? AppColors.primary : color,
                fontWeight: badgeCount > 0 || selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
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
    final l10n = AppLocalizations.of(context);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: const Offset(0, -12),
              child: Material(
                color: Colors.transparent,
                elevation: 0,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: Ink(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.brandGradient,
                      boxShadow: DaromDecorations.cardShadow,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppColors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.navAdd,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
