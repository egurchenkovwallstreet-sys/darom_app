import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../data/profile_achievements.dart';
import '../models/user.dart';
import '../services/auth_api.dart';
import '../services/push_service.dart';
import '../services/session_service.dart';
import '../services/users_api.dart';
import '../widgets/avatar_image.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/primary_action_button.dart';
import 'my_listings_screen.dart';
import 'onboarding_screen.dart';
import 'partner_stats_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userName;
  final String? phoneNumber;
  final bool inShell;

  const ProfileScreen({
    super.key,
    this.userName,
    this.phoneNumber,
    this.inShell = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UsersApi _usersApi = UsersApi();
  final AuthApi _authApi = AuthApi();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isEditPressed = false;
  bool _uploadingAvatar = false;
  late Future<User> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  @override
  void dispose() {
    _usersApi.dispose();
    _authApi.dispose();
    super.dispose();
  }

  Future<User> _loadProfile() {
    final phone = widget.phoneNumber;
    if (phone == null || phone.isEmpty) {
      return Future.error('Нет номера телефона');
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
        const SnackBar(
          content: Text('Аватар обновлён'),
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

  Future<void> _openPushSettings(String phoneNumber) async {
    final status = await PushService.instance.getPermissionStatus();
    if (!mounted) return;

    if (status == AuthorizationStatus.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Уведомления заблокированы. Откройте настройки браузера → Сайты → '
            'darom-app.online → Уведомления → Разрешить',
          ),
          backgroundColor: Color(0xFFFF5722),
          duration: Duration(seconds: 8),
        ),
      );
      return;
    }

    final result = await PushService.instance.requestPermissionAndRegister(phone: phoneNumber);
    if (!mounted) return;

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
            content: Text('Разрешите уведомления в настройках браузера'),
            backgroundColor: Color(0xFFFF5722),
            duration: Duration(seconds: 6),
          ),
        );
      case PushRegisterResult.notConfigured:
      case PushRegisterResult.failed:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Не удалось включить уведомления'),
            backgroundColor: Color(0xFFFF5722),
          ),
        );
    }
  }

  Widget _buildAchievementTile(ProfileAchievement achievement, User user) {
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
            achievement.title,
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00BFFF)),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off, size: 48, color: Color(0xFF00BFFF)),
                      const SizedBox(height: 16),
                      Text(
                        snapshot.error?.toString() ?? 'Не удалось загрузить профиль',
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
                        onPressed: _retry,
                      ),
                      const SizedBox(height: 12),
                      PrimaryActionButton(
                        label: 'Выйти и войти заново',
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

            return _buildContent(snapshot.data!);
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
                            'Профиль',
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
                                content: Text('Редактировать профиль'),
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
                                  'Нажмите на фото, чтобы сменить',
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
                                    child: const Text(
                                      '⭐ Основатель',
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
                                    child: const Text(
                                      '🤝 Партнёр',
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
                                        '${user.donorLevel} • ${user.rating}',
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
                                _buildStatItem(Icons.inventory_2, '${user.activeListings}/${user.listingLimit}', 'Объявления'),
                                Container(
                                  width: 1,
                                  height: 50,
                                  color: Color(0xFF00BFFF).withOpacity(0.3),
                                ),
                                _buildStatItem(Icons.handshake, '${user.dealsCount}', 'Сделки'),
                                Container(
                                  width: 1,
                                  height: 50,
                                  color: Color(0xFF00BFFF).withOpacity(0.3),
                                ),
                                _buildStatItem(
                                  Icons.shopping_bag_outlined,
                                  '${user.pickupsUsedThisMonth}/${user.pickupLimit}',
                                  'Заборы',
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
                                  '🏆 Достижения',
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
                                  Icons.inventory_2_outlined,
                                  'Мои объявления',
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
                                    'Статистика партнёра',
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
                                    Icons.admin_panel_settings_outlined,
                                    'Админ-панель',
                                    onTap: () => _openAdminPanel(user.phoneNumber),
                                  ),
                                ],
                                Divider(color: Color(0xFF00BFFF).withOpacity(0.3), height: 1),
                                _buildSettingsItem(
                                  Icons.notifications,
                                  'Уведомления',
                                  onTap: () => _openPushSettings(user.phoneNumber),
                                ),
                                Divider(color: Color(0xFF00BFFF).withOpacity(0.3), height: 1),
                                _buildSettingsItem(Icons.language, 'Язык'),
                                Divider(color: Color(0xFF00BFFF).withOpacity(0.3), height: 1),
                                _buildSettingsItem(Icons.help, 'Помощь'),
                                Divider(color: Color(0xFF00BFFF).withOpacity(0.3), height: 1),
                                _buildSettingsItem(Icons.info, 'О приложении'),
                              ],
                            ),
                          )
                              .animate(
                                delay: Duration(milliseconds: 700),
                              )
                              .fadeIn(duration: Duration(milliseconds: 800))
                              .slideY(begin: 0.3, end: 0),
                          
                          SizedBox(height: 20),

                          PrimaryActionButton(
                            label: 'Выйти',
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

  Widget _buildSettingsItem(IconData icon, String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title — скоро'),
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
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFFFFFFF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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