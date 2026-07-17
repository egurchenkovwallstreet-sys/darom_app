import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/midnight_glow_screen.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  static const _paragraphs = [
    '«Даром» — это место, где добро становится простым.',
    'В каждом доме лежат вещи, которые уже не нужны: одежда, книги, игрушки, посуда, мелочи для дома. Кому-то они как раз пригодятся — прямо сейчас, рядом с вами.',
    'Не нужно искать адреса фондов, возить коробки через весь город и думать «к кому это нести». Открываете приложение, пишете пару слов, добавляете фото — и вещь уже ждёт того, кому она нужна. Или сами находите то, что искали, и забираете у соседа — бесплатно.',
    'Помогать может каждый. Не обязательно быть богатым или известным. Достаточно одной вещи, одного доброго поступка, одного «возьмите, пусть послужит». Это и есть настоящая благотворительность — тихая, простая, настоящая.',
    '«Даром» — когда помощь близко. Когда добро не в словах, а на деле. Когда мир становится чуть теплее — потому что вы решили не выбросить, а подарить.',
  ];

  @override
  Widget build(BuildContext context) {
    return MidnightGlowScreen(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.cyan),
                  ),
                  const Expanded(
                    child: Text(
                      'О приложении',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF001F3F).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cyan, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < _paragraphs.length; i++) ...[
                          if (i > 0) const SizedBox(height: 16),
                          Text(
                            _paragraphs[i],
                            style: TextStyle(
                              color: Colors.white.withOpacity(i == 0 ? 1 : 0.88),
                              fontSize: i == 0 ? 18 : 16,
                              height: 1.55,
                              fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
