import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../data/profile_achievements.dart';
import '../models/user.dart';
import '../l10n/app_localizations.dart';
import '../services/locale_service.dart';
import '../widgets/language_picker.dart';
import '../services/auth_api.dart';
import '../services/session_service.dart';
import '../services/support_api.dart';
import '../services/users_api.dart';
import '../widgets/avatar_image.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/primary_action_button.dart';
import 'my_listings_screen.dart';
import 'onboarding_screen.dart';
import 'partner_stats_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_login_screen.dart';
import 'admin_daily_reports_screen.dart';
import 'admin_reports_screen.dart';
import 'support_screen.dart';
import 'about_app_screen.dart';
import 'public_offer_screen.dart';
import 'privacy_policy_screen.dart';
import 'cookie_policy_screen.dart';
import 'personal_data_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userName;
  final String? phoneNumber;
  final bool inShell;
  final bool isActiveTab;

  const ProfileScreen({
    super.key,
    this.userName,
    this.phoneNumber,
    this.inShell = false,
    this.isActiveTab = true,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UsersApi _usersApi = UsersApi();
  final AuthApi _authApi = AuthApi();
  final SupportApi _supportApi = SupportApi();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isEditPressed = false;
  bool _uploadingAvatar = false;
  Future<User>? _profileFuture;
  int _supportUnread = 0;
  int _adminSupportUnread = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isActiveTab) {
      _profileFuture = _loadProfile();
    }
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActiveTab && !oldWidget.isActiveTab && _profileFuture == null) {
      setState(() => _profileFuture = _loadProfile());
    }
  }

  @override
  void dispose() {
    _usersApi.dispose();
    _authApi.dispose();
    _supportApi.dispose();
    super.dispose();
  }

  Future<void> _refreshSupportUnread(User user) async {
    try {
      final userCount = await _supportApi.fetchUnreadSummary(phone: user.phoneNumber);
      var adminCount = 0;
      if (user.isSuperAdmin) {
        adminCount = await _supportApi.fetchAdminUnreadSummary();
      }
      if (!mounted) return;
      setState(() {
        _supportUnread = userCount;
        _adminSupportUnread = adminCount;
      });
    } catch (_) {}
  }

  Future<User> _loadProfile() {
    final phone = widget.phoneNumber;
    if (phone == null || phone.isEmpty) {
      return Future.error(AppLocalizations.of(context).errNoPhone);
    }
    return _usersApi.fetchProfile(phone: phone);
  }

  void _retry() {
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  Future<void> _pickAvatar(User user) async {
    if (_uploadingAvatar) return;

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await picked.readAsBytes();
      final updated = await _usersApi.uploadAvatar(
        phone: user.phoneNumber,
        bytes: bytes,
        fileName: picked.name,
      );
      if (!mounted) return;
      setState(() {
        _profileFuture = Future.value(updated);
        _uploadingAvatar = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).avatarUpdated),
          backgroundColor: Color(0xFF00BFFF),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error is UsersApiException ? error.message : '$error'),
          backgroundColor: const Color(0xFFFF5722),
        ),
      );
    }
  }

  Future<void> _deleteAccount(User user) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF001F3F),
        title: Text(l10n.deleteAccountTitle, style: const TextStyle(color: Colors.white)),
        content: Text(
          l10n.deleteAccountBody,
          style: TextStyle(color: Colors.white.withOpacity(0.9)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: const TextStyle(color: Color(0xFF80DEEA))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteButton, style: const TextStyle(color: Color(0xFFFF5722))),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _usersApi.deleteAccount(phone: user.phoneNumber);
      await _authApi.logout();
      await SessionService.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error is UsersApiException ? error.message : '$error'),
          backgroundColor: const Color(0xFFFF5722),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await _authApi.logout();
    await SessionService.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      (_) => false,
    );
  }

  void _openAdminPanel(String phoneNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminLoginScreen(
          prefilledPhone: phoneNumber,
          showBackButton: true,
          onLoggedIn: (session) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AdminDashboardScreen(
                  session: session,
                  showBackToApp: true,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAchievementTile(ProfileAchievement achievement, User user) {
    final l10n = AppLocalizations.of(context);
    final unlocked = achievement.isUnlocked(user);
    final color = unlocked ? achievement.color : const Color(0xFF607D8B);
    final width = unlocked ? 80.0 : 56.0;
    final iconSize = unlocked ? 30.0 : 18.0;
    final fontSize = unlocked ? 10.0 : 8.0;

    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: unlocked
            ? color.withOpacity(0.2)
            : const Color(0xFF607D8B).withOpacity(0.12),
        borderRadius: BorderRadius.circular(unlocked ? 12 : 10),
        border: Border.all(
          color: unlocked ? color : const Color(0xFF607D8B).withOpacity(0.35),
          width: unlocked ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            achievement.icon,
            size: iconSize,
            color: unlocked ? color : const Color(0xFF90A4AE),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.achievementTitle(achievement.title),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: unlocked ? FontWeight.bold : FontWeight.w500,
              color: unlocked ? color : const Color(0xFF90A4AE),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = SafeArea(
            child: FutureBuilder<User>(
              future: _profileFuture,
              builder: (context, snapshot) {
                if (_profileFuture == null ||
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00BFFF)),
                  );
                }

            if (snapshot.hasError || !snapshot.hasData) {
              final l10n = AppLocalizations.of(context);
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off, size: 48, color: Color(0xFF00BFFF)),
                      const SizedBox(height: 16),
                      Text(
                        snapshot.error?.toString() ?? l10n.errLoadProfile,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFFFFFFFF).withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      PrimaryActionButton(
                        label: l10n.repeatButton,
                        height: 48,
                        fontSize: 16,
                        borderRadius: 24,
                        gradientColors: PrimaryActionButton.primaryShortGradient,
                        onPressed: _retry,
                      ),
                      const SizedBox(height: 12),
                      PrimaryActionButton(
                        label: l10n.logoutAndLoginAgain,
                        height: 48,
                        fontSize: 16,
                        borderRadius: 24,
                        gradientColors: PrimaryActionButton.dangerDeepGradient,
                        shadowColor: const Color(0xFFFF5722),
                        onPressed: _logout,
                      ),
                    ],
                  ),
                ),
              );
            }

            final user = snapshot.data!;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && widget.isActiveTab) {
                _refreshSupportUnread(user);
              }
            });
            return _buildContent(user);
          },
        ),
    );
    if (widget.inShell) return child;
    return MidnightGlowScreen(child: child);
  }

  Widget _buildAvatar(User user) {
    return GestureDetector(
      onTap: _uploadingAvatar ? null : () => _pickAvatar(user),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AvatarImage(
            url: user.avatarUrl,
            size: 100,
            borderColor: const Color(0xFF008C8C),
          ),
          if (_uploadingAvatar)
            const SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF00BFFF),
              ),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF001F3F),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00BFFF), width: 2),
              ),
              child: const Icon(Icons.camera_alt, color: Color(0xFF00BFFF), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(User user) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        if (!widget.inShell) ...[
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: Color(0xFF001F3F).withOpacity(0.85),
                                shape: BoxShape.circle,
                                border: Border.all(color: Color(0xFF00BFFF), width: 2),
                              ),
                              child: Icon(Icons.arrow_back, color: Color(0xFF00BFFF)),
                            ),
                          )
                              .animate(
                                delay: Duration(milliseconds: 200),
                              )
                              .fadeIn(duration: Duration(milliseconds: 600))
                              .scale(begin: Offset(0.8, 0.8), end: Offset(1.0, 1.0)),
                          SizedBox(width: 15),
                        ],
                        Expanded(
                          child: Text(
                            l10n.profileTitle,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFFFFF),
                              shadows: [
                                Shadow(
                                  color: Color(0xFF00BFFF).withOpacity(0.6),
                                  offset: Offset(0, 4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          )
                              .animate(
                                delay: Duration(milliseconds: 300),
                              )
                              .fadeIn(duration: Duration(milliseconds: 800))
                              .slideX(begin: -0.3, end: 0),
                        ),
                        GestureDetector(
                          onTapDown: (_) => setState(() => _isEditPressed = true),
                          onTapUp: (_) {
                            setState(() => _isEditPressed = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.editProfileSoon),
                                backgroundColor: Color(0xFF00BFFF),
                              ),
                            );
                          },
                          onTapCancel: () => setState(() => _isEditPressed = false),
                          child: AnimatedScale(
                            scale: _isEditPressed ? 1.08 : 1.0,
                            duration: Duration(milliseconds: 150),
                            curve: Curves.easeOut,
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: Color(0xFF001F3F).withOpacity(0.85),
                                shape: BoxShape.circle,
                                border: Border.all(color: Color(0xFF00BFFF), width: 2),
                              ),
                              child: Icon(Icons.edit, color: Color(0xFF00BFFF)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // Аватар и имя
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Color(0xFF001F3F).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Color(0xFF00BFFF), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF00BFFF).withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildAvatar(user),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.tapPhotoToChange,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFFFFFFFF).withOpacity(0.55),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  user.name,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFFFFFF),
                                    shadows: [
                                      Shadow(
                                        color: Color(0xFF00BFFF).withOpacity(0.6),
                                        offset: Offset(0, 4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  user.phoneNumber,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFFFFFFFF).withOpacity(0.7),
                                  ),
                                ),
                                if (user.isFounder) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFC107).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFFFC107)),
                                    ),
                                    child: Text(
                                      l10n.founderBadge,
                                      style: TextStyle(
                                        color: Color(0xFFFFC107),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                                if (user.isPartner) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF80DEEA).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF80DEEA)),
                                    ),
                                    child: Text(
                                      l10n.partnerBadge,
                                      style: TextStyle(
                                        color: Color(0xFF80DEEA),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                                SizedBox(height: 10),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF00BFFF),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star, color: Colors.white, size: 16),
                                      SizedBox(width: 5),
                                      Text(
                                        '${l10n.donorLevelLabel(user.donorLevel)} • ${user.rating}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate(
                                delay: Duration(milliseconds: 400),
                              )
                              .fadeIn(duration: Duration(milliseconds: 800))
                              .slideY(begin: 0.3, end: 0),
                          
                          SizedBox(height: 20),

                          // Статистика
                          Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Color(0xFF001F3F).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Color(0xFF008C8C), width: 2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(Icons.inventory_2, '${user.activeListings}/${user.listingLimit}', l10n.statListings),
                                Container(
                                  width: 1,
                                  height: 50,
                                  color: Color(0xFF00BFFF).withOpacity(0.3),
                                ),
                                _buildStatItem(Icons.handshake, '${user.dealsCount}', l10n.statDeals),
                                Container(
                                  width: 1,
                                  height: 50,
                                  color: Color(0xFF00BFFF).withOpacity(0.3),
                                ),
                                _buildStatItem(
                                  Icons.shopping_bag_outlined,
                                  '${user.pickupsUsedThisMonth}/${user.pickupLimit}',
                                  l10n.statPickups,
                                ),
                              ],
                            ),
                          )
                              .animate(
                                delay: Duration(milliseconds: 500),
                              )
                              .fadeIn(duration: Duration(milliseconds: 800))
                              .slideY(begin: 0.3, end: 0),
                          
                          SizedBox(height: 20),

                          // Достижения
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.achievementsTitle,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFFFFFF),
                                  ),
                                ),
                                Text(
                                  '${ProfileAchievements.unlockedCount(user)}/${ProfileAchievements.all.length}',
                                  style: TextStyle(
                                    color: Color(0xFF00BFFF),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),

                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Color(0xFF001F3F).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Color(0xFF00BFFF), width: 2),
                            ),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.all(15),
                              itemCount: ProfileAchievements.all.length,
                              itemBuilder: (context, index) {
                                return _buildAchievementTile(
                                  ProfileAchievements.all[index],
                                  user,
                                );
                              },
                            ),
                          )
                              .animate(
                                delay: Duration(milliseconds: 600),
                              )
                              .fadeIn(duration: Duration(milliseconds: 800))
                              .slideY(begin: 0.3, end: 0),
                          
                          SizedBox(height: 20),

                          // Настройки
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFF001F3F).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Color(0xFF00BFFF), width: 2),
                            ),
                            child: Column(
                              children: [
                                _buildSettingsItem(
                                  Icons.language,
                                  AppLocalizations.of(context).languageTitle,
                                  subtitle: LocaleService.instance.languageLabel,
                                  onTap: () => showLanguagePickerDialog(context),
                                ),
                                Divider(color: Color(0xFF00BFFF).withOpacity(0.3), height: 1),
                                _buildSettingsItem(
                                  Icons.inventory_2_outlined,
                                  AppLocalizations.of(context).myListings,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MyListingsScreen(
                                          phoneNumber: user.phoneNumber,
                                          currentUserId: user.id,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                if (user.isPartner) ...[
                                  Divider(color: Color(0xFF00BFFF).withOpacity(0.3), height: 1),
                                  _buildSettingsItem(
                                    Icons.analytics_outlined,
                                    AppLocalizations.of(context).partnerStats,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PartnerStatsScreen(
                                            phoneNumber: user.phoneNumber,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                                if (user.canAccessAdminPanel) ...[
                                  Divider(color: Color(0xFF00BFFF).withOpacity(0.3), height: 1),
                                  _buildSettingsItem(
                                    Icons.flag_outlined,
                                    l10n.adminReports,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const AdminReportsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                                if (user.isSuperAdmin) ...[
                                  Divider(color: Color(0xFF00BFFF).withOpacity(0.3), height: 1),
                                  _buildSettingsItem(
                                    Icons.bar_chart_outlined,
                                    l10n.adminDailyStats,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const AdminDailyReportsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  Divider(color: Color(0xFF00BFFF).withOpacity(0.3), height: 1),
                                  _buildSettingsItem(
                                    Icons.support_agent_outlined,
                                    l10n.adminUserRequests,
                                    badgeCount: _adminSupportUnread,
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SupportScreen(
                                            phoneNumber: user.phoneNumber,
                                            isAdminMode: true,
                                          ),
                                        ),
                                      );
                                      if (mounted) _refreshSupportUnread(user);
                                    },
                                  ),
                                  Divider(color: Color(0xFF00BFFF).withOpacity(0.3), height: 1),
                                  _buildSettingsItem(
                                    Icons.admin_panel_settings_outlined,
                                    l10n.adminPanel,
                                    onTap: () => _openAdminPanel(user.phoneNumber),
                                  ),
                                ],
                                Divider(color: Color(0xFF00BFFF).withOpacity(0.3), height: 1),
                                _buildSettingsItem(
                                  Icons.support_agent_outlined,
                                  AppLocalizations.of(context).support,
                                  badgeCount: _supportUnread,
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SupportScreen(
                                          phoneNumber: user.phoneNumber,
                                        ),
                                      ),
                                    );
                                    if (mounted) _refreshSupportUnread(user);
                                  },
                                ),
                                Divider(color: Color(0xFF00BFFF).withOpacity(0.3), height: 1),
                                _buildSettingsItem(
                                  Icons.policy_outlined,
                                  AppLocalizations.of(context).publicOffer,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const PublicOfferScreen(),
                                      ),
                                    );
                                  },
                                ),
                                Divider(color: Color(0xFF00BFFF).withOpacity(0.3), height: 1),
                                _buildSettingsItem(
                                  Icons.privacy_tip_outlined,
                                  AppLocalizations.of(context).privacyPolicyMenu,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const PrivacyPolicyScreen(),
                                      ),
                                    );
                                  },
                                ),
                                Divider(color: Color(0xFF00BFFF).withOpacity(0.3), height: 1),
                                _buildSettingsItem(
                                  Icons.article_outlined,
                                  AppLocalizations.of(context).cookiePolicyMenu,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const CookiePolicyScreen(),
                                      ),
                                    );
                                  },
                                ),
                                Divider(color: Color(0xFF00BFFF).withOpacity(0.3), height: 1),
                                _buildSettingsItem(
                                  Icons.folder_shared_outlined,
                                  AppLocalizations.of(context).myPersonalData,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PersonalDataScreen(
                                          phoneNumber: user.phoneNumber,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Divider(color: Color(0xFF00BFFF).withOpacity(0.3), height: 1),
                                _buildSettingsItem(
                                  Icons.info,
                                  AppLocalizations.of(context).aboutApp,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AboutAppScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          )
                              .animate(
                                delay: Duration(milliseconds: 700),
                              )
                              .fadeIn(duration: Duration(milliseconds: 800))
                              .slideY(begin: 0.3, end: 0),
                          
                          SizedBox(height: 12),

                          PrimaryActionButton(
                            label: AppLocalizations.of(context).deleteAccount,
                            height: 50,
                            fontSize: 16,
                            borderRadius: 25,
                            gradientColors: const [
                              Color(0xFF8B0000),
                              Color(0xFFFF5722),
                            ],
                            shadowColor: const Color(0xFFFF5722),
                            onPressed: () => _deleteAccount(user),
                          )
                              .animate(
                                delay: Duration(milliseconds: 750),
                              )
                              .fadeIn(duration: Duration(milliseconds: 800))
                              .slideY(begin: 0.3, end: 0),

                          SizedBox(height: 12),

                          PrimaryActionButton(
                            label: l10n.logoutProfile,
                            height: 55,
                            fontSize: 18,
                            borderRadius: 27,
                            gradientColors: PrimaryActionButton.dangerDeepGradient,
                            shadowColor: const Color(0xFFFF5722),
                            onPressed: _logout,
                          )
                              .animate(
                                delay: Duration(milliseconds: 800),
                              )
                              .fadeIn(duration: Duration(milliseconds: 800))
                              .slideY(begin: 0.3, end: 0),
                          
                          SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Color(0xFF00BFFF), size: 28),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFFFFF),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFFFFFFFF).withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    IconData icon,
    String title, {
    VoidCallback? onTap,
    int badgeCount = 0,
    String? subtitle,
  }) {
    return InkWell(
      onTap: onTap ?? () {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.comingSoon(title)),
            backgroundColor: Color(0xFF00BFFF),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: Color(0xFF00BFFF), size: 24),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFFFFFFF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF80DEEA).withOpacity(0.9),
                      ),
                    ),
                ],
              ),
            ),
            if (badgeCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5722),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFFFFFFFF).withOpacity(0.4),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}