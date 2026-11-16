import 'package:flutter/material.dart';

import '../models/user.dart';

class ProfileAchievement {
  const ProfileAchievement({
    required this.icon,
    required this.title,
    required this.color,
    required this.requirementRu,
    required this.requirementEn,
    required this.isUnlocked,
  });

  final IconData icon;
  final String title;
  final Color color;
  final String requirementRu;
  final String requirementEn;
  final bool Function(User user) isUnlocked;
}

/// Достижения профиля = 5 уровней дарителя из ТЗ (раздел 8).
/// У каждого уровня свой яркий цвет медали; до получения — приглушённая медаль с условием.
class ProfileAchievements {
  ProfileAchievements._();

  static const List<ProfileAchievement> all = [
    ProfileAchievement(
      icon: Icons.waving_hand_rounded,
      title: 'Новичок',
      color: Color(0xFF2F6FE0),
      requirementRu: 'С первого дня',
      requirementEn: 'From day one',
      isUnlocked: _novice,
    ),
    ProfileAchievement(
      icon: Icons.bolt_rounded,
      title: 'Активный',
      color: Color(0xFF6D4AE0),
      requirementRu: 'Отдать 5 вещей',
      requirementEn: 'Give 5 items',
      isUnlocked: _active,
    ),
    ProfileAchievement(
      icon: Icons.card_giftcard_rounded,
      title: 'Щедрый',
      color: Color(0xFF0E8FB8),
      requirementRu: 'Отдать 20 вещей',
      requirementEn: 'Give 20 items',
      isUnlocked: _generous,
    ),
    ProfileAchievement(
      icon: Icons.volunteer_activism_rounded,
      title: 'Благотворитель',
      color: Color(0xFFC9952B),
      requirementRu: 'Отдать 50 вещей',
      requirementEn: 'Give 50 items',
      isUnlocked: _philanthropist,
    ),
    ProfileAchievement(
      icon: Icons.favorite_rounded,
      title: 'Самое доброе сердце',
      color: Color(0xFFC23C8E),
      requirementRu: 'Отдать 100 вещей',
      requirementEn: 'Give 100 items',
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
