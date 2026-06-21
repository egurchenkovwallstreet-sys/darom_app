import 'package:flutter/material.dart';

import '../models/user.dart';

class ProfileAchievement {
  const ProfileAchievement({
    required this.icon,
    required this.title,
    required this.color,
    required this.isUnlocked,
  });

  final IconData icon;
  final String title;
  final Color color;
  final bool Function(User user) isUnlocked;
}

/// Достижения профиля = 5 уровней дарителя из ТЗ (раздел 8).
/// Серые до получения уровня, цветные после.
class ProfileAchievements {
  ProfileAchievements._();

  static const List<ProfileAchievement> all = [
    ProfileAchievement(
      icon: Icons.waving_hand,
      title: 'Новичок',
      color: Color(0xFF80DEEA),
      isUnlocked: _novice,
    ),
    ProfileAchievement(
      icon: Icons.bolt,
      title: 'Активный',
      color: Color(0xFF00BFFF),
      isUnlocked: _active,
    ),
    ProfileAchievement(
      icon: Icons.card_giftcard,
      title: 'Щедрый',
      color: Color(0xFF008C8C),
      isUnlocked: _generous,
    ),
    ProfileAchievement(
      icon: Icons.volunteer_activism,
      title: 'Благотворитель',
      color: Color(0xFFFFC107),
      isUnlocked: _philanthropist,
    ),
    ProfileAchievement(
      icon: Icons.favorite,
      title: 'Самое доброе сердце',
      color: Color(0xFFFF5722),
      isUnlocked: _kindestHeart,
    ),
  ];

  /// Стартовый уровень — у всех с первого дня.
  static bool _novice(User user) => true;

  /// ТЗ: 5+ отдано, рейтинг 4.0+
  static bool _active(User user) =>
      user.itemsGiven >= 5 && user.rating >= 4.0;

  /// ТЗ: 20+ отдано
  static bool _generous(User user) => user.itemsGiven >= 20;

  /// ТЗ: 50+ отдано
  static bool _philanthropist(User user) => user.itemsGiven >= 50;

  /// ТЗ: 100+ отдано, рейтинг 4.8+
  static bool _kindestHeart(User user) =>
      user.itemsGiven >= 100 && user.rating >= 4.8;

  static int unlockedCount(User user) =>
      all.where((item) => item.isUnlocked(user)).length;
}
