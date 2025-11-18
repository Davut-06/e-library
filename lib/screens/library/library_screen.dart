import 'package:e_library/design/colors.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'section_books_screen.dart'; // Экран "Смотреть все"
import '../../widgets/section_header.dart';
import 'book_list.dart'; // Виджет для горизонтального списка книг
import 'search_bar.dart'; // Виджет строки поиска
import '../../services/api_services.dart';
import '../../models/book_models.dart';
import '../../models/book_filter_model.dart';
import '../BookDetailScreen.dart';

// Вспомогательная структура для секции
class SectionConfig {
  final String title;
  final BookFilterModel filter;
  SectionConfig({required this.title, required this.filter});
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<BookCategory>> _categoriesFuture;

  // Флаги и состояние поиска
  bool _isSearching = false;
  BookFilterModel _currentFilter = BookFilterModel();

  // Добавьте импорт BookListResponse, если он не импортирован выше
  Future<dynamic>? _searchResultsFuture;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _apiService.fetchAllCategories();
  }

  // ********************************************
  // * МЕТОД: Логика поиска через API с Debounce
  // ********************************************
  void _runApiSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Выход из режима поиска, если строка пуста
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResultsFuture = null;
      });
      return;
    }

    // Запускаем поиск через 300 мс после последнего ввода
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final filter = BookFilterModel(search: query.trim());

      setState(() {
        _isSearching = true;
        _searchResultsFuture = _apiService.fetchBooksPage(
          initialQueryParams: filter.toQueryParams(),
          limit: 50,
          offset: 0,
        );
      });
    });
  }

  // Метод перехода на экран "Смотреть все"
  void navigateToSection(
    BuildContext context,
    String title,
    BookFilterModel filter,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SectionBooksScreen(sectionTitle: title, initialFilter: filter),
      ),
    );
  }

  void _handleFilterApplied(BookFilterModel newFilter) {
    setState(() {
      _currentFilter = newFilter;
    });
    // Если поиск активен, перезапускаем его с новым фильтром
    if (_isSearching) {
      _runApiSearch(_currentFilter.search ?? '');
    }
  }

  // ********************************************
  // * МЕТОД: Построение секции (загрузка 10 книг)
  // ********************************************
  Widget _buildSection(BuildContext context, SectionConfig section) {
    // ! СОХРАНЕННАЯ ЗАДЕРЖКА: Используем для предотвращения перегрузки API.
    final int delayMs = (section.title.hashCode % 300).abs() + 50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: section.title,
          onTap: () =>
              navigateToSection(context, section.title, section.filter),
        ),

        SizedBox(
          height: 250,
          child: FutureBuilder<dynamic>(
            // Используем dynamic, чтобы избежать проблем с типами, если BookListResponse не импортирован
            // Оборачиваем вызов Future в Future.delayed
            future: Future.delayed(Duration(milliseconds: delayMs), () {
              return _apiService.fetchBooksPage(
                initialQueryParams: section.filter.toQueryParams(),
                limit: 10,
              );
            }),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                // Более информативное сообщение об ошибке API
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Ошибка загрузки: ${section.title} временно недоступна (503).',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final books = snapshot.data?.results ?? [];

              if (books.isEmpty) {
                return const Center(child: Text('Книги не найдены.'));
              }

              return BookList(books: books);
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ********************************************
  // * МЕТОД: Условное отображение контента
  // ********************************************
  Widget _buildContent() {
    // 1. Если активен поиск, отображаем FutureBuilder с результатами
    if (_isSearching && _searchResultsFuture != null) {
      return FutureBuilder<dynamic>(
        future: _searchResultsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 50.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка поиска: ${snapshot.error}'));
          }

          final books = snapshot.data?.results ?? [];
          return BookSearchResultsList(books: books);
        },
      );
    }

    // 2. Если поиск неактивен, отображаем категории
    return FutureBuilder<List<BookCategory>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 50.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Ошибка загрузки категорий: ${snapshot.error}'),
          );
        }

        final categories = snapshot.data ?? [];

        // ГЕНЕРАЦИЯ SectionConfig
        final List<SectionConfig> librarySections = categories.map((cat) {
          return SectionConfig(
            title: cat.name,
            // ! КЛЮЧЕВОЕ ИСПРАВЛЕНИЕ: Возвращаем поиск по имени.
            // ! Это устранит проблемы, если API не принимает categoryId для фильтрации книг.
            // ! (Требует Uri.encodeQueryComponent в BookFilterModel.toQueryParams())
            filter: BookFilterModel(search: cat.name),
          );
        }).toList();

        // 3. Отображаем динамические секции
        return Column(
          children: librarySections.map((section) {
            return _buildSection(context, section);
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 8.0,
        title: const Text(
          'Library',
          style: TextStyle(
            color: secondaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            const SizedBox(height: 10),

            // 1. Search bar + filter button
            LibrarySearchBar(
              onSearch: _runApiSearch, // Привязка к методу поиска API
              currentFilter: _currentFilter,
              onFilterApplied: _handleFilterApplied,
            ),

            const SizedBox(height: 20),

            // 2. Вызываем метод, который условно отобразит нужный контент
            _buildContent(),
          ],
        ),
      ),
    );
  }
}

// 🖼️ Виджет для отображения результатов поиска (оставлен без изменений)
class BookSearchResultsList extends StatelessWidget {
  final List<Book> books;

  const BookSearchResultsList({super.key, required this.books});

  void _navigateToBookDetailsScreen(BuildContext context, Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 50.0),
          child: Text(
            'Ничего не найдено',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return Column(
      children: books.map((book) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: SizedBox(
              width: 50,
              height: 70,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: (book.thumbnailUrl.isNotEmpty)
                    ? Image.network(
                        book.thumbnailUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primaryColor,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, size: 20),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.book, size: 20),
                      ),
              ),
            ),
            title: Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(book.author.name),
            onTap: () => _navigateToBookDetailsScreen(context, book),
          ),
        );
      }).toList(),
    );
  }
}
