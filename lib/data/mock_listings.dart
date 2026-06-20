import '../models/listing.dart';

/// Тестовые объявления до подключения сервера.
class MockListings {
  MockListings._();

  static List<Listing> forSubcategory(String category, String subcategory) {
    final templates = _templates[category]?[subcategory] ?? _defaultTemplates;

    return List.generate(templates.length, (index) {
      final template = templates[index];
      return Listing(
        id: '${category}_${subcategory}_$index',
        ownerId: 'mock_owner_$index',
        title: template['title'] as String,
        description: template['description'] as String,
        category: category,
        subcategory: subcategory,
        authorName: template['author'] as String,
        authorLevel: template['level'] as String,
        authorRating: template['rating'] as double,
        photosCount: template['photos'] as int,
        distanceKm: template['distance'] as double,
      );
    });
  }

  static const _defaultTemplates = [
    {
      'title': 'Отдам бесплатно',
      'description': 'Вещь в хорошем состоянии, заберите сами.',
      'author': 'Анна',
      'level': 'Активный даритель',
      'rating': 4.7,
      'photos': 2,
      'distance': 1.2,
    },
    {
      'title': 'Нужно забрать сегодня',
      'description': 'Отдаю даром, самовывоз из подъезда.',
      'author': 'Игорь',
      'level': 'Новичок',
      'rating': 4.5,
      'photos': 1,
      'distance': 2.4,
    },
    {
      'title': 'Почти новое',
      'description': 'Пользовались недолго, всё работает.',
      'author': 'Мария',
      'level': 'Щедрый',
      'rating': 4.9,
      'photos': 3,
      'distance': 0.8,
    },
  ];

  static const _templates = {
    'Одежда': {
      'Мужская': [
        {
          'title': 'Куртка мужская L',
          'description': 'Лёгкая демисезонная куртка, без дыр и пятен.',
          'author': 'Дмитрий',
          'level': 'Активный даритель',
          'rating': 4.8,
          'photos': 3,
          'distance': 1.1,
        },
        {
          'title': 'Джинсы 32 размер',
          'description': 'Классические синие джинсы, носили один сезон.',
          'author': 'Олег',
          'level': 'Новичок',
          'rating': 4.4,
          'photos': 2,
          'distance': 2.0,
        },
        {
          'title': 'Свитер шерстяной',
          'description': 'Тёплый свитер, цвет тёмно-синий.',
          'author': 'Елена',
          'level': 'Щедрый',
          'rating': 4.9,
          'photos': 4,
          'distance': 0.6,
        },
      ],
    },
    'Электроника': {
      'Телефоны': [
        {
          'title': 'Samsung Galaxy A52',
          'description': 'Телефон рабочий, есть чехол и зарядка.',
          'author': 'Алексей',
          'level': 'Благотворитель',
          'rating': 4.6,
          'photos': 5,
          'distance': 1.8,
        },
        {
          'title': 'iPhone 8 64GB',
          'description': 'Батарея 78%, экран без трещин.',
          'author': 'Кирилл',
          'level': 'Активный даритель',
          'rating': 4.7,
          'photos': 4,
          'distance': 3.2,
        },
      ],
    },
    'Для дома': {
      'Мебель — Гостиная': [
        {
          'title': 'Диван-кровать',
          'description': 'Раскладной диван, нужен самовывоз и помощь при выносе.',
          'author': 'Светлана',
          'level': 'Щедрый',
          'rating': 4.5,
          'photos': 3,
          'distance': 2.5,
        },
        {
          'title': 'Журнальный столик',
          'description': 'Деревянный столик, лёгкий, можно забрать одному.',
          'author': 'Павел',
          'level': 'Новичок',
          'rating': 4.3,
          'photos': 2,
          'distance': 1.0,
        },
      ],
    },
  };
}
