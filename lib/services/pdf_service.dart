import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

final Dio _dio = Dio();
const String _baseUrl = 'http://192.168.100.202/api';

Future<File> downloadPdfFileWithDio(String bookId) async {
  final String apiUrl = '$_baseUrl/v1/books/$bookId/pdf';

  final dir = await getTemporaryDirectory();
  final String savePath = '${dir.path}/$bookId.pdf';

  try {
    await _dio.download(
      apiUrl,
      savePath,
      // onReceiveProgress можно оставить для отслеживания загрузки
      onReceiveProgress: (received, total) {
        if (total != -1) {
          print('Загрузка: ${(received / total * 100).toStringAsFixed(0)}%');
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
