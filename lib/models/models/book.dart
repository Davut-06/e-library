import 'package:flutter/foundation.dart';

// Class representing a single book from the API
class Book {
  final int id;
  final String title;
  final String author;
  final String coverUrl;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
  });

  // Factory constructor to create a Book object from a JSON map
  factory Book.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print('Parsing JSON for Book: $json');
    }

    // ⚠️ ВАЖНО: Проверьте эти ключи ('title', 'author', 'cover_url', 'id')
    // и измените их, если ваш сервер использует другие названия (например, 'name', 'writer', 'pk').
    return Book(
      id: json['id'] as int? ?? json['pk'] as int? ?? 0,
      title:
          json['title'] as String? ?? json['name'] as String? ?? 'Нет названия',
      author:
          json['author'] as String? ??
          json['writer'] as String? ??
          'Неизвестен',
      coverUrl: json['cover_url'] as String? ?? json['cover'] as String? ?? '',
    );
  }
}
