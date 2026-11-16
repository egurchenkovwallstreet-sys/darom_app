import 'package:darom_app/theme/darom_decorations.dart';
import 'package:flutter/material.dart';
import 'package:darom_app/theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../utils/responsive_layout.dart';
import '../widgets/auth_header_icon.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/primary_action_button.dart';
import '../widgets/responsive_page_frame.dart';
import 'phone_screen.dart';
import 'partner_register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<({IconData icon, String title, String description})> _pages(AppLocalizations l10n) => [
        (
          icon: Icons.card_giftcard_rounded,
          title: l10n.onboardingTitle1,
          description: l10n.onboardingDesc1,
        ),
        (
          icon: Icons.favorite_outline_rounded,
          title: l10n.onboardingTitle2,
          description: l10n.onboardingDesc2,
        ),
        (
          icon: Icons.volunteer_activism_outlined,
          title: l10n.onboardingTitle3,
          description: l10n.onboardingDesc3,
        ),
      ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next(int pageCount) {
    if (_currentPage < pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PhoneScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = _pages(l10n);
    final isLast = _currentPage == pages.length - 1;

    return MidnightGlowScreen(
      child: SafeArea(
        child: ResponsivePageFrame(
          maxWidth: ResponsiveLayout.isDesktop(context) ? 560 : double.infinity,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  itemBuilder: (context, index) => _OnboardingPage(
                    icon: pages[index].icon,
                    title: pages[index].title,
                    description: pages[index].description,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => GestureDetector(
                    onTap: () => _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
                    child: AnimatedContainer(
                      duration: DaromDecorations.interactionDuration,
                      curve: DaromDecorations.interactionCurve,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? AppColors.primary : AppColors.tabTrack,
                        borderRadius: BorderRadius.circular(DaromDecorations.pillRadius),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: PrimaryActionButton(
                  key: const ValueKey('onboarding-primary-button'),
                  label: isLast ? l10n.startButton : l10n.nextButton,
                  height: 56,
                  fontSize: 17,
                  onPressed: () => _next(pages.length),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: Visibility(
                  visible: isLast,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PartnerRegisterScreen(),
                        ),
                      );
                    },
                    child: Text(
                      l10n.partnerLink,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AuthHeaderIcon(icon, size: 128),
              const SizedBox(height: 32),
              Text(
                title,
                textAlign: TextAlign.center,
                style: DaromDecorations.titleStyle(fontSize: 28),
              ),
              const SizedBox(height: 16),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
