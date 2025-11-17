import 'package:e_library/design/colors.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'section_books_screen.dart';
import '../../widgets/section_header.dart';
import 'book_list.dart'; // Предполагаемый импорт для отображения секций
import 'search_bar.dart'; // Предполагаемый импорт для строки поиска
import '../../services/api_services.dart';
import '../../models/book_models.dart';
import '../BookDetailScreen.dart';
// import 'package:e_library/screens/library/filter_screen.dart'; // Если не используется, можно удалить

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final ApiService _apiService = ApiService();

  List<Book> _allBooks = [];
  List<Book> _filteredBooks = [];
  bool _isLoading = true;
  bool _isSearching = false;

  Timer? _debounce;

  final popularTitle = 'Popular';
  final newTitle = 'New';
  final storiesTitle = 'Strories';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final books = await _apiService.fetchAllBooks();
      setState(() {
        _allBooks = books;
        _filteredBooks = books;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
        // Можно добавить логику, чтобы показать ошибку пользователю
        _allBooks = [];
      });
    }
  }

  void _filterBooks(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final lowerCaseQuery = query.toLowerCase().trim();

      setState(() {
        _isSearching = lowerCaseQuery.isNotEmpty;

        if (lowerCaseQuery.isEmpty) {
          _filteredBooks = _allBooks;
        } else {
          _filteredBooks = _allBooks.where((book) {
            final titleMatches = book.title.toLowerCase().contains(
              lowerCaseQuery,
            );
            final authorMatches = book.author.name.toLowerCase().contains(
              lowerCaseQuery,
            );
            return titleMatches || authorMatches;
          }).toList();
        }
      });
    });
  }

  void navigateToSection(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SectionBooksScreen(sectionTitle: title),
      ),
    );
  }

  // 💡 НОВЫЙ МЕТОД: Условное отображение контента
  Widget _buildContent() {
    // 1. Если идет загрузка, показываем индикатор
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 50.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 2. Если включен поиск, показываем результаты поиска
    if (_isSearching) {
      return BookSearchResultsList(books: _filteredBooks);
    }

    // 3. Показываем стандартные секции (только если не ищем)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 📚 Section: Popular
        SectionHeader(
          title: popularTitle,
          onTap: () => navigateToSection(context, popularTitle),
        ),
        BookList(sectionTitle: popularTitle), // Используем твой виджет BookList
        const SizedBox(height: 20),

        // 📚 Section: New
        SectionHeader(
          title: newTitle,
          onTap: () => navigateToSection(context, newTitle),
        ),
        BookList(sectionTitle: newTitle),
        const SizedBox(height: 20),

        // 📚 Section: Stories
        SectionHeader(
          title: storiesTitle,
          onTap: () => navigateToSection(context, storiesTitle),
        ),
        BookList(sectionTitle: storiesTitle),
        const SizedBox(height: 20),
      ],
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

            // 1. Search bar + filter button (Передаем функцию поиска)
            LibrarySearchBar(onSearch: _filterBooks),

            const SizedBox(height: 20),

            // 2. 💡 Вызываем метод, который условно отобразит нужный контент
            _buildContent(),
          ],
        ),
      ),
    );
  }
}

// 🖼️ Виджет для отображения результатов поиска
class BookSearchResultsList extends StatelessWidget {
  final List<Book> books;

  const BookSearchResultsList({super.key, required this.books});

  void _navigateToBookDetailsScreen(BuildContext context, Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
    );
    print('Navigating to details for: ${book.title}');
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

    // Используем Column, так как внешний виджет — ListView
    return Column(
      children: books.map((book) {
        final coverUrl = book.thumbnailUrl;
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
