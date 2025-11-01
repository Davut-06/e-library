import 'package:e_library/design/colors.dart';
import 'package:flutter/material.dart';
import 'section_books_screen.dart';
import '../../widgets/section_header.dart';
import 'book_list.dart';
import 'search_bar.dart';
import 'package:e_library/screens/library/filter_screen.dart';

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
    const popularTitle = 'Popular';
    const newTitle = 'New';
    const storiesTitle = 'Strories';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: iconColor,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        titleSpacing: 8.0,
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

            // Search bar + filter button
            const LibrarySearchBar(),

            const SizedBox(height: 20),

            // 📚 Section: Popular
            SectionHeader(
              title: popularTitle,
              onTap: () => navigateToSection(context, popularTitle),
            ),
            const BookList(sectionTitle: popularTitle),
            const SizedBox(height: 20),

            SectionHeader(
              title: newTitle,
              onTap: () => navigateToSection(context, newTitle),
            ),
            const BookList(sectionTitle: newTitle),
            const SizedBox(height: 20),

            SectionHeader(
              title: storiesTitle,
              onTap: () => navigateToSection(context, storiesTitle),
            ),
            const BookList(sectionTitle: storiesTitle),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
