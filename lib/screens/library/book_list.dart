import 'package:flutter/material.dart';
import '../../widgets/book_card.dart';
import 'package:e_library/models/book_models.dart';

class BookList extends StatelessWidget {
  const BookList({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 20,
        itemBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.only(right: 12),
            // child: BookCard()
          );
        },
      ),
    );
  }
}
