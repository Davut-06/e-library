import 'package:e_library/design/colors.dart';
import 'package:flutter/material.dart';
import '../models/book_models.dart';
import '../screens/BookDetailScreen.dart';

class BookCard extends StatelessWidget {
  final Book book;

  const BookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final bool hasThumbnail = book.thumbnailUrl.isNotEmpty;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: hasThumbnail
                ? Image.network(
                    book.thumbnailUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 150,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: Colors.red.withOpacity(0.1),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(
                        Icons.menu_book,
                        color: secondaryVariantColor,
                        size: 32,
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 8),

          // 2. Отображение названия книги
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: secondaryVariantColor,
              fontSize: 14,
            ),
          ),

          // 3. Отображение имени автора
          Text(
            book.author.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: primaryColor),
          ),
        ],
      ),
    );
  }
}
