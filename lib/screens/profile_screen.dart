import 'package:darom_app/theme/darom_decorations.dart';
import 'package:flutter/material.dart';
import 'package:darom_app/theme/app_colors.dart';
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

  /// Один запрос счётчиков поддержки на загрузку профиля: build вызывается часто,
  /// а setState из ответа снова запускал бы build — бесконечный цикл запросов.
  bool _supportUnreadRequested = false;

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
    _supportUnreadRequested = false;
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
          backgroundColor: AppColors.accent,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error is UsersApiException ? error.message : '$error'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _deleteAccount(User user) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.deleteAccountTitle, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          l10n.deleteAccountBody,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteButton, style: const TextStyle(color: AppColors.danger)),
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
          backgroundColor: AppColors.danger,
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
    final color = achievement.color;
    final tint = Color.alphaBlend(color.withOpacity(unlocked ? 0.12 : 0.06), AppColors.surface);

    return Container(
      width: 112,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
      decoration: BoxDecoration(
        color: unlocked ? tint : AppColors.background,
        borderRadius: BorderRadius.circular(DaromDecorations.cardRadius),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unlocked ? color : tint,
                ),
                child: Icon(
                  achievement.icon,
                  size: 32,
                  color: unlocked ? AppColors.white : color.withOpacity(0.55),
                ),
              ),
              if (!unlocked)
                Positioned(
                  right: -4,
                  bottom: -2,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      boxShadow: DaromDecorations.cardShadow,
                    ),
                    child: const Icon(Icons.lock_rounded, size: 14, color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.achievementTitle(achievement.title),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: unlocked ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            unlocked
                ? (l10n.isEn ? 'Received' : 'Получено')
                : (l10n.isEn ? achievement.requirementEn : achievement.requirementRu),
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: unlocked ? color : AppColors.textSecondary,
            ),
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
                    child: CircularProgressIndicator(color: AppColors.accent),
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
                      const Icon(Icons.cloud_off, size: 48, color: AppColors.accent),
                      const SizedBox(height: 16),
                      Text(
                        snapshot.error?.toString() ?? l10n.errLoadProfile,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary.withOpacity(0.7),
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
                        shadowColor: AppColors.danger,
                        onPressed: _logout,
                      ),
                    ],
                  ),
                ),
              );
            }

            final user = snapshot.data!;
            if (!_supportUnreadRequested) {
              _supportUnreadRequested = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && widget.isActiveTab) {
                  _refreshSupportUnread(user);
                }
              });
            }
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
            borderColor: AppColors.accentDark,
          ),
          if (_uploadingAvatar)
            const SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.accent,
              ),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: DaromDecorations.cardShadow,
              ),
              child: const Icon(Icons.camera_alt_outlined, color: AppColors.textPrimary, size: 17),
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
                              decoration: const BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                boxShadow: DaromDecorations.cardShadow,
                              ),
                              child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
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
                            style: DaromDecorations.titleStyle(fontSize: 24),
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
                                backgroundColor: AppColors.accent,
                              ),
                            );
                          },
                          onTapCancel: () => setState(() => _isEditPressed = false),
                          child: AnimatedScale(
                            scale: _isEditPressed ? 1.08 : 1.0,
                            duration: Duration(milliseconds: 150),
                            curve: Curves.easeOut,
                            child: const SizedBox(
                              width: 45,
                              height: 45,
                              child: Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 22),
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
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: DaromDecorations.solidCard(),
                            child: Column(
                              children: [
                                _buildAvatar(user),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.tapPhotoToChange,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textPrimary.withOpacity(0.55),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  user.name,
                                  style: DaromDecorations.titleStyle(fontSize: 22),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  user.phoneNumber,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (user.isFounder) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.badgeFounderBg,
                                      borderRadius: BorderRadius.circular(DaromDecorations.pillRadius),
                                    ),
                                    child: Text(
                                      l10n.founderBadge,
                                      style: const TextStyle(
                                        color: AppColors.badgeFounderText,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                                if (user.isPartner) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.tabTrack,
                                      borderRadius: BorderRadius.circular(DaromDecorations.pillRadius),
                                    ),
                                    child: Text(
                                      l10n.partnerBadge,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                                SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.badgeNewbieBg,
                                    borderRadius: BorderRadius.circular(DaromDecorations.pillRadius),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, color: AppColors.badgeNewbieText, size: 16),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${l10n.donorLevelLabel(user.donorLevel)} • ${user.rating}',
                                        style: const TextStyle(
                                          color: AppColors.badgeNewbieText,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
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
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                            decoration: DaromDecorations.solidCard(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(Icons.inventory_2_outlined, '${user.activeListings}/${user.listingLimit}', l10n.statListings),
                                Container(
                                  width: 1,
                                  height: 48,
                                  color: AppColors.borderDivider,
                                ),
                                _buildStatItem(Icons.handshake_outlined, '${user.dealsCount}', l10n.statDeals),
                                Container(
                                  width: 1,
                                  height: 48,
                                  color: AppColors.borderDivider,
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
                                  style: DaromDecorations.titleStyle(fontSize: 18),
                                ),
                                Text(
                                  '${ProfileAchievements.unlockedCount(user)}/${ProfileAchievements.all.length}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),

                          Container(
                            height: 196,
                            decoration: DaromDecorations.solidCard(),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.all(12),
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
                            clipBehavior: Clip.antiAlias,
                            decoration: DaromDecorations.solidCard(),
                            child: Column(
                              children: [
                                _buildSettingsItem(
                                  Icons.language,
                                  AppLocalizations.of(context).languageTitle,
                                  subtitle: LocaleService.instance.languageLabel,
                                  onTap: () => showLanguagePickerDialog(context),
                                ),
                                const Divider(color: AppColors.borderDivider, height: 1, thickness: 1, indent: 59),
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
                                  const Divider(color: AppColors.borderDivider, height: 1, thickness: 1, indent: 59),
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
                                  const Divider(color: AppColors.borderDivider, height: 1, thickness: 1, indent: 59),
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
                                  const Divider(color: AppColors.borderDivider, height: 1, thickness: 1, indent: 59),
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
                                  const Divider(color: AppColors.borderDivider, height: 1, thickness: 1, indent: 59),
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
                                  const Divider(color: AppColors.borderDivider, height: 1, thickness: 1, indent: 59),
                                  _buildSettingsItem(
                                    Icons.admin_panel_settings_outlined,
                                    l10n.adminPanel,
                                    onTap: () => _openAdminPanel(user.phoneNumber),
                                  ),
                                ],
                                const Divider(color: AppColors.borderDivider, height: 1, thickness: 1, indent: 59),
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
                                const Divider(color: AppColors.borderDivider, height: 1, thickness: 1, indent: 59),
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
                                const Divider(color: AppColors.borderDivider, height: 1, thickness: 1, indent: 59),
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
                                const Divider(color: AppColors.borderDivider, height: 1, thickness: 1, indent: 59),
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
                                const Divider(color: AppColors.borderDivider, height: 1, thickness: 1, indent: 59),
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
                                const Divider(color: AppColors.borderDivider, height: 1, thickness: 1, indent: 59),
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
                            label: l10n.logoutProfile,
                            height: 52,
                            fontSize: 16,
                            gradientColors: PrimaryActionButton.neutralGradient,
                            onPressed: _logout,
                          )
                              .animate(
                                delay: Duration(milliseconds: 750),
                              )
                              .fadeIn(duration: Duration(milliseconds: 800))
                              .slideY(begin: 0.3, end: 0),

                          SizedBox(height: 12),

                          Center(
                            child: TextButton(
                              onPressed: () => _deleteAccount(user),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              child: Text(AppLocalizations.of(context).deleteAccount),
                            ),
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
        Icon(icon, color: AppColors.textPrimary, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: DaromDecorations.titleStyle(fontSize: 19),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
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
            backgroundColor: AppColors.accent,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 22),
            const SizedBox(width: 17),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withOpacity(0.9),
                      ),
                    ),
                ],
              ),
            ),
            if (badgeCount > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}