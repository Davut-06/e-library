import 'package:e_library/design/colors.dart';
import 'package:e_library/screens/library/filter_screen.dart';
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
  BookFilterModel _currentFilter = const BookFilterModel();

  // Используем BookListResponse для типа (предполагаем, что он доступен)
  Future<BookListResponse>? _searchResultsFuture;
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

    // Выход из режима поиска, если строка пуста и нет активных фильтров
    // ПРИМЕЧАНИЕ: isFilterActive() должно быть реализовано в BookFilterModel
    if (query.trim().isEmpty && !_currentFilter.isFilterActive()) {
      setState(() {
        _isSearching = false;
        _searchResultsFuture = null;
      });
      return;
    }

    // Запускаем поиск через 300 мс после последнего ввода
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final String searchString = query.trim().toLowerCase();

      // Создаем новую модель, чтобы сбросить пагинацию и установить search
      final newFilter = _currentFilter.copyWith(
        search: searchString,
        offset: 0,
      );

      setState(() {
        _currentFilter = newFilter; // Обновляем текущий фильтр
        _isSearching = true; // Переключаемся на отображение результатов поиска

        // ✅ ИСПРАВЛЕНИЕ 1: Используем единый объект BookFilterModel
        _searchResultsFuture = _apiService.fetchBooksPage(
          filter: _currentFilter.copyWith(
            limit: 50,
          ), // Устанавливаем лимит для поиска
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

  // ********************************************
  // * НОВЫЙ МЕТОД: Открытие экрана фильтрации и обработка результата
  // ********************************************
  void _openFilterScreen() async {
    // Предполагается, что FilterScreen импортирован (добавил его выше)
    final BookFilterModel? newFilter = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilterScreen(initialFilter: _currentFilter),
      ),
    );

    // 2. Если пользователь нажал "Сохранить" (т.е. newFilter не null)
    if (newFilter != null && newFilter != _currentFilter) {
      // 3. Обновляем текущий фильтр и сбрасываем пагинацию
      setState(() {
        _currentFilter = newFilter.copyWith(offset: 0);
      });

      // 4. ГЛАВНАЯ ЛОГИКА: Перезапускаем отображение с фильтром.

      final bool hasTextSearch = newFilter.search?.isNotEmpty == true;
      final bool hasOtherFilters = newFilter.isFilterActive(ignoreSearch: true);

      // Если есть какой-либо активный фильтр (текст ИЛИ другие)
      if (hasTextSearch || hasOtherFilters) {
        setState(() {
          _isSearching = true;
          // ✅ ИСПРАВЛЕНИЕ 2: Используем единый объект BookFilterModel
          _searchResultsFuture = _apiService.fetchBooksPage(
            filter: _currentFilter.copyWith(limit: 50),
          );
        });

        // Если фильтры сброшены (и _isSearching был активен), возвращаемся к обычному виду
      } else if (_isSearching) {
        setState(() {
          _isSearching = false;
          _searchResultsFuture = null;
        });
      }
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
          child: FutureBuilder<BookListResponse>(
            // Используем BookListResponse для точного типа
            // Оборачиваем вызов Future в Future.delayed
            future: Future.delayed(Duration(milliseconds: delayMs), () {
              // ✅ ИСПРАВЛЕНИЕ 3: Используем единый объект BookFilterModel
              return _apiService.fetchBooksPage(
                filter: section.filter.copyWith(
                  limit: 10,
                ), // Устанавливаем лимит для секции
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
                      'Ошибка загрузки: ${section.title} временно недоступна.',
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

              return BookList(
                books: books as List<Book>,
              ); // Приведение типа, если BookList ожидает List<Book>
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
      return FutureBuilder<BookListResponse>(
        // Используем точный тип
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
          return BookSearchResultsList(books: books as List<Book>);
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
            // ! КЛЮЧЕВОЕ ИСПРАВЛЕНИЕ: Мы используем cat.name для фильтрации,
            // ! предполагая, что API фильтрует по имени категории,
            // ! так как categoryId мог не работать в BookFilterModel.
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
              // ✅ НОВОЕ: Передаем метод, который открывает FilterScreen
              onFilterPressed: _openFilterScreen,
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
  // ... (остальная часть BookSearchResultsList не менялась)
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
              width: 70,
              height: 100,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: (book.thumbnailUrl.isNotEmpty)
                    ? Image.network(
                        book.thumbnailUrl,
                        fit: BoxFit.contain,
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
