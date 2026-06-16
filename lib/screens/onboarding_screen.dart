import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/primary_action_button.dart';
import 'phone_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.card_giftcard,
      'color': Color(0xFF00BFFF),
      'borderColor': Color(0xFF008C8C),
      'title': 'Добро пожаловать в "Даром"!',
      'description':
          'Приложение для бесплатной передачи вещей. Отдавай ненужное — помогай другим!',
    },
    {
      'icon': Icons.map,
      'color': Color(0xFF008C8C),
      'borderColor': Color(0xFF00BFFF),
      'title': 'Находи вещи рядом',
      'description':
          'Смотри карту объявлений вокруг себя и забирай нужные вещи бесплатно.',
    },
    {
      'icon': Icons.favorite,
      'color': Color(0xFF00BFFF),
      'borderColor': Color(0xFF008C8C),
      'title': 'Делись с миром',
      'description':
          'Отдавай вещи, которые тебе не нужны, и получай уровень "Самое доброе сердце"!',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MidnightGlowScreen(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildVolumetricPage(
                    icon: _pages[index]['icon'],
                    iconColor: _pages[index]['color'],
                    borderColor: _pages[index]['borderColor'],
                    title: _pages[index]['title'],
                    description: _pages[index]['description'],
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => GestureDetector(
                  onTap: () {
                    _pageController.jumpToPage(index);
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    margin: EdgeInsets.symmetric(horizontal: 6),
                    width: _currentPage == index ? 24 : 12,
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: _currentPage == index
                          ? LinearGradient(
                              colors: [
                                Color(0xFF00BFFF),
                                Color(0xFF008C8C),
                              ],
                            )
                          : null,
                      color: _currentPage == index
                          ? null
                          : Color(0xFFFFFFFF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Color(0xFF00BFFF),
                        width: 2,
                      ),
                      boxShadow: _currentPage == index
                          ? [
                              BoxShadow(
                                color: Color(0xFF00BFFF).withOpacity(0.6),
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ]
                          : [],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            PrimaryActionButton(
              key: const ValueKey('onboarding-primary-button'),
              label: _currentPage < _pages.length - 1 ? 'Далее' : 'Начать',
              padding: const EdgeInsets.symmetric(horizontal: 40),
              onPressed: () {
                if (_currentPage < _pages.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const PhoneScreen()),
                  );
                }
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumetricPage({
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    required String title,
    required String description,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF001F3F),
                  borderColor.withOpacity(0.3),
                ],
              ),
              border: Border.all(
                color: borderColor,
                width: 5,
              ),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 10,
                  offset: Offset(0, 15),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 80,
              color: iconColor,
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
              )
              .animate()
              .scale(
                duration: Duration(seconds: 2),
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                duration: Duration(seconds: 2),
                curve: Curves.easeInOut,
              ),
          SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
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
              .slideY(begin: 0.3, end: 0),
          SizedBox(height: 30),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF001F3F).withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF00BFFF).withOpacity(0.2),
                  blurRadius: 25,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFFFFFFF),
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
              .animate(
                delay: Duration(milliseconds: 500),
              )
              .fadeIn(duration: Duration(milliseconds: 800))
              .slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }
}
