import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
// ! Убедитесь, что эти импорты верны в вашем проекте
import '../models/book_models.dart';
import '../models/book_filter_model.dart';
import 'package:path_provider/path_provider.dart';

class ApiService {
  // Базовая URL, которую вы предоставили
  static const String _baseUrl = 'http://192.168.100.202/api';
  static const String _booksEndpoint = '/books/';
  static const String _pdfDownloadEndpoint = '/books/';

  final Dio _dio = Dio();

  /// 🌐 Метод для получения всех книг с учетом пагинации и фильтра.
  ///
  /// @param initialQueryParams: Карта параметров фильтра, полученная из BookFilterModel.
  Future<List<Book>> fetchAllBooks({
    Map<String, dynamic>? initialQueryParams,
  }) async {
    List<Book> allBooks = [];

    // 1. Формируем URL для первого запроса, включая параметры фильтра.
    String? nextUrl = Uri.parse(
      '$_baseUrl$_booksEndpoint',
    ).replace(queryParameters: initialQueryParams).toString();

    try {
      // Цикл продолжается, пока есть URL для следующей страницы
      while (nextUrl != null) {
        print('Fetching books from URL: $nextUrl');

        final Response response = await _dio.get(nextUrl!);

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = response.data;
          final responseModel = BookListResponse.fromJson(jsonResponse);

          // Добавляем полученные книги в общий список
          allBooks.addAll(responseModel.results);

          // Обновляем nextUrl для следующей итерации (может быть null)
          nextUrl = responseModel.next;
        } else {
          throw Exception(
            'Error loading page from server: ${response.statusCode}',
          );
        }
      }
    } on DioException catch (e) {
      print('Dio Error during batch fetch: ${e.message}');
      throw Exception('Network error during batch fetch: ${e.message}');
    }

    return allBooks;
  }

  // ! ВНИМАНИЕ: Ваш предыдущий метод fetchBooks() удален,
  // ! так как fetchAllBooks() теперь полностью поддерживает и пагинацию, и фильтр.

  /// ⬇️ Метод для скачивания PDF
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
