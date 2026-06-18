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
        clipBehavior: Clip.none,
        decoration: BoxDecoration(
          color: const Color(0xFF001F3F).withOpacity(0.95),
          border: Border(
            top: BorderSide(color: const Color(0xFF00BFFF).withOpacity(0.25)),
          ),
        ),
        padding: EdgeInsets.only(top: 14, bottom: bottomInset > 0 ? bottomInset : 8),
        child: SizedBox(
          height: 58,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
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
    final accent = selected ? const Color(0xFF00BFFF) : const Color(0xFF80DEEA);

    return Expanded(
      child: SizedBox(
        height: 58,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              top: -18,
              child: Material(
                elevation: 10,
                shadowColor: const Color(0xFF00BFFF).withOpacity(0.55),
                shape: const CircleBorder(),
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: Ink(
                    width: 58,
                    height: 58,
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
                          color: accent.withOpacity(0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 34,
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
