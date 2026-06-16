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
    return MidnightGlowScreen(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF00BFFF),
        unselectedItemColor: const Color(0xFF80DEEA),
        backgroundColor: const Color(0xFF001F3F).withOpacity(0.95),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_rounded),
            label: 'Избранное',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_rounded, size: 40, color: Color(0xFF00BFFF)),
            label: 'Добавить',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_rounded),
            label: 'Чаты',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Профиль',
          ),
        ],
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
