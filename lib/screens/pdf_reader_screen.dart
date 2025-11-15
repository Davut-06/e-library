import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'; // 👈 Импорт пакета

class PdfReaderScreen extends StatelessWidget {
  final String pdfUrl;
  final String bookTitle;

  const PdfReaderScreen({
    super.key,
    required this.pdfUrl,
    required this.bookTitle,
  });

  @override
  Widget build(BuildContext context) {
    print('Loading PDF from URL: $pdfUrl');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          bookTitle,
          // Ограничиваем длину заголовка, чтобы он поместился
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      // ✅ ИСПОЛЬЗУЕМ SfPdfViewer.network()
      body: SfPdfViewer.network(
        pdfUrl, // Передаем URL файла, который мы получили
        // Можно добавить логику загрузки, если нужно:
        // onDocumentLoadFailed: (details) {
        //   print('PDF load failed: ${details.description}');
        // },
        // initialScrollOffset: const Offset(0, 0),
      ),
    );
  }
}
