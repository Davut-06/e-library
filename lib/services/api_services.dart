import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../models/book_models.dart';
import 'package:path_provider/path_provider.dart';

class ApiService {
  static const String _baseUrl = 'http://192.168.100.202/api';
  static const String _booksEndpoint = '/books/';
  // Используется для формирования URL скачивания: /api/books/{bookId}/pdf
  static const String _pdfDownloadEndpoint = '/books/';

  final Dio _dio = Dio();

  // 1. Метод для получения списка книг (ваш существующий код)
  Future<List<Book>> fetchBooks() async {
    final String url = '$_baseUrl$_booksEndpoint';
    // ... (логика fetchBooks опущена для краткости) ...
    try {
      final Response response = await _dio.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = response.data;
        final responseModel = BookListResponse.fromJson(jsonResponse);
        return responseModel.results;
      } else {
        throw Exception(
          'Error loading books from server: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  // 2. Метод для скачивания PDF (Новый, добавленный)
  Future<File> downloadPdfFile(String bookId) async {
    // Формируем URL для скачивания
    final String apiUrl = '$_baseUrl$_pdfDownloadEndpoint$bookId/pdf';

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
      // Возвращаем локально сохраненный файл
      return File(savePath);
    } on DioException catch (e) {
      print("Ошибка Dio при загрузке PDF: ${e.message}");
      throw Exception(
        'Не удалось загрузить книгу. Статус: ${e.response?.statusCode ?? 'No response'}',
      );
    }
  }
}
