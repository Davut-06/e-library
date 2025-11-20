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

  // ⚠️ КОНТРОЛЛЕР СКОММЕНТИРОВАН ДЛЯ РАБОТЫ С WEB (NotificationListener)
  // final ScrollController _scrollController = ScrollController();

  final TextEditingController _searchController = TextEditingController();

  // --- ПОСТРАНИЧНАЯ ЗАГРУЗКА ---
  List<Book> _allLoadedBooks = [];
  List<Book> _displayBooks = [];
  BookFilterModel _currentFilter = BookFilterModel();

  int _currentPageOffset = 0;

  final int _pageSize = 100;

  bool _isLoading = false;
  bool _hasMore = true;
  bool _isLocallySearching = false;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;

    _loadNextPage();
    _searchController.addListener(_onSearchChanged);

    // ⚠️ ЛОГИКА SCROLL КОНТРОЛЛЕРА СКОММЕНТИРОВАНА
    // _scrollController.addListener(_onScroll);
  }

  // --- ЛОГИКА SCROLL ДЛЯ ANDROID (СКОММЕНТИРОВАНО) ---
  /*
  void _onScroll() {
    // Если достигнут конец списка (с небольшим запасом)
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoading &&
        _hasMore &&
        !_isLocallySearching) {
      _loadNextPage();
    }
  }
  */

  // --- ЛОГИКА SCROLL ДЛЯ WEB (NotificationListener) ---
  bool _onNotification(ScrollNotification scrollInfo) {
    // Проверяем, достигнут ли конец прокрутки (90% от maxExtent)
    if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.9 &&
        !_isLoading &&
        _hasMore &&
        !_isLocallySearching) {
      _loadNextPage();
      return true; // Указываем, что нотификация обработана
    }
    return false;
  }

  // ! МЕТОД ПОСТРАНИЧНОЙ ЗАГРУЗКИ
  Future<void> _loadNextPage({BookFilterModel? newFilter}) async {
    if (_isLoading) return;

    if (newFilter != null) {
      _currentFilter = newFilter;
      _allLoadedBooks = [];
      _currentPageOffset = 0;
      _hasMore = true;
      _searchController.clear();
      _isLocallySearching = false;

      // ⚠️ СБРОС СКРОЛЛА: используем проверку, так как контроллер теперь опционален
      // if (_scrollController.hasClients) {
      //   _scrollController.jumpTo(0);
      // }
    }

    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> params = _currentFilter.toQueryParams();

      final response = await _apiService.fetchBooksPage(
        initialQueryParams: params,
        limit: _pageSize,
        offset: _currentPageOffset,
      );

      setState(() {
        _allLoadedBooks.addAll(response.results as List<Book>);

        _hasMore = response.results.length == _pageSize;

        _currentPageOffset += _pageSize;
        _isLoading = false;

        _applyLocalSearch(_searchController.text);
      });
    } catch (e) {
      debugPrint('Ошибка загрузки страницы: $e');
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

  void _handleFilterApplied(BookFilterModel newFilter) {
    _loadNextPage(newFilter: newFilter);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();

    // ⚠️ DISPOSE КОНТРОЛЛЕРА СКОММЕНТИРОВАНО
    // _scrollController.dispose();

    super.dispose();
  }

  // --- UI КОНТЕНТ ---

  Widget _buildContent() {
    if (_allLoadedBooks.isEmpty && _isLoading) {
      return Center(
        child: SpinKitFadingCircle(color: primaryColor, size: 50.0),
      );
    }

    if (_displayBooks.isEmpty && !_isLoading) {
      final message = _isLocallySearching
          ? 'По вашему запросу ничего не найдено.'
          : 'Книги в этом разделе не найдены.';
      return Center(
        child: Text(message, style: TextStyle(color: secondaryColor)),
      );
    }

    // Отображение списка книг
    return GridView.builder(
      // ⚠️ КОНТРОЛЛЕР СКОММЕНТИРОВАН
      // controller: _scrollController,
      primary: false,

      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
      itemCount:
          _displayBooks.length + (_hasMore && !_isLocallySearching ? 1 : 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.5,
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

        final book = _displayBooks[index];
        return BookCard(book: book);
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
      // !!! ИСПОЛЬЗУЕМ NotificationListener ДЛЯ ОБРАБОТКИ SCROLL В WEB !!!
      body: NotificationListener<ScrollNotification>(
        onNotification: _onNotification,
        child: Column(
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
      ),
    );
  }
}
