import 'package:e_library/design/colors.dart';
import 'package:e_library/models/book_models.dart';
import 'package:e_library/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:async';
import '../library/search_bar.dart'; // ✅ Импортируем наш SearchBar

import '../../widgets/book_card.dart';
import 'filter_screen.dart';

// SectionBooksScreen теперь StatefulWidget
class SectionBooksScreen extends StatefulWidget {
  final String sectionTitle;

  const SectionBooksScreen({super.key, required this.sectionTitle});

  @override
  State<SectionBooksScreen> createState() => _SectionBooksScreenState();
}

class _SectionBooksScreenState extends State<SectionBooksScreen> {
  // --- НОВЫЕ ПОЛЯ ДЛЯ ПОИСКА И ФИЛЬТРАЦИИ ---
  List<Book> _allSectionBooks =
      []; // Все загруженные книги раздела (для фильтрации)
  List<Book> _filteredBooks = []; // Список для отображения
  bool _isSearching = false; // Состояние поиска

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce; // Для Debouncing

  // --- СТАРЫЕ ПОЛЯ ---
  late Future<List<Book>> _booksFuture;

  @override
  void initState() {
    super.initState();
    // ⚠️ В идеале здесь должен быть вызов API, который фильтрует по widget.sectionTitle.
    // Пока оставим fetchBooks(), но в рабочем приложении это нужно изменить.
    _booksFuture = ApiService().fetchBooks();
  }

  void _filterBooks(String query) {
    final bool shouldSearch = query.isNotEmpty;

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _isSearching = shouldSearch;

        if (shouldSearch) {
          final lowerCaseQuery = query.toLowerCase();
          _filteredBooks = _allSectionBooks.where((book) {
            final bookTitle = book.title.toLowerCase();
            final bookAuthor = book.author.name.toLowerCase();

            return bookTitle.contains(lowerCaseQuery) ||
                bookAuthor.contains(lowerCaseQuery);
          }).toList();
        } else {
          // Если запрос пуст, сбрасываем фильтр до полного списка
          _filteredBooks = _allSectionBooks;
        }
      });
    });
  }

  void _openFilter(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FilterScreen()),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildContent(List<Book> allBooks) {
    // 1. ✅ ИСПРАВЛЕНО: Правильная проверка на пустоту и инициализация списков
    if (_allSectionBooks.isEmpty) {
      _allSectionBooks = allBooks;
      _filteredBooks = allBooks;
    }

    // 2. Определяем, какой список отображать
    final booksToDisplay = _isSearching ? _filteredBooks : _allSectionBooks;

    // 3. Сообщения об отсутствии результатов
    if (booksToDisplay.isEmpty && _isSearching) {
      return const Center(child: Text('По вашему запросу ничего не найдено.'));
    }
    if (booksToDisplay.isEmpty && !_isSearching) {
      return const Center(child: Text('Книги в этом разделе не найдены.'));
    }

    // 4. Отображение списка книг
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
      itemCount: booksToDisplay.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.45,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemBuilder: (context, index) {
        return BookCard(book: booksToDisplay[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(widget.sectionTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: iconColor,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            // ✅ ЗАМЕНА СТАРОГО TextField НА LibrarySearchBar
            child: LibrarySearchBar(
              onSearch: _filterBooks, // Передаем нашу функцию
              controller: _searchController, // Для кнопки очистки
            ),
          ),
          const SizedBox(height: 16),
          // ✅ ИСПРАВЛЕНО: Правильная структура FutureBuilder
          Expanded(
            child: FutureBuilder<List<Book>>(
              future: _booksFuture,
              builder: (context, snapshot) {
                // 1. Состояние загрузки
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: SpinKitFadingCircle(
                      color: secondaryColor,
                      size: 50.0,
                    ),
                  );
                }

                // 2. Состояние ошибки
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Ошибка при загрузке книг: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                // 3. Отображение контента (или сообщения об отсутствии данных)
                if (snapshot.hasData) {
                  return _buildContent(snapshot.data!);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
