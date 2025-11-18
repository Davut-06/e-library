import 'dart:convert';

// Модель для автора книги
class Author {
  final String name;

  Author({required this.name});

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(name: json['name'] as String);
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
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
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

    if (categoryJson is int) {
      // Если API возвращает только ID категории
      // ! ИСПРАВЛЕНИЕ: Добавляем slug для соответствия конструктору
      parsedCategory = BookCategory(
        id: categoryJson,
        name: 'Неизвестно',
        slug: 'unknown',
      );
    } else if (categoryJson is Map<String, dynamic>) {
      // Если API возвращает полный объект категории
      parsedCategory = BookCategory.fromJson(categoryJson);
    } else {
      // Fallback
      // ! ИСПРАВЛЕНИЕ: Добавляем slug для соответствия конструктору
      parsedCategory = BookCategory(id: 0, name: 'Неизвестно', slug: 'unknown');
    }

    return Book(
      id: json['id'] as int,
      title: json['name'] as String,
      slug: json['slug'] as String,
      thumbnailUrl: json['thumbnail'] as String,
      description: json['description'] ?? 'Нет описания',
      author: Author.fromJson(json['author']),
      category: parsedCategory, // Используем адаптированный объект
      year: json['year'] as int,
      language: json['language'] as int,
      viewCount: json['view_count'] as int,
      fileUrl: json['file'] as String?,
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
    final List<dynamic> resultsList = json['results'] ?? [];
    final List<Book> books = resultsList
        .map((item) => Book.fromJson(item as Map<String, dynamic>))
        .toList();

    return BookListResponse(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: books,
    );
  }
}
