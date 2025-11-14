import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/book_models.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class BookApi {
  static const String _baseUrl = 'https://api.yourlibrary.com/api/v1';
  final Dio _dio;

  // Конструктор
  BookApi(this._dio);

  /// 🌐 Получает список книг с пагинацией
  /// @param page: Номер страницы для загрузки (по умолчанию 1)
  Future<BookListResponse> fetchBooks({int page = 1}) async {
    final String url = '$_baseUrl/books/?page=$page';

    try {
      // 1. Выполняем GET-запрос
      final Response response = await _dio.get(url);

      if (response.statusCode == 200) {
        // Dio автоматически декодирует JSON в Map<String, dynamic> или List<dynamic>
        final Map<String, dynamic> data = response.data;

        // 2. Преобразуем Map в нашу модель BookListResponse
        return BookListResponse.fromJson(data);
      } else {
        // Обрабатываем HTTP-ошибки (4xx, 5xx)
        throw Exception(
          'Failed to load books. Status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      // Обрабатываем ошибки Dio (сеть, таймаут и т.д.)
      print('Dio Error fetching books: ${e.message}');
      throw Exception('Network error or API call failed: ${e.message}');
    }
  }

  /// 🔎 Получает одну книгу по ее ID
  Future<Book> fetchBookDetails(int bookId) async {
    final String url = '$_baseUrl/books/$bookId/';

    try {
      final Response response = await _dio.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return Book.fromJson(data);
      } else {
        throw Exception(
          'Failed to load book $bookId details. Status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('Dio Error fetching book details: ${e.message}');
      throw Exception('Network error fetching book details: ${e.message}');
    }
  }

  // 📥 НОВЫЙ МЕТОД: Скачивает PDF-файл по ID книги
  Future<File> downloadPdfFile(String bookId) async {
    // Формируем URL: https://api.yourlibrary.com/api/v1/books/{bookId}/pdf
    final String apiUrl = '$_baseUrl/books/$bookId/pdf';

    // Определяем путь для временного сохранения файла
    final dir = await getTemporaryDirectory();
    final String savePath = '${dir.path}/$bookId.pdf';

    try {
      await _dio.download(
        apiUrl,
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
      print("Ошибка Dio при загрузке PDF: ${e.message}");
      throw Exception(
        'Не удалось загрузить книгу. Статус: ${e.response?.statusCode ?? 'No response'}',
      );
    }
  }
}
