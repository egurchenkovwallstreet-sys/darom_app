import 'package:flutter/material.dart';

/// Описание подкатегории для навигации и API.
class AppSubcategory {
  const AppSubcategory({
    required this.name,
    required this.icon,
    this.children,
    this.listingSubcategory,
  });

  final String name;
  final IconData icon;

  /// Вложенные подкатегории (например, комнаты в «Мебель»).
  final List<AppSubcategory>? children;

  /// Значение для поля subcategory в API. Если null — используется [name].
  final String? listingSubcategory;

  bool get hasChildren => children != null && children!.isNotEmpty;

  String resolveListingSubcategory() => listingSubcategory ?? name;
}

/// Описание категории верхнего уровня.
class AppCategory {
  const AppCategory({
    required this.name,
    required this.icon,
    required this.subcategories,
  });

  final String name;
  final IconData icon;
  final List<AppSubcategory> subcategories;
}

/// Единый справочник категорий приложения.
class AppCategories {
  AppCategories._();

  static const _furnitureRooms = [
    'Гостиная',
    'Спальня',
    'Кухня',
    'Офис',
    'Детская',
  ];

  static const _other = AppSubcategory(
    name: 'Прочее',
    icon: Icons.more_horiz,
  );

  static List<AppSubcategory> _withOther(List<AppSubcategory> items) {
    return [...items, _other];
  }

  static List<AppSubcategory> _furnitureChildren() {
    return [
      ..._furnitureRooms.map(
        (room) => AppSubcategory(
          name: room,
          icon: _furnitureRoomIcon(room),
          listingSubcategory: 'Мебель — $room',
        ),
      ),
      _other.copyWith(listingSubcategory: 'Мебель — Прочее'),
    ];
  }

  static IconData _furnitureRoomIcon(String room) {
    switch (room) {
      case 'Гостиная':
        return Icons.weekend;
      case 'Спальня':
        return Icons.bed;
      case 'Кухня':
        return Icons.kitchen;
      case 'Офис':
        return Icons.business_center;
      case 'Детская':
        return Icons.toys;
      default:
        return Icons.chair;
    }
  }

  static final List<AppCategory> all = [
    AppCategory(
      name: 'Одежда',
      icon: Icons.checkroom,
      subcategories: _withOther([
        AppSubcategory(name: 'Мужская', icon: Icons.man),
        AppSubcategory(name: 'Женская', icon: Icons.woman),
        AppSubcategory(name: 'Детская', icon: Icons.child_care),
        AppSubcategory(name: 'Обувь', icon: Icons.directions_walk),
        AppSubcategory(name: 'Аксессуары', icon: Icons.watch),
      ]),
    ),
    AppCategory(
      name: 'Для дома',
      icon: Icons.home,
      subcategories: _withOther([
        AppSubcategory(
          name: 'Мебель',
          icon: Icons.chair,
          children: _furnitureChildren(),
        ),
        AppSubcategory(name: 'Посуда', icon: Icons.restaurant),
        AppSubcategory(name: 'Растения', icon: Icons.local_florist),
        AppSubcategory(name: 'Сад и огород', icon: Icons.yard),
      ]),
    ),
    AppCategory(
      name: 'Детское',
      icon: Icons.toys,
      subcategories: _withOther([
        AppSubcategory(name: 'Коляски', icon: Icons.stroller),
        AppSubcategory(name: 'Автокресла', icon: Icons.event_seat),
        AppSubcategory(name: 'Игрушки', icon: Icons.toys),
        AppSubcategory(name: 'Одежда', icon: Icons.checkroom),
        AppSubcategory(name: 'Книги', icon: Icons.menu_book),
      ]),
    ),
    AppCategory(
      name: 'Электроника',
      icon: Icons.smartphone,
      subcategories: _withOther([
        AppSubcategory(name: 'Телефоны', icon: Icons.phone_android),
        AppSubcategory(name: 'Компьютеры', icon: Icons.computer),
        AppSubcategory(name: 'Планшеты', icon: Icons.tablet_android),
        AppSubcategory(name: 'Аудио', icon: Icons.headphones),
        AppSubcategory(name: 'Бытовая техника', icon: Icons.microwave),
      ]),
    ),
    AppCategory(
      name: 'Книги',
      icon: Icons.menu_book,
      subcategories: _withOther([
        AppSubcategory(name: 'Художественная', icon: Icons.auto_stories),
        AppSubcategory(name: 'Учебная', icon: Icons.school),
        AppSubcategory(name: 'Научная', icon: Icons.science),
        AppSubcategory(name: 'Детская', icon: Icons.child_friendly),
        AppSubcategory(name: 'Комиксы', icon: Icons.draw),
      ]),
    ),
    AppCategory(
      name: 'Спорт',
      icon: Icons.fitness_center,
      subcategories: _withOther([
        AppSubcategory(name: 'Велосипеды', icon: Icons.pedal_bike),
        AppSubcategory(name: 'Тренажеры', icon: Icons.fitness_center),
        AppSubcategory(name: 'Инвентарь', icon: Icons.sports),
        AppSubcategory(name: 'Одежда', icon: Icons.checkroom),
        AppSubcategory(name: 'Туризм', icon: Icons.terrain),
      ]),
    ),
    AppCategory(
      name: 'Строй материалы',
      icon: Icons.construction,
      subcategories: _withOther([
        AppSubcategory(name: 'Инструменты', icon: Icons.handyman),
        AppSubcategory(name: 'Краски', icon: Icons.format_paint),
      ]),
    ),
    AppCategory(
      name: 'Другое',
      icon: Icons.category,
      subcategories: [
        AppSubcategory(name: 'Для животных', icon: Icons.pets),
        _other,
      ],
    ),
  ];

