import 'package:e_library/design/colors.dart';
import 'package:e_library/models/book_models.dart';
import 'package:e_library/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:async';
import 'search_bar.dart';
import '../../models/book_filter_model.dart';
// Обязательный импорт
import '../../widgets/book_card.dart';
import 'filter_screen.dart';

class SectionBooksScreen extends StatefulWidget {
  final String sectionTitle;
  final BookFilterModel initialFilter; // Фильтр, переданный с LibraryScreen

  const SectionBooksScreen({
    super.key,
    required this.sectionTitle,
    required this.initialFilter, // Сделали final
  });

  @override
  State<SectionBooksScreen> createState() => _SectionBooksScreenState();
}

class _SectionBooksScreenState extends State<SectionBooksScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // --- ПОСТРАНИЧНАЯ ЗАГРУЗКА ---
  List<Book> _allLoadedBooks = []; // Все книги, загруженные с API
  List<Book> _displayBooks =
      []; // Книги для отображения (после локального поиска)
  BookFilterModel _currentFilter = BookFilterModel();

  int _currentPageOffset = 0;
  final int _pageSize = 20;
  bool _isLoading = false;
  bool _hasMore = true; // Есть ли еще страницы для загрузки
  bool _isLocallySearching = false;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // ! 1. Инициализируем фильтр, переданный из LibraryScreen (например, search=CategoryName)
    _currentFilter = widget.initialFilter;

    _loadNextPage(); // Запускаем первую загрузку
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  // --- ЛОГИКА SCROLL И ЗАГРУЗКИ ---

  void _onScroll() {
    // Если достигнут конец списка (с небольшим запасом)
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoading &&
        _hasMore &&
        !_isLocallySearching // Не грузим, пока ищем локально
        ) {
      _loadNextPage();
    }
  }

  // ! 2. МЕТОД ПОСТРАНИЧНОЙ ЗАГРУЗКИ (Заменяет _loadBooks)
  Future<void> _loadNextPage({BookFilterModel? newFilter}) async {
    if (_isLoading) return;

    if (newFilter != null) {
      // Если применили новый фильтр, сбрасываем все
      _currentFilter = newFilter;
      _allLoadedBooks = [];
      _currentPageOffset = 0;
      _hasMore = true;
      _scrollController.jumpTo(0);
    }

    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // ! 3. Используем _currentFilter для параметров запроса API
      final Map<String, dynamic> params = _currentFilter.toQueryParams();

      final BookListResponse response = await _apiService.fetchBooksPage(
        initialQueryParams: params,
        limit: _pageSize,
        offset: _currentPageOffset,
      );

      setState(() {
        _allLoadedBooks.addAll(response.results);
        _hasMore =
            response.results.length ==
            _pageSize; // Если пришло меньше чем pageSize, значит это последняя страница
        _currentPageOffset += _pageSize;
        _isLoading = false;
        // После загрузки применяем локальный поиск (если он был активен)
        _applyLocalSearch(_searchController.text);
      });
    } catch (e) {
      print('Ошибка загрузки страницы: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- ЛОКАЛЬНЫЙ ПОИСК ---

  void _onSearchChanged() {
    final query = _searchController.text;
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _applyLocalSearch(query);
      });
    });
  }

  // ! Метод для LibrarySearchBar (обязателен, но просто вызывает _onSearchChanged)
  void _handleSearchQuery(String query) {
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
        final bookAuthor = book.author.name.toLowerCase();

        return bookTitle.contains(lowerCaseQuery) ||
            bookAuthor.contains(lowerCaseQuery);
      }).toList();
    }
  }

  // --- ФИЛЬТРАЦИЯ ---

  Future<void> _openFilter(BuildContext context) async {
    final result = await Navigator.push<BookFilterModel>(
      context,
      MaterialPageRoute(
        builder: (context) => FilterScreen(initialFilter: _currentFilter),
      ),
    );

    if (result != null) {
      _handleFilterApplied(result);
    }
  }

  // 4. Метод для обработки результата из FilterScreen
  void _handleFilterApplied(BookFilterModel newFilter) {
    // ! Запускаем загрузку с новым фильтром и сбросом страниц
    _loadNextPage(newFilter: newFilter);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- UI КОНТЕНТ ---

  Widget _buildContent() {
    if (_allLoadedBooks.isEmpty && _isLoading) {
      // Отображаем SpinKit только при первой загрузке
      return const Center(
        child: SpinKitFadingCircle(color: secondaryColor, size: 50.0),
      );
    }

    if (_displayBooks.isEmpty && !_isLoading) {
      final isSearchActive = _searchController.text.isNotEmpty;
      final message = isSearchActive
          ? 'По вашему запросу ничего не найдено.'
          : 'Книги в этом разделе не найдены.';
      return Center(child: Text(message));
    }

    // Отображение списка книг
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
      itemCount:
          _displayBooks.length +
          (_hasMore && !_isLocallySearching
              ? 1
              : 0), // Добавляем место для лоадера
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // Обычно 3, а не 4 для комфортного просмотра
        childAspectRatio: 0.5, // Изменен для 3х-колоночной сетки
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemBuilder: (context, index) {
        if (index == _displayBooks.length) {
          // Лоадер для бесконечного скролла
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return BookCard(book: _displayBooks[index]);
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
            child: LibrarySearchBar(
              onSearch: _handleSearchQuery,
              controller: _searchController,
              currentFilter: _currentFilter,
              onFilterApplied: _handleFilterApplied,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }
}
