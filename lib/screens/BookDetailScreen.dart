import 'package:e_library/design/colors.dart';
import 'package:e_library/models/book_models.dart';
import 'package:e_library/services/api_services.dart';
import 'package:flutter/material.dart';
import '../screens/pdf_reader_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/book_filter_model.dart';
import '../screens/library/section_books_screen.dart'; // Убедитесь, что этот импорт правильный

class BookDetailScreen extends StatelessWidget {
  final Book book;
  final ApiService _apiService = ApiService();

  BookDetailScreen({super.key, required this.book});

  // ********************************************
  // * МЕТОД: Открытие PDF или внешнего URL
  // ********************************************
  void _launchFile(BuildContext context) async {
    final String? url = book.fileUrl?.trim();
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Файл для чтения онлайн недоступен.')),
      );
      return;
    }

    final bool isPdf = url.toLowerCase().endsWith('.pdf');
    if (isPdf) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfReaderScreen(
            pdfUrl: url,
            bookTitle: book.title,
          ),
        ),
      );
      return;
    }

    final Uri? uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть ссылку: $url')),
      );
    }
  }

  // ********************************************
  // * МЕТОД: Построение основного экрана
  // ********************************************
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: iconColor,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildHeaderSection(context, book),

            const SizedBox(height: 20),
            Text(
              book.description,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: secondaryColor,
              ),
              textAlign: TextAlign.justify,
            ),

            const SizedBox(height: 30),

            _buildRecommendationsTitle(context), // Передаем context

            const SizedBox(height: 15),

            _buildRecommendationsListWidget(context), // Передаем context

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, Book book) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          height: 187,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.network(
            book.thumbnailUrl,
            height: 220,
            width: double.infinity,
            fit: BoxFit.contain,
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildMetadataRow('Author', book.author.name),

              _buildMetadataRow('Category', book.category.name),

              _buildMetadataRow('Year', book.year.toString()),

              _buildMetadataRow('Language ID', book.language.toString()),

              _buildMetadataRow('View Count', book.viewCount.toString()),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Добавить логику загрузки (заглушка)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Начало загрузки... (логика не реализована)',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Download',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: backgroundColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      // [ИСПРАВЛЕНИЕ: Вызываем общий метод _launchFile]
                      onPressed: () => _launchFile(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Read online',
                        style: TextStyle(
                          fontSize: 12,
                          color: backgroundColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: secondaryColor),
          children: <TextSpan>[
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: secondaryColor),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  // ********************************************
  // * МЕТОД: Заголовок рекомендаций ("See all")
  // ********************************************
  Widget _buildRecommendationsTitle(BuildContext context) {
    // Формируем фильтр, чтобы исключить текущую книгу при просмотре "всех" рекомендаций
    final filter = BookFilterModel(
      categoryId: book.category.id,
      excludeId: book.id,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recommendations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: secondaryVariantColor,
          ),
        ),
        TextButton(
          onPressed: () {
            // [ИСПРАВЛЕНИЕ: Логика для "See all"]
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SectionBooksScreen(
                  sectionTitle: 'Recommendations: ${book.category.name}',
                  initialFilter: filter,
                ),
              ),
            );
          },
          child: const Text('See all', style: TextStyle(color: primaryColor)),
        ),
      ],
    );
  }

  // ********************************************
  // * МЕТОД: Список рекомендаций (горизонтальный)
  // ********************************************
  Widget _buildRecommendationsListWidget(BuildContext context) {
    final filter = BookFilterModel(
      categoryId: book.category.id,
      excludeId: book.id,
    );
    return SizedBox(
      height: 200,
      child: FutureBuilder<dynamic>(
        future: _apiService.fetchBooksPage(
          initialQueryParams: filter.toQueryParams(),
          limit: 10, // Ограничиваем количество для горизонтального списка
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<Book> allFetchedBooks = snapshot.data?.results ?? [];
          final List<Book> recommendedBooks = allFetchedBooks
              .where((b) => b.id != book.id)
              .toList();

          if (snapshot.hasError || recommendedBooks.isEmpty) {
            return const Center(
              child: Text(
                'Нет рекомендаций в этой категории.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recommendedBooks.length,
            itemBuilder: (context, index) {
              final recommendedBook = recommendedBooks[index];
              return InkWell(
                onTap: () {
                  // [ИСПРАВЛЕНИЕ: Переход на страницу деталей рекомендуемой книги]
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Заменяем текущий экран новым, чтобы стек навигации был чистым
                      builder: (context) =>
                          BookDetailScreen(book: recommendedBook),
                    ),
                  );
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 150,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            recommendedBook.thumbnailUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.book,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        recommendedBook.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        recommendedBook.author.name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: secondaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
