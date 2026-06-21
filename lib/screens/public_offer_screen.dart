import 'package:flutter/material.dart';

import '../data/public_offer.dart';
import '../widgets/midnight_glow_screen.dart';
import '../widgets/primary_action_button.dart';

class PublicOfferScreen extends StatelessWidget {
  const PublicOfferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MidnightGlowScreen(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF00BFFF)),
                  ),
                  const Expanded(
                    child: Text(
                      PublicOfferText.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF001F3F).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF00BFFF).withOpacity(0.4), width: 2),
                  ),
                  child: const Text(
                    PublicOfferText.body,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.55,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: PrimaryActionButton(
                label: 'Закрыть',
                height: 48,
                fontSize: 16,
                borderRadius: 24,
                gradientColors: PrimaryActionButton.primaryShortGradient,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
