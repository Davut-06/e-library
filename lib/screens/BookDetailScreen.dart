import 'package:e_library/design/colors.dart';
import 'package:e_library/models/book_models.dart';
import 'package:e_library/services/api_services.dart';
import 'package:flutter/material.dart';
import '../screens/pdf_reader_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/book_filter_model.dart';
import '../screens/library/section_books_screen.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;
  final ApiService _apiService;

  BookDetailScreen({super.key, required this.book})
    : _apiService = ApiService();

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool _isLoading = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  void _launchFile(BuildContext context) async {
    final String? url = widget.book.fileUrl?.trim();
    if (url == null || url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Файл для чтения онлайн недоступен.')),
        );
      }
      return;
    }
    setState(() {
      _isLoading = true;
    });

    final bool isPdf = url.toLowerCase().endsWith('.pdf');
    if (isPdf) {
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PdfReaderScreen(pdfUrl: url, bookTitle: widget.book.title),
          ),
        );
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    final Uri? uri = Uri.tryParse(url);
    // final bool canLaunch = await canLaunchUrl(uri!);
    if (uri != null) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось открыть ссылку: $url')),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // import 'package:permission_handler/permission_handler.dart'; // Добавить импорт

  void _downloadBook(BuildContext context) async {
    final String? url = widget.book.fileUrl?.trim();
    if (url == null || url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Файл для скачивания недоступен.')),
        );
      }
      return;
    }

    // Запрос разрешения на хранение (Критично для Android)
    if (await Permission.storage.request().isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Разрешение на хранение не предоставлено.'),
          ),
        );
      }
      return;
    }

    try {
      // ⚠️ ИСПОЛЬЗУЕМ getDownloadsDirectory()
      final Directory? directory = await getDownloadsDirectory();

      if (directory == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось найти каталог для загрузок.'),
            ),
          );
        }
        return;
      }

      String fileName =
          "${widget.book.title.replaceAll(' ', '_')}_${widget.book.id}.pdf";
      // Устанавливаем путь в папку Downloads
      String savePath = '${directory.path}/$fileName';

      // Проверка существования файла
      if (await File(savePath).exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Книга уже скачана: $savePath')),
          );
        }
        return;
      }

      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
      });

      // 3. Загрузка файла
      await widget._apiService.dio.download(
        url,
        savePath, // <-- Теперь это папка Downloads
        onReceiveProgress: (received, total) {
          // ... (логика прогресса)
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Книга успешно скачана в папку "Загрузки"! (Путь: $savePath)',
            ),
          ),
        );
      }
    } on DioException catch (e) {
      // ... (Обработка ошибок)
    } catch (e) {
      // ... (Обработка ошибок)
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
                _buildHeaderSection(context, widget.book),
                const SizedBox(height: 20),
                Text(
                  widget.book.description,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: secondaryColor,
                  ),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 30),
                _buildRecommendationsTitle(context),
                const SizedBox(height: 15),
                _buildRecommendationsListWidget(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        if (_isLoading)
          const Opacity(
            opacity: 0.6,
            child: ModalBarrier(dismissible: false, color: Colors.black),
          ),
        if (_isLoading)
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: activeColor),
                SizedBox(height: 16),
                Text(
                  'Ожидайте, идет загрузка книги...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHeaderSection(BuildContext context, Book book) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          height: 187,
          decoration: BoxDecoration(color: Colors.grey[200]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              book.thumbnailUrl,
              height: 220,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
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
              // Исправлено: Language ID на LanguageID для соответствия предыдущей реализации
              _buildMetadataRow('LanguageID', book.language.toString()),
              _buildMetadataRow('ViewCount', book.viewCount.toString()),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isDownloading
                          ? null
                          : () => _downloadBook(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                      ),
                      child: _isDownloading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                value: _downloadProgress > 0.0
                                    ? _downloadProgress
                                    : null,
                                strokeWidth: 3,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  backgroundColor,
                                ),
                              ),
                            )
                          : const Text(
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

  Widget _buildRecommendationsTitle(BuildContext context) {
    final filter = BookFilterModel(
      categoryId: widget.book.category.id,
      excludeId: widget.book.id,
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SectionBooksScreen(
                  sectionTitle: 'Recommendations: ${widget.book.category.name}',
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

  Widget _buildRecommendationsListWidget(BuildContext context) {
    final filter = BookFilterModel(
      categoryId: widget.book.category.id,
      excludeId: widget.book.id,
    );
    return SizedBox(
      height: 250,
      child: FutureBuilder<dynamic>(
        future: widget._apiService.fetchBooksPage(
          initialQueryParams: filter.toQueryParams(),
          limit: 10,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<Book> allFetchedBooks = snapshot.data?.results ?? [];
          final List<Book> recommendedBooks = allFetchedBooks
              .where((b) => b.id != widget.book.id)
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
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            itemCount: recommendedBooks.length,
            itemBuilder: (context, index) {
              final recommendedBook = recommendedBooks[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
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
                          color: secondaryVariantColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        recommendedBook.author.name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: primaryColor,
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
