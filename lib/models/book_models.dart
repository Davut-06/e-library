// Модель для автора книги
class Author {
  final String name;

  Author({required this.name});

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(name: _asString(json['name'], fallback: 'Неизвестный автор'));
  }

  factory Author.fromDynamic(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return Author.fromJson(raw);
    }
    if (raw is String) {
      return Author(name: raw);
    }
    return Author(name: 'Неизвестный автор');
  }
}

// ! ИСПРАВЛЕННАЯ Модель для категории книги (Slug теперь nullable)
class BookCategory {
  final int id;
  final String name;
  // Slug может быть null в заглушках или если отсутствует в API
  final String? slug;

  BookCategory({required this.name, required this.id, this.slug});

  factory BookCategory.fromJson(Map<String, dynamic> json) {
    return BookCategory(
      id: _parseInt(json['id']),
      name: _asString(json['name'], fallback: 'Неизвестно'),
      // slug берется как String?, если _asString возвращает пустую строку ('')
      slug: _asString(json['slug'], fallback: '').isEmpty
          ? null
          : _asString(json['slug']),
    );
  }
}

// Модель для опций фильтра (Авторы, Предметы, Жанры, Языки)
class FilterOption {
  final int id;
  final String name;
  final String? slug;

  FilterOption({required this.id, required this.name, this.slug});

  factory FilterOption.fromJson(Map<String, dynamic> json) {
    return FilterOption(
      // Часто ID называется 'pk' или 'id'
      id: _parseInt(json['id'] ?? json['pk']),
      // Название может быть 'name' или 'title'
      name: _asString(json['name'] ?? json['title'], fallback: 'Неизвестно'),
      // Slug может быть null
      slug: _asString(json['slug'], fallback: '').isEmpty
          ? null
          : _asString(json['slug']),
    );
  }
}

// Основная модель для одной книги
class Book {
  final int id;
  final String title;
  final String slug;
  final String thumbnailUrl;
  final String description;
  final Author author;
  final BookCategory category;
  final int year;
  final int language;
  final int viewCount;
  // Это поле уже было nullable, что корректно
  final String? fileUrl;

  // Все поля, получающие значения через _asString с fallback, остаются required String
  Book({
    required this.id,
    required this.title,
    required this.slug,
    required this.thumbnailUrl,
    required this.description,
    required this.author,
    required this.category,
    required this.year,
    required this.language,
    required this.viewCount,
    this.fileUrl,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    // ! Адаптация для обработки вложенной категории
    final categoryJson = json['category'];
    BookCategory parsedCategory;

    if (categoryJson is int || categoryJson is String) {
      // Если API возвращает только ID категории
      parsedCategory = BookCategory(
        id: _parseInt(categoryJson),
        name: 'Неизвестно',
        slug: 'unknown',
      );
    } else if (categoryJson is Map<String, dynamic>) {
      // Если API возвращает полный объект категории
      parsedCategory = BookCategory.fromJson(categoryJson);
    } else {
      // Fallback
      parsedCategory = BookCategory(id: 0, name: 'Неизвестно', slug: 'unknown');
    }

    // Обратите внимание: _asString гарантирует, что эти поля не будут null
    // (они будут ' ' или 'Без названия' и т.д. в случае null),
    // поэтому они могут оставаться required String в конструкторе.
    return Book(
      id: _parseInt(json['id']),
      title: _asString(json['name'], fallback: 'Без названия'),
      slug: _asString(json['slug'], fallback: ''),
      thumbnailUrl: _asString(json['thumbnail']),
      description: _asString(json['description'], fallback: 'Нет описания'),
      author: Author.fromDynamic(json['author']),
      category: parsedCategory, // Используем адаптированный объект
      year: _parseInt(json['year']),
      language: _parseInt(json['language']),
      viewCount: _parseInt(json['view_count']),
      fileUrl: _asString(json['file'], fallback: '').isEmpty
          ? null
          : _asString(json['file']),
    );
  }
}

// Модель для ответа API (контейнер, содержащий список в поле 'results')
class BookListResponse {
  final int count;
  // next и previous уже корректно объявлены как nullable String?
  final String? next;
  final String? previous;
  final List<Book> results;

  BookListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory BookListResponse.fromJson(Map<String, dynamic> json) {
    final resultsRaw = json['results'];
    final List<dynamic> resultsList = resultsRaw is List
        ? resultsRaw
        : const [];
    final List<Book> books = resultsList
        .whereType<Map<String, dynamic>>()
        .map((item) => Book.fromJson(item))
        .toList();

    return BookListResponse(
      count: _parseInt(json['count']),
      // Значения next и previous уже корректно читаются как String?
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: books,
    );
  }
}

// --- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ---

int _parseInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

// _asString корректно возвращает не-null String (fallback)
String _asString(dynamic value, {String fallback = ''}) {
  if (value is String) return value;
  if (value != null) return value.toString();
  return fallback;
}
