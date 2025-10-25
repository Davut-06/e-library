import 'package:e_library/design/colors.dart';
import 'package:flutter/material.dart';
import 'section_books_screen.dart';
import '../../widgets/section_header.dart';
import 'book_list.dart';
import 'search_bar.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  void navigateToSection(BuildContext context, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SectionBooksScreen(sectionTitle: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Library',
          style: TextStyle(
            color: secondaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            const SizedBox(height: 10),

            // 🔍 Search bar + filter button
            const LibrarySearchBar(),

            const SizedBox(height: 20),

            // 📚 Section: Popular
            SectionHeader(
              title: 'Popular',
              onTap: () => navigateToSection(context, 'Popular'),
            ),
            const BookList(),

            SectionHeader(
              title: 'New',
              onTap: () => navigateToSection(context, 'New'),
            ),
            const BookList(),

            SectionHeader(
              title: 'Stories',
              onTap: () => navigateToSection(context, 'Stories'),
            ),
            const BookList(),
          ],
        ),
      ),
    );
  }
}
