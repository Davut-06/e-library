import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/book_models.dart';

class ApiService {
  static const String _baseUrl = 'http://192.168.100.202/api';
  static const String _booksEndpoint = '/books/';

  final Dio _dio = Dio();

  Future<List<Book>> fetchBooks() async {
    final String url = '$_baseUrl$_booksEndpoint';

    try {
      final Response response = await _dio.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = response.data;

        final responseModel = BookListResponse.fromJson(jsonResponse);

        return responseModel.results;
      } else {
        print('Failed to load books. Status code: ${response.statusCode}');
        throw Exception(
          'Error loading books from server: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print(
          'Dio error: Server responded with error: ${e.response!.statusCode}',
        );
        throw Exception('Server Error: ${e.response!.statusCode}');
      } else {
        print('Dio error: Network or request setup error: $e');
        throw Exception(
          'Network error. Failed to connect to API: ${e.message}',
        );
      }
    } catch (e) {
      print('An unexpected error occurred: $e');
      throw Exception('An unknown error occurred: $e');
    }
  }
}
