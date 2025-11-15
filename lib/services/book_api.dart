import 'package:dio/dio.dart';
import '../models/book_models.dart'; // Предполагаем, что здесь находятся ваши модели
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class BookApi {
  // 🚨 ИЗМЕНЕНИЕ: Используем ваш локальный URL
  // Указываем базовый URL БЕЗ параметра пагинации (Dio добавит его)
  static const String _baseUrl = 'http://192.168.100.202/api/books/?page=2';
  final Dio _dio;

  // Константа для числа страниц
  static const int _fixedTotalPages = 11;

  BookApi(this._dio);

  // -----------------------------------------------------------------
  // НОВЫЙ МЕТОД: Загружает все книги с 1 по 11 страницу
  // -----------------------------------------------------------------
  Future<List<Book>> fetchAllBooks() async {
    List<Book> allBooks = [];

    for (int page = 1; page <= _fixedTotalPages; page++) {
      try {
        // Вызываем существующий метод для получения одной страницы
        final BookListResponse response = await fetchBooks(page: page);

        // ✅ ИСПРАВЛЕНИЕ ОШИБКИ: Используем 'results' (как в BookListResponse)
        allBooks.addAll(response.results);

        print(
          'Successfully fetched page: $page. Total books: ${allBooks.length}',
        );

        // Опционально: Если API присылает null в 'next' на последней странице,
        // можно прервать цикл раньше, если response.next == null.
        if (response.next == null && page < _fixedTotalPages) {
          print('Next page link is null. Breaking cycle early.');
          break;
        }
      } on Exception catch (e) {
        print('Error fetching page $page: $e');
        // Если произошла ошибка, прерываем цикл, чтобы не нагружать API
        break;
      }
    }

    return allBooks;
  }

  // -----------------------------------------------------------------

  /// 🌐 Получает список книг с пагинацией
  /// @param page: Номер страницы для загрузки (по умолчанию 1)
  Future<BookListResponse> fetchBooks({int page = 1}) async {
    // В Dio мы можем использовать _baseUrl, а путь оставить пустым,
    // если _baseUrl уже содержит конечную точку '/api/books/'
    final String path = '';

    try {
      final Response response = await _dio.get(
        _baseUrl +
            path, // Полный URL будет http://192.168.100.202/api/books/?page=X
        queryParameters: {'page': page},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return BookListResponse.fromJson(data);
      } else {
        throw Exception(
          'Failed to load books. Status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception('Network error or API call failed: ${e.message}');
    }
  }

  /// 🔎 Получает одну книгу по ее ID
  Future<Book> fetchBookDetails(int bookId) async {
    // Используем относительный путь от _baseUrl
    final String path = '$bookId/';

    try {
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

  // 📥 Скачивает PDF-файл по ID книги
  Future<File> downloadPdfFile(String bookId) async {
    final String path = '$bookId/pdf';
    final dir = await getTemporaryDirectory();
    final String savePath = '${dir.path}/$bookId.pdf';

    try {
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
}
