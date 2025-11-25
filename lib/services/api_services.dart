import 'dart:io';
import 'package:dio/dio.dart';
// ! Убедитесь, что эти импорты верны в вашем проекте
import '../models/book_models.dart';
import '../models/book_filter_model.dart';
import 'package:path_provider/path_provider.dart';

// ❌ УДАЛЕН КЛАСС FilterOption
// 🔑 ЕСЛИ FilterOption ИСПОЛЬЗУЕТСЯ ВНУТРИ ApiService, ОН ДОЛЖЕН БЫТЬ ОПРЕДЕЛЕН
//    В book_models.dart ИЛИ ИМПОРТИРОВАН ИЗ ДРУГОГО МЕСТА.
//    Предполагается, что Author, BookCategory и BookListResponse
//    уже импортированы из book_models.dart.

class ApiService {
  // Базовая URL, которую вы предоставили
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.100.202/api',
  );
  static const String _booksEndpoint = '/books/';
  static const String _pdfDownloadEndpoint = '/books/';
  static const String _categoriesEndpoint = '/books/categories/';
  // ✅ НОВЫЕ ЭНДПОИНТЫ ДЛЯ ФИЛЬТРОВ
  static const String _authorsEndpoint = '/books/authors/';
  static const String _genresEndpoint = '/books/genres/';
  static const String _subjectsEndpoint = '/books/subjects/'; // Предполагаемый

  final Dio _dio;

  ApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );

  Dio get dio => _dio;

  // --- НОВЫЕ МЕТОДЫ ДЛЯ ЗАГРУЗКИ СПИСКОВ ФИЛЬТРОВ ---
  // 🔑 ПРИМЕЧАНИЕ: Этот метод требует, чтобы FilterOption был определен и импортирован.
  Future<List<FilterOption>> _fetchFilterList(String endpoint) async {
    final String url = _baseUrl + endpoint;
    try {
      final Response response = await _dio.get(url);
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> jsonList = response.data;
        // ❌ ВНИМАНИЕ: FilterOption должен быть импортирован из book_models.dart
        return jsonList
            .map((json) => FilterOption.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Failed to load filter list from $endpoint: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('Dio Error fetching filter list from $endpoint: ${e.message}');
      throw Exception(
        'Network error fetching filter list from $endpoint: ${e.message}',
      );
    }
  }

  Future<List<FilterOption>> fetchAuthors() =>
      _fetchFilterList(_authorsEndpoint);
  Future<List<FilterOption>> fetchGenres() => _fetchFilterList(_genresEndpoint);
  Future<List<FilterOption>> fetchSubjects() =>
      _fetchFilterList(_subjectsEndpoint);

  // --- МЕТОД ЗАГРУЗКИ КНИГ С ПАГИНАЦИЕЙ И ФИЛЬТРОМ ---

  /// 🌐 Метод для получения страницы книг с учетом пагинации и фильтра.
  Future<BookListResponse> fetchBooksPage({
    required BookFilterModel filter,
  }) async {
    // 1. Используем BookFilterModel для формирования параметров
    final Map<String, dynamic> params = filter.toQueryParams();

    // 2. Создаем URL, заменяя существующие queryParameters
    final String url = Uri.parse(_baseUrl + _booksEndpoint)
        .replace(
          queryParameters: params.map((k, v) => MapEntry(k, v.toString())),
        )
        .toString();

    try {
      print('Fetching page from URL: $url');
      final Response response = await _dio.get(url);

      if (response.statusCode == 200) {
        return BookListResponse.fromJson(response.data);
      } else {
        throw Exception('Error loading page: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('Dio Error during page fetch: ${e.message}');
      throw Exception('Network error during page fetch: ${e.message}');
    }
  }

  Future<List<BookCategory>> fetchAllCategories() async {
    final String url = _baseUrl + _categoriesEndpoint;
    try {
      final Response response = await _dio.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = response.data;
        return jsonList
            .map((json) => BookCategory.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('Dio Error fetching categories: ${e.message}');
      throw Exception('Network error fetching categories: ${e.message}');
    }
  }

  // --- ИСПРАВЛЕННЫЙ МЕТОД ЗАГРУЗКИ ВСЕХ КНИГ ---

  /// 📚 Метод для загрузки ВСЕХ книг с помощью пагинации 'nextUrl'.
  /// ✅ ИСПРАВЛЕНО: Убедился, что здесь НЕТ вызова fetchBooksPage.
  Future<List<Book>> fetchAllBooks({
    Map<String, dynamic>? initialQueryParams,
  }) async {
    List<Book> allBooks = [];
    String? nextUrl = Uri.parse(
      '$_baseUrl$_booksEndpoint',
    ).replace(queryParameters: initialQueryParams).toString();
    try {
      while (nextUrl != null) {
        print('Fetching books from URL: $nextUrl');
        // NOTE: Используем nextUrl напрямую, а не _baseUrl
        final Response response = await _dio.get(nextUrl!);
        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonResponse = response.data;
          final responseModel = BookListResponse.fromJson(jsonResponse);
          allBooks.addAll(responseModel.results);
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

  /// ⬇️ Метод для скачивания PDF
  Future<File> downloadPdfFile(String bookId) async {
    final String apiUrl = '$_baseUrl$_pdfDownloadEndpoint$bookId/pdf';
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
