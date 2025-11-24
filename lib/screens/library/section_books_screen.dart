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
  static const int _MAX_BOOK_LIMIT = 5000;
  final TextEditingController _searchController = TextEditingController();
  List<Book> _allLoadedBooks = [];
  List<Book> _displayBooks = [];
  BookFilterModel _currentFilter = BookFilterModel();
  int _currentPageOffset = 0;
  late final int _pageSize = _MAX_BOOK_LIMIT;
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
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  bool _onNotification(ScrollNotification scrollInfo) {
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
      _currentFilter = newFilter;
      _allLoadedBooks = [];
      _currentPageOffset = 0;
      _hasMore = true;
      _searchController.clear();
      _isLocallySearching = false;
    }
    if (!_hasMore) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final int limitForRequest = _currentPageOffset == 0
          ? _MAX_BOOK_LIMIT
          : _pageSize;
      final Map<String, dynamic> params = _currentFilter.toQueryParams();
      final response = await _apiService.fetchBooksPage(
        initialQueryParams: params,
        limit: limitForRequest,
        offset: _currentPageOffset,
      );
      setState(() {
        _allLoadedBooks.addAll(response.results as List<Book>);
        _hasMore = response.results.length == limitForRequest;
        _currentPageOffset += limitForRequest;
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
    return GridView.builder(
      primary: false,
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
      itemCount:
          _displayBooks.length + (_hasMore && !_isLocallySearching ? 1 : 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.45,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemBuilder: (context, index) {
        if (index == _displayBooks.length) {
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
