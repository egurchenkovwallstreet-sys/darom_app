import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/app_categories.dart';
import '../theme/app_colors.dart';
import '../widgets/midnight_glow_screen.dart';
import 'listings_feed_screen.dart';

class SubcategoriesScreen extends StatefulWidget {
  final String categoryName;
  final Color categoryColor;
  final String phoneNumber;
  final String? currentUserId;
  final String? nestedGroup;

  const SubcategoriesScreen({
    super.key,
    required this.categoryName,
    required this.categoryColor,
    required this.phoneNumber,
    this.currentUserId,
    this.nestedGroup,
  });

  @override
  State<SubcategoriesScreen> createState() => _SubcategoriesScreenState();
}

class _SubcategoriesScreenState extends State<SubcategoriesScreen> {
  List<AppSubcategory> get _subcategories {
    return AppCategories.subcategoriesFor(
      widget.categoryName,
      nestedGroup: widget.nestedGroup,
    );
  }

  String get _screenTitle {
    if (widget.nestedGroup != null) {
      return '${widget.categoryName} · ${widget.nestedGroup}';
    }
    return widget.categoryName;
  }

  @override
  Widget build(BuildContext context) {
    final subcategories = _subcategories;

    return MidnightGlowScreen(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFF001F3F).withOpacity(0.85),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF00BFFF), width: 2),
                      ),
                      child: const Icon(Icons.arrow_back, color: Color(0xFF00BFFF)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _screenTitle,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFFFFF),
                            shadows: [
                              Shadow(
                                color: AppColors.categoryIcon.withOpacity(0.6),
                                offset: const Offset(0, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${subcategories.length} подкатегорий',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFFFFFFFF).withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    ...List.generate(
                      subcategories.length,
                      (index) => _buildSubcategoryCard(subcategories[index], index),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSubcategoryTap(AppSubcategory subcategory) {
    if (subcategory.hasChildren) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubcategoriesScreen(
            categoryName: widget.categoryName,
            categoryColor: widget.categoryColor,
            phoneNumber: widget.phoneNumber,
            currentUserId: widget.currentUserId,
            nestedGroup: subcategory.name,
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListingsFeedScreen(
          categoryName: widget.categoryName,
          subcategoryName: subcategory.resolveListingSubcategory(),
          categoryColor: AppColors.categoryIcon,
          phoneNumber: widget.phoneNumber,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  Widget _buildSubcategoryCard(AppSubcategory subcategory, int index) {
    return GestureDetector(
      onTap: () => _onSubcategoryTap(subcategory),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF001F3F).withOpacity(0.85),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: AppColors.categoryIcon,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.categoryIcon.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.categoryIcon.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                subcategory.icon,
                size: 35,
                color: AppColors.categoryIcon,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subcategory.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                  if (subcategory.hasChildren)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        '${subcategory.children!.length} разделов',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFFFFFFFF).withOpacity(0.6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              subcategory.hasChildren ? Icons.arrow_forward_ios : Icons.arrow_forward_ios,
              color: const Color(0xFFFFFFFF).withOpacity(0.4),
              size: 20,
            ),
          ],
        ),
      )
          .animate(
            delay: Duration(milliseconds: 200 + (index * 100)),
          )
          .fadeIn(duration: const Duration(milliseconds: 600))
          .slideX(begin: -0.2, end: 0)
          .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0)),
    );
  }
}
