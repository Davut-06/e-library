import 'package:e_library/design/colors.dart';
import 'package:e_library/models/book_models.dart';
import 'package:e_library/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:async';
import 'search_bar.dart';
import '../../models/book_filter_model.dart';
import '../../widgets/book_card.dart';
import 'filter_screen.dart';
import '../BookDetailScreen.dart'; // Предполагаемый импорт для навигации

class SectionBooksScreen extends StatefulWidget {
  final String sectionTitle;
  final BookFilterModel initialFilter;
  const SectionBooksScreen({
    super.key,
    required this.sectionTitle,
    required this.initialFilter,
  });
  @override
  State<SectionBooksScreen> createState() => _SectionBooksScreenState();
}

class _SectionBooksScreenState extends State<SectionBooksScreen> {
  final ApiService _apiService = ApiService();
  static const int _MAX_BOOK_LIMIT = 5000;
  final TextEditingController _searchController = TextEditingController();
  List<Book> _allLoadedBooks = [];
  List<Book> _displayBooks = [];
  BookFilterModel _currentFilter = BookFilterModel();
  int _currentPageOffset = 0;
  // NOTE: Используем _MAX_BOOK_LIMIT только для первой загрузки, затем _pageSize для пагинации
  late final int _pageSize =
      30; // Установим разумный размер страницы для последующих запросов.
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isLocallySearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
    // Начинаем загрузку с начальным фильтром
    _loadNextPage();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  bool _onNotification(ScrollNotification scrollInfo) {
    // Триггер загрузки следующей страницы при прокрутке до 90%
    if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.9 &&
        !_isLoading &&
        _hasMore &&
        !_isLocallySearching) {
      _loadNextPage();
      return true;
    }
    return false;
  }

  Future<void> _loadNextPage({BookFilterModel? newFilter}) async {
    if (_isLoading) return;

    if (newFilter != null) {
      // 1. Сброс состояния, если применен новый фильтр
      _currentFilter = newFilter;
      _allLoadedBooks = [];
      _currentPageOffset = 0;
      _hasMore = true;
      _searchController.clear();
      _isLocallySearching = false;
    }

    // Если книги уже загружены, а мы не сбрасывали фильтр, то не загружаем
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Загружаем MAX_BOOK_LIMIT только в первый раз
      // Последующие запросы будут использовать _pageSize
      final int limitForRequest = _currentPageOffset == 0
          ? _MAX_BOOK_LIMIT
          : _pageSize;

      // 1. Создаем единую модель фильтра для запроса, включая limit и offset
      final BookFilterModel filterForRequest = _currentFilter.copyWith(
        offset: _currentPageOffset,
        limit: limitForRequest,
      );

      // 2. Используем новую сигнатуру с 'filter:'
      final response = await _apiService.fetchBooksPage(
        filter: filterForRequest,
      );

      setState(() {
        _allLoadedBooks.addAll(response.results as List<Book>);
        _hasMore = response.results.length == limitForRequest;
        _currentPageOffset += limitForRequest;
        _isLoading = false;
        // Применяем локальный поиск к новым данным
        _applyLocalSearch(_searchController.text);
      });
    } catch (e) {
      debugPrint('Ошибка загрузки страницы: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _applyLocalSearch(query);
      });
    });
  }

  void _handleSearchQuery(String query) {
    // Просто вызываем обработчик изменения текста, который включает debounce
    _onSearchChanged();
  }

  void _applyLocalSearch(String query) {
    _isLocallySearching = query.isNotEmpty;
    if (query.isEmpty) {
      _displayBooks = _allLoadedBooks;
    } else {
      final lowerCaseQuery = query.toLowerCase();
      _displayBooks = _allLoadedBooks.where((book) {
        final bookTitle = book.title.toLowerCase();

        // ✅ ИСПРАВЛЕНИЕ NULL SAFETY: Используем ?. и ??
        final bookAuthor = book.author?.name.toLowerCase() ?? '';

        return bookTitle.contains(lowerCaseQuery) ||
            bookAuthor.contains(lowerCaseQuery);
      }).toList();
    }
  }

  // ✅ МЕТОД ДЛЯ ОБРАБОТКИ КНОПКИ ФИЛЬТРА
  Future<void> _onFilterPressed(BuildContext context) async {
    final result = await Navigator.push<BookFilterModel>(
      context,
      MaterialPageRoute(
        builder: (context) => FilterScreen(initialFilter: _currentFilter),
      ),
    );

    if (result != null && result != _currentFilter) {
      // 🔑 Вызываем _loadNextPage для сброса данных и загрузки с новым фильтром
      _loadNextPage(newFilter: result);
    }
  }

  // ✅ Метод для навигации на экран деталей книги
  void _navigateToBookDetailsScreen(BuildContext context, Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
    );
  }

  Widget _buildContent() {
    // Состояние: Первичная загрузка
    if (_allLoadedBooks.isEmpty && _isLoading && !_isLocallySearching) {
      return Center(
        child: SpinKitFadingCircle(color: primaryColor, size: 50.0),
      );
    }

    // Состояние: Нет результатов
    if (_displayBooks.isEmpty && !_isLoading) {
      final message = _isLocallySearching
          ? 'По вашему запросу ничего не найдено.'
          : 'Книги в этом разделе не найдены.';
      return Center(
        child: Text(message, style: const TextStyle(color: secondaryColor)),
      );
    }

    // Состояние: Отображение книг
    return GridView.builder(
      primary: false,
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
      // Добавляем 1 для индикатора загрузки, если есть еще данные
      itemCount:
          _displayBooks.length + (_hasMore && !_isLocallySearching ? 1 : 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.45,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemBuilder: (context, index) {
        // Элемент: Индикатор загрузки
        if (index == _displayBooks.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        // Элемент: Карточка книги
        final book = _displayBooks[index];
        return GestureDetector(
          onTap: () => _navigateToBookDetailsScreen(context, book),
          child: BookCard(book: book),
        );
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
      // Обертываем в NotificationListener для пагинации при прокрутке
      body: NotificationListener<ScrollNotification>(
        onNotification: _onNotification,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: LibrarySearchBar(
                onSearch: _handleSearchQuery,
                controller: _searchController,
                // ✅ ПЕРЕДАЧА МЕТОДА ДЛЯ ОБРАБОТКИ КНОПКИ ФИЛЬТРА
                onFilterPressed: () => _onFilterPressed(context),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              // Используем ListView, так как GridView.builder внутри _buildContent
              // имеет shrinkWrap: true и его нужно обернуть в скроллящийся виджет
              child: ListView(
                children: [
                  _buildContent(),
                  // Если индикатор загрузки не встроен в GridView (что происходит, когда
                  // книги уже есть, но идет дозагрузка), отображаем его здесь.
                  // (В текущей реализации он встроен в GridView, но эта проверка полезна для отладки).
                  if (_hasMore &&
                      !_isLocallySearching &&
                      _isLoading &&
                      _allLoadedBooks.isNotEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),

                  const SizedBox(height: 16), // Дополнительное место внизу
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
