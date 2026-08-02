import 'app_localizations.dart';

/// Отображаемые названия категорий (ключи API остаются на русском).
extension CategoryLocalizations on AppLocalizations {
  String _label(String ru, String en) => isEn ? en : ru;

  String categoryLabel(String ruName) {
    switch (ruName) {
      case 'Одежда':
        return _label('Одежда', 'Clothing');
      case 'Для дома':
        return _label('Для дома', 'Home');
      case 'Детское':
        return _label('Детское', 'Kids');
      case 'Электроника':
        return _label('Электроника', 'Electronics');
      case 'Книги':
        return _label('Книги', 'Books');
      case 'Спорт':
        return _label('Спорт', 'Sports');
      case 'Строй материалы':
        return _label('Строй материалы', 'Building supplies');
      case 'Другое':
        return _label('Другое', 'Other');
      default:
        return ruName;
    }
  }

  String subcategoryLabel(String ruName) {
    switch (ruName) {
      case 'Прочее':
        return _label('Прочее', 'Misc');
      case 'Мужская':
        return _label('Мужская', 'Men\'s');
      case 'Женская':
        return _label('Женская', 'Women\'s');
      case 'Детская':
        return _label('Детская', 'Kids');
      case 'Обувь':
        return _label('Обувь', 'Shoes');
      case 'Аксессуары':
        return _label('Аксессуары', 'Accessories');
      case 'Мебель':
        return _label('Мебель', 'Furniture');
      case 'Посуда':
        return _label('Посуда', 'Tableware');
      case 'Растения':
        return _label('Растения', 'Plants');
      case 'Сад и огород':
        return _label('Сад и огород', 'Garden');
      case 'Гостиная':
        return _label('Гостиная', 'Living room');
      case 'Спальня':
        return _label('Спальня', 'Bedroom');
      case 'Кухня':
        return _label('Кухня', 'Kitchen');
      case 'Офис':
        return _label('Офис', 'Office');
      case 'Коляски':
        return _label('Коляски', 'Strollers');
      case 'Автокресла':
        return _label('Автокресла', 'Car seats');
      case 'Игрушки':
        return _label('Игрушки', 'Toys');
      case 'Телефоны':
        return _label('Телефоны', 'Phones');
      case 'Компьютеры':
        return _label('Компьютеры', 'Computers');
      case 'Планшеты':
        return _label('Планшеты', 'Tablets');
      case 'Аудио':
        return _label('Аудио', 'Audio');
      case 'Бытовая техника':
        return _label('Бытовая техника', 'Appliances');
      case 'Художественная':
        return _label('Художественная', 'Fiction');
      case 'Учебная':
        return _label('Учебная', 'Textbooks');
      case 'Научная':
        return _label('Научная', 'Science');
      case 'Комиксы':
        return _label('Комиксы', 'Comics');
      case 'Велосипеды':
        return _label('Велосипеды', 'Bikes');
      case 'Тренажеры':
        return _label('Тренажеры', 'Gym equipment');
      case 'Инвентарь':
        return _label('Инвентарь', 'Gear');
      case 'Туризм':
        return _label('Туризм', 'Outdoor');
      case 'Инструменты':
        return _label('Инструменты', 'Tools');
      case 'Краски':
        return _label('Краски', 'Paint');
      case 'Для животных':
        return _label('Для животных', 'For pets');
      default:
        return categoryLabel(ruName);
    }
  }

  String listingSubcategoryLabel(String apiValue) {
    if (apiValue.contains(' — ')) {
      final parts = apiValue.split(' — ');
      if (parts.length == 2) {
        return '${subcategoryLabel(parts[0])} — ${subcategoryLabel(parts[1])}';
      }
    }
    return subcategoryLabel(apiValue);
  }

  String screenCategoryTitle(String categoryName, {String? nestedGroup}) {
    if (nestedGroup != null) {
      return '${categoryLabel(categoryName)} · ${subcategoryLabel(nestedGroup)}';
    }
    return categoryLabel(categoryName);
  }
}
