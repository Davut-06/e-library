import 'package:e_library/design/colors.dart';
import 'package:flutter/material.dart';

class BookCard extends StatelessWidget {
  const BookCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/book_cover.jpg',
              height: 150,
              width: 105,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The book of art',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: secondaryVariantColor,
              fontSize: 14,
            ),
          ),
          const Text(
            'Author Name',
            style: TextStyle(fontSize: 13, color: primaryColor),
          ),
        ],
      ),
    );
  }
}
