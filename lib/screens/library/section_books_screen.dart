import 'package:e_library/design/colors.dart';
import 'package:e_library/models/book_models.dart';
import 'package:e_library/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:async';
import '../library/search_bar.dart';
// ! Добавьте импорт модели фильтра
import '../../models/book_filter_model.dart';

import '../../widgets/book_card.dart';
import 'filter_screen.dart';

class SectionBooksScreen extends StatefulWidget {
  final String sectionTitle;

  const SectionBooksScreen({super.key, required this.sectionTitle});

  @override
  State<SectionBooksScreen> createState() => _SectionBooksScreenState();
}

class _SectionBooksScreenState extends State<SectionBooksScreen> {
  // --- НОВЫЕ ПОЛЯ ДЛЯ ПОИСКА И ФИЛЬТРАЦИИ ---
  BookFilterModel _currentFilter = BookFilterModel();
  List<Book> _booksFromApi = [];
  List<Book> _filteredBooks = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _searchController.addListener(_onSearchChanged);
  }

  // --- ЛОГИКА ЗАГРУЗКИ И ФИЛЬТРАЦИИ ---

  // 1. Метод для загрузки книг через API (с учетом фильтра)
  Future<void> _loadBooks({BookFilterModel? newFilter}) async {
    if (newFilter != null) {
      _currentFilter = newFilter;
    }

    setState(() {
      _isLoading = true;
      _booksFromApi = [];
      _filteredBooks = [];
    });

    try {
      final Map<String, dynamic> params = _currentFilter.toQueryParams();

      // Здесь вы можете добавить фильтрацию по разделу (widget.sectionTitle)
      // params['section_title'] = widget.sectionTitle;

      final List<Book> fetchedBooks = await ApiService().fetchAllBooks(
        initialQueryParams: params,
      );

      setState(() {
        _booksFromApi = fetchedBooks;
        _applyLocalSearch(_searchController.text);
      });
    } catch (e) {
      print('Ошибка загрузки книг с фильтром: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 2. Метод для локального поиска (Debounced) - БЕЗ АРГУМЕНТОВ
  void _onSearchChanged() {
    final query = _searchController.text;
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _applyLocalSearch(query);
      });
    });
  }

  // ! ⚠️ ВОССТАНОВЛЕННАЯ ФУНКЦИЯ: Принимает String для LibrarySearchBar
  void _handleSearchQuery(String query) {
    // Мы игнорируем переданный 'query' и просто запускаем логику Debounce,
    // которая сама прочитает актуальное значение из контроллера.
    _onSearchChanged();
  }

  // 3. Метод для применения локального поиска
  void _applyLocalSearch(String query) {
    if (query.isEmpty) {
      _filteredBooks = _booksFromApi;
    } else {
      final lowerCaseQuery = query.toLowerCase();
      _filteredBooks = _booksFromApi.where((book) {
        final bookTitle = book.title.toLowerCase();
        final bookAuthor = book.author.name.toLowerCase();

        return bookTitle.contains(lowerCaseQuery) ||
            bookAuthor.contains(lowerCaseQuery);
      }).toList();
    }
  }

  Future<void> _openFilter(BuildContext context) async {
    final result = await Navigator.push<BookFilterModel>(
      context,
      MaterialPageRoute(
        builder: (context) => FilterScreen(initialFilter: _currentFilter),
      ),
    );

    // Если результат получен (т.е. пользователь нажал "Save")
    if (result != null) {
      _handleFilterApplied(result);
    }
  }

  // 4. Метод для обработки результата из FilterScreen
  void _handleFilterApplied(BookFilterModel newFilter) {
    _loadBooks(newFilter: newFilter);
  }

  // ! ✅ ИСПРАВЛЕНИЕ: Оставлена только одна функция dispose()
  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // --- UI КОНТЕНТ ---

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: SpinKitFadingCircle(color: secondaryColor, size: 50.0),
      );
    }

    if (_filteredBooks.isEmpty) {
      final isSearchActive = _searchController.text.isNotEmpty;
      final message = isSearchActive
          ? 'По вашему запросу ничего не найдено.'
          : 'Книги в этом разделе не найдены.';
      return Center(child: Text(message));
    }

    // Отображение списка книг
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
      itemCount: _filteredBooks.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.45,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemBuilder: (context, index) {
        return BookCard(book: _filteredBooks[index]);
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
              // ! ИСПРАВЛЕНИЕ: Используем функцию, которая принимает String
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
