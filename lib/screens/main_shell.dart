import 'package:flutter/material.dart';

import 'add_listing_screen.dart';
import 'chats_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import '../widgets/midnight_glow_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return MidnightGlowScreen(
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF001F3F).withOpacity(0.95),
          border: Border(
            top: BorderSide(color: const Color(0xFF00BFFF).withOpacity(0.25)),
          ),
        ),
        padding: EdgeInsets.only(top: 4, bottom: bottomInset > 0 ? bottomInset - 2 : 4),
        child: SizedBox(
          height: 50,
          child: Row(
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
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF00BFFF) : const Color(0xFF80DEEA);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: color, fontWeight: selected ? FontWeight.w600 : FontWeight.normal),
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
    return Expanded(
      child: Transform.translate(
        offset: const Offset(0, -8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_rounded,
                size: 34,
                color: selected ? const Color(0xFF00BFFF) : const Color(0xFF80DEEA),
              ),
              const SizedBox(height: 1),
              Text(
                'Добавить',
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? const Color(0xFF00BFFF) : const Color(0xFF80DEEA),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
