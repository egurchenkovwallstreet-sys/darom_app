import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../widgets/midnight_glow_screen.dart';
import 'listings_feed_screen.dart';

class SubcategoriesScreen extends StatefulWidget {
  final String categoryName;
  final Color categoryColor;
  final String phoneNumber;
  final String? currentUserId;

  const SubcategoriesScreen({
    super.key,
    required this.categoryName,
    required this.categoryColor,
    required this.phoneNumber,
    this.currentUserId,
  });

  @override
  State<SubcategoriesScreen> createState() => _SubcategoriesScreenState();
}

class _SubcategoriesScreenState extends State<SubcategoriesScreen> {
  final Map<String, List<Map<String, dynamic>>> _subcategories = {
    'Одежда': [
      {'name': 'Мужская', 'icon': Icons.man, 'count': 124},
      {'name': 'Женская', 'icon': Icons.woman, 'count': 256},
      {'name': 'Детская', 'icon': Icons.child_care, 'count': 89},
      {'name': 'Обувь', 'icon': Icons.checkroom_outlined, 'count': 67},
      {'name': 'Аксессуары', 'icon': Icons.watch, 'count': 45},
    ],
    'Мебель': [
      {'name': 'Гостиная', 'icon': Icons.tv, 'count': 34},
      {'name': 'Спальня', 'icon': Icons.bed, 'count': 28},
      {'name': 'Кухня', 'icon': Icons.kitchen, 'count': 42},
      {'name': 'Офис', 'icon': Icons.business_center, 'count': 19},
      {'name': 'Детская', 'icon': Icons.toys, 'count': 15},
    ],
    'Детское': [
      {'name': 'Коляски', 'icon': Icons.stroller, 'count': 23},
      {'name': 'Автокресла', 'icon': Icons.car_rental, 'count': 18},
      {'name': 'Игрушки', 'icon': Icons.toys, 'count': 156},
      {'name': 'Одежда', 'icon': Icons.checkroom, 'count': 89},
      {'name': 'Книги', 'icon': Icons.menu_book, 'count': 67},
    ],
    'Электроника': [
      {'name': 'Телефоны', 'icon': Icons.phone_android, 'count': 45},
      {'name': 'Компьютеры', 'icon': Icons.computer, 'count': 32},
      {'name': 'Планшеты', 'icon': Icons.tablet_android, 'count': 21},
      {'name': 'Аудио', 'icon': Icons.headphones, 'count': 38},
      {'name': 'Бытовая техника', 'icon': Icons.home_work, 'count': 56},
    ],
    'Книги': [
      {'name': 'Художественная', 'icon': Icons.auto_stories, 'count': 78},
      {'name': 'Учебная', 'icon': Icons.school, 'count': 45},
      {'name': 'Научная', 'icon': Icons.science, 'count': 34},
      {'name': 'Детская', 'icon': Icons.child_friendly, 'count': 56},
      {'name': 'Комиксы', 'icon': Icons.collections_bookmark, 'count': 23},
    ],
    'Посуда': [
      {'name': 'Кастрюли', 'icon': Icons.water_drop, 'count': 23},
      {'name': 'Тарелки', 'icon': Icons.restaurant, 'count': 34},
      {'name': 'Чашки', 'icon': Icons.local_cafe, 'count': 45},
      {'name': 'Столовые приборы', 'icon': Icons.dinner_dining, 'count': 28},
      {'name': 'Контейнеры', 'icon': Icons.inventory_2, 'count': 19},
    ],
    'Спорт': [
      {'name': 'Велосипеды', 'icon': Icons.pedal_bike, 'count': 12},
      {'name': 'Тренажеры', 'icon': Icons.fitness_center, 'count': 18},
      {'name': 'Инвентарь', 'icon': Icons.sports_martial_arts, 'count': 34},
      {'name': 'Одежда', 'icon': Icons.sports_soccer, 'count': 45},
      {'name': 'Туризм', 'icon': Icons.terrain, 'count': 23},
    ],
    'Другое': [
      {'name': 'Разное', 'icon': Icons.category, 'count': 234},
      {'name': 'Стройматериалы', 'icon': Icons.handyman, 'count': 67},
      {'name': 'Коллекционное', 'icon': Icons.celebration, 'count': 23},
      {'name': 'Товары для дома', 'icon': Icons.home, 'count': 89},
      {'name': 'Прочее', 'icon': Icons.more_horiz, 'count': 156},
    ],
  };

  List<Map<String, dynamic>> _getSubcategories() {
    return _subcategories[widget.categoryName] ?? [
      {'name': 'Все подкатегории', 'icon': Icons.category, 'count': 0},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final subcategories = _getSubcategories();
    
    return MidnightGlowScreen(
      child: SafeArea(
              child: Column(
                children: [
                  // Шапка
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Color(0xFF001F3F).withOpacity(0.85),
                              shape: BoxShape.circle,
                              border: Border.all(color: Color(0xFF00BFFF), width: 2),
                            ),
                            child: Icon(Icons.arrow_back, color: Color(0xFF00BFFF)),
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.categoryName,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFFFFF),
                                  shadows: [
                                    Shadow(
                                      color: AppColors.categoryIcon.withOpacity(0.6),
                                      offset: Offset(0, 4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${subcategories.length} подкатегорий',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFFFFFFF).withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Список подкатегорий
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          SizedBox(height: 10),
                          ...List.generate(
                            subcategories.length,
                            (index) => _buildSubcategoryCard(
                              subcategories[index],
                              index,
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSubcategoryCard(Map<String, dynamic> subcategory, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListingsFeedScreen(
              categoryName: widget.categoryName,
              subcategoryName: subcategory['name'] as String,
              categoryColor: AppColors.categoryIcon,
              phoneNumber: widget.phoneNumber,
              currentUserId: widget.currentUserId,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF001F3F).withOpacity(0.85),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: AppColors.categoryIcon,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.categoryIcon.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 5),
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
                subcategory['icon'] as IconData,
                size: 35,
                color: AppColors.categoryIcon,
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subcategory['name'] as String,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '${subcategory['count']} объявлений',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFFFFFFF).withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFFFFFFFF).withOpacity(0.4),
              size: 20,
            ),
          ],
        ),
      )
          .animate(
            delay: Duration(milliseconds: 200 + (index * 100)),
          )
          .fadeIn(duration: Duration(milliseconds: 600))
          .slideX(begin: -0.2, end: 0)
          .scale(begin: Offset(0.95, 0.95), end: Offset(1.0, 1.0)),
    );
  }
}