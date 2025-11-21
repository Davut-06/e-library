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

// ! ИСПРАВЛЕННАЯ Модель для категории книги
class BookCategory {
  final int id;
  final String name;
  final String slug;

  BookCategory({required this.name, required this.id, required this.slug});

  factory BookCategory.fromJson(Map<String, dynamic> json) {
    return BookCategory(
      id: _parseInt(json['id']),
      name: _asString(json['name'], fallback: 'Неизвестно'),
      slug: _asString(json['slug'], fallback: 'unknown'),
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
  final String? fileUrl;

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
    final List<dynamic> resultsList = resultsRaw is List ? resultsRaw : const [];
    final List<Book> books = resultsList
        .whereType<Map<String, dynamic>>()
        .map((item) => Book.fromJson(item))
        .toList();

    return BookListResponse(
      count: _parseInt(json['count']),
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: books,
    );
  }
}

int _parseInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value is String) return value;
  if (value != null) return value.toString();
  return fallback;
}