  static AppCategory? findCategory(String name) {
    for (final category in all) {
      if (category.name == name) return category;
    }
    return null;
  }

  static IconData iconFor(String categoryName) {
    return findCategory(categoryName)?.icon ?? Icons.category;
  }

  static List<String> get categoryNames => all.map((c) => c.name).toList();

  /// Подкатегории для экрана списка (верхний уровень или вложенный).
  static List<AppSubcategory> subcategoriesFor(
    String categoryName, {
    String? nestedGroup,
  }) {
    final category = findCategory(categoryName);
    if (category == null) return const [];

    if (nestedGroup == null) {
      return category.subcategories;
    }

    for (final sub in category.subcategories) {
      if (sub.name == nestedGroup && sub.hasChildren) {
        return sub.children!;
      }
    }

    return const [];
  }

  /// Все значения subcategory для API (листья дерева) — для формы объявления.
  static List<String> listingSubcategoriesFor(String categoryName) {
    final category = findCategory(categoryName);
    if (category == null) return const [];

    final result = <String>[];
    for (final sub in category.subcategories) {
      if (sub.hasChildren) {
        for (final child in sub.children!) {
          result.add(child.resolveListingSubcategory());
        }
      } else {
        result.add(sub.resolveListingSubcategory());
      }
    }
    return result;
  }

  /// Карта category → subcategories для формы «Добавить объявление».
  static Map<String, List<String>> get listingSubcategoryMap {
    return {for (final c in all) c.name: listingSubcategoriesFor(c.name)};
  }

  /// Число активных объявлений для подкатегории (сумма для вложенных).
  static int countForSubcategory(
    AppSubcategory subcategory,
    Map<String, int> counts,
  ) {
    if (subcategory.hasChildren) {
      var sum = 0;
      for (final child in subcategory.children!) {
        sum += counts[child.resolveListingSubcategory()] ?? 0;
      }
      return sum;
    }
    return counts[subcategory.resolveListingSubcategory()] ?? 0;
  }

  /// Перевод старых категорий (до реструктуризации) в новые.
  static ({String category, String subcategory}) normalizeLegacy({
    required String category,
    required String subcategory,
  }) {
    if (category == 'Мебель') {
      return (
        category: 'Для дома',
        subcategory: 'Мебель — $subcategory',
      );
    }
    if (category == 'Посуда') {
      return (category: 'Для дома', subcategory: subcategory);
    }
    return (category: category, subcategory: subcategory);
  }
}

extension on AppSubcategory {
  AppSubcategory copyWith({String? listingSubcategory}) {
    return AppSubcategory(
      name: name,
      icon: icon,
      children: children,
      listingSubcategory: listingSubcategory ?? this.listingSubcategory,
    );
  }
}
