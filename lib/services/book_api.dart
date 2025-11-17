import 'package:dio/dio.dart';
import '../models/book_models.dart'; // Предполагаем, что здесь находятся ваши модели
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class BookApi {
  // Базовый URL
  static const String _baseUrl =
      'http://192.168.100.202/api/books/'; //'http://217.174.233.210:20001/api/books/';  //'http://192.168.100.202/api/books/';
  final Dio _dio;

  BookApi(this._dio);

  // -----------------------------------------------------------------
  // МЕТОД 1: НАДЕЖНАЯ ПАГИНАЦИЯ (fetchAllBooksReliably)
  // -----------------------------------------------------------------
  Future<List<Book>> fetchAllBooksReliably() async {
    List<Book> allBooks = [];
    String? nextUrl = _baseUrl; // Начинаем с базового URL (страница 1)

    while (nextUrl != null) {
      try {
        print('Fetching books from URL: $nextUrl');

        final Response response = await _dio.get(nextUrl);

        if (response.statusCode == 200) {
          final BookListResponse pageResponse = BookListResponse.fromJson(
            response.data,
          );

          allBooks.addAll(pageResponse.results);

          // Получаем ссылку на следующую страницу или null
          nextUrl = pageResponse.next;

          print(
            'Successfully loaded ${pageResponse.results.length} books. Total: ${allBooks.length}. Next: ${nextUrl == null ? "END" : "YES"}',
          );
        } else {
          print(
            'API returned non-200 status: ${response.statusCode}. Stopping pagination.',
          );
          break;
        }
      } on DioException catch (e) {
        print('🚨 Dio Error while fetching $nextUrl: ${e.message}. Stopping.');
        break;
      } catch (e) {
        print('🚨 Parsing Error: $e. Stopping pagination.');
        break;
      }
    }

    print('All books loaded. Total count: ${allBooks.length}');
    return allBooks;
  }

  // -----------------------------------------------------------------
  // МЕТОД 2: ДЕТАЛИ КНИГИ (fetchBookDetails)
  // -----------------------------------------------------------------
  /// 🔎 Получает одну книгу по ее ID
  Future<Book> fetchBookDetails(int bookId) async {
    // Используем относительный путь от _baseUrl
    final String path = '$bookId/';

    try {
      // ✅ ИСПОЛЬЗУЕМ _baseUrl + path
      final Response response = await _dio.get(_baseUrl + path);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return Book.fromJson(data);
      } else {
        throw Exception(
          'Failed to load book $bookId details. Status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception('Network error fetching book details: ${e.message}');
    }
  }

  // -----------------------------------------------------------------
  // МЕТОД 3: СКАЧИВАНИЕ PDF (downloadPdfFile)
  // -----------------------------------------------------------------
  // 📥 Скачивает PDF-файл по ID книги
  Future<File> downloadPdfFile(String bookId) async {
    final String path = '$bookId/pdf';
    final dir = await getTemporaryDirectory();
    final String savePath = '${dir.path}/$bookId.pdf';

    try {
      // ✅ ИСПОЛЬЗУЕМ _baseUrl + path
      await _dio.download(
        _baseUrl + path,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print(
              'Загрузка $bookId: ${(received / total * 100).toStringAsFixed(0)}%',
            );
          }
        },
      );
      return File(savePath);
    } on DioException catch (e) {
      throw Exception(
        'Не удалось загрузить книгу. Статус: ${e.response?.statusCode ?? 'No response'}',
      );
    }
  }
} // <-- Теперь все методы внутри этой скобки.
