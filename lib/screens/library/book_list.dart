import 'package:e_library/design/colors.dart';
import 'package:e_library/models/book_models.dart';
import 'package:e_library/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../widgets/book_card.dart';

class BookList extends StatefulWidget {
  const BookList({super.key, required String sectionTitle});

  @override
  State<BookList> createState() => _BookListState();
}

class _BookListState extends State<BookList> {
  // Переменная для хранения Future, которое будет загружать книги

  late Future<List<Book>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _booksFuture = ApiService().fetchBooks();
  }

  @override
  Widget build(BuildContext context) {
    const double listHeight = 220;

    return SizedBox(
      height: listHeight,
      child: FutureBuilder<List<Book>>(
        future: _booksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SpinKitFadingCircle(color: secondaryColor, size: 30.0),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ошибка загрузки: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Нет доступных книг в этом разделе.'),
            );
          }

          final List<Book> books = snapshot.data!;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(width: 90, child: BookCard(book: books[index])),
              );
            },
          );
        },
      ),
    );
  }
}
