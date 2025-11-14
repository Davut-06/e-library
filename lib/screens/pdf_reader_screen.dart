// lib/screens/pdf_reader_screen.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';

// ⚠️ Важно: импортируйте функцию, которую мы создали на Шаге 1
import '../services/pdf_service.dart';

class PdfDownloadAndReaderScreen extends StatelessWidget {
  final String bookId;
  final String bookTitle;

  const PdfDownloadAndReaderScreen({
    Key? key,
    required this.bookId,
    this.bookTitle = 'Онлайн книга',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(bookTitle)),
      body: FutureBuilder<File>(
        // Вызываем функцию загрузки из сервисного файла
        future: downloadPdfFileWithDio(bookId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // ... (Отображение ошибки)
            return Center(
              child: Text('Ошибка загрузки: ${snapshot.error.toString()}'),
            );
          }

          if (snapshot.hasData) {
            final File pdfFile = snapshot.data!;
            // Отображаем файл после успешной загрузки
            return SfPdfViewer.file(pdfFile);
          }

          // Пока нет данных (идет загрузка)
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Загрузка книги...'),
              ],
            ),
          );
        },
      ),
    );
  }
}
