import 'dart:convert';

// Модель для автора книги
class Author {
  final String name;

  Author({required this.name});

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(name: json['name'] as String);
  }
}

// Модель для категории книги
class BookCategory {
  final String name;

  BookCategory({required this.name});

  factory BookCategory.fromJson(Map<String, dynamic> json) {
    return BookCategory(name: json['name'] as String);
  }
}

// Основная модель для одной книги
class Book {
  final int id;
  final String title; // Соответствует полю 'name' в JSON
  final String slug;
  final String
  thumbnailUrl; // Соответствует полю 'thumbnail' в JSON (URL обложки)
  final String description;
  final Author author;
  final BookCategory category;
  final int year;
  final int language;
  final int viewCount;

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
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as int,
      title: json['name'] as String, // ! Используем 'name'
      slug: json['slug'] as String,
      thumbnailUrl: json['thumbnail'] as String, // ! Используем 'thumbnail'
      description: json['description'] ?? 'Нет описания',
      author: Author.fromJson(json['author']), // Парсим вложенный объект
      category: BookCategory.fromJson(
        json['category'],
      ), // Парсим вложенный объект
      year: json['year'] as int,
      language: json['language'] as int,
      viewCount: json['view_count'] as int,
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
