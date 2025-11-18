import 'package:flutter/material.dart';
import '../../models/book_models.dart';
// ! Убедитесь, что BookCard импортирован правильно
import '../../widgets/book_card.dart';
import '../BookDetailScreen.dart'; // Предполагаемый импорт для навигации

class BookList extends StatelessWidget {
  final List<Book> books;

  const BookList({super.key, required this.books});

  // Вспомогательный метод для навигации к деталям
  void _navigateToBookDetailsScreen(BuildContext context, Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ! 1. Удален лишний itemBuilder вне класса

    if (books.isEmpty) {
      return const Center(child: Text('Нет книг в этой секции.'));
    }

    // Создаем горизонтальный список из переданных книг
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        // ! 2. itemBuilder корректно расположен внутри ListView.builder
        itemBuilder: (context, index) {
          final book = books[index];

          return Padding(
            padding: const EdgeInsets.only(left: 16.0),
            // Используем GestureDetector, чтобы сделать карточку кликабельной
            child: GestureDetector(
              onTap: () => _navigateToBookDetailsScreen(context, book),
              child: SizedBox(
                width: 120,
                // ! 3. Использование вашего виджета BookCard
                child: BookCard(book: book),

                // ! Если BookCard требует только URL, используйте:
                // child: BookCard(coverUrl: book.thumbnailUrl, title: book.title),
              ),
            ),
          );
        },
      ),
    );
  }
}
