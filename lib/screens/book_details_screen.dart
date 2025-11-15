import 'package:e_library/design/colors.dart';
import 'package:e_library/models/book_models.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/pdf_reader_screen.dart';

class BookDetailScreen extends StatelessWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    // Временное описание
    const String dummyDescription =
        "Cras eget elit semper, congue sapien id, pellentesque diam. Nulla faucibus diam nec fermentum ullamcorper. Praesent sed ipsum ut augue vestibulum malesuada. Duis vitae volutpat odio. Integer sit amet elit ac justo sagittis dignissim. Vivamus quis metus in nunc semper efficitur eget vitae diam. Proin justo diam, venenatis sit amet eros in, iaculis auctor magna. Pellentesque sit amet accumsan urna, sit amet pretium ipsum. Fusce condimentum venenatis mauris et luctus. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: iconColor,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildHeaderSection(context, book),

            const SizedBox(height: 20),
            Text(
              book.description,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: secondaryColor,
              ),
              textAlign: TextAlign.justify,
            ),

            const SizedBox(height: 30),

            _buildRecommendationsHeader(),

            const SizedBox(height: 15),

            _buildRecommendationsList(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, Book book) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          height: 187,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.network(
            book.thumbnailUrl,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Название книги
              Text(
                book.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              _buildMetadataRow('Author', book.author.name),

              _buildMetadataRow('Category', book.category.name),

              _buildMetadataRow('Year', book.year.toString()),

              _buildMetadataRow('Language ID', book.language.toString()),

              _buildMetadataRow('View Count', book.viewCount.toString()),

              const SizedBox(height: 15),

              // Кнопки
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Download',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: backgroundColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Проверяем, существует ли URL файла
                        if (book.fileUrl != null) {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => PdfReaderScreen(
                          //       // Передаем URL PDF-файла в экран читалки
                          //       pdfUrl: book.fileUrl!,
                          //       bookTitle: book.title,
                          //     ),
                          //   ),
                          // );
                          launchUrl(Uri.parse(book.fileUrl!));
                        } else {
                          // Если файла нет, можно вывести сообщение или диалог
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Файл для чтения онлайн недоступен.',
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Read online',
                        style: TextStyle(
                          fontSize: 12,
                          color: backgroundColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Строка метаданных "Ключ: Значение"
  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: secondaryColor),
          children: <TextSpan>[
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: secondaryColor,
              ), // Ключ синим цветом
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  // Заголовок рекомендаций
  Widget _buildRecommendationsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recommendations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: secondaryVariantColor,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text('See all', style: TextStyle(color: primaryColor)),
        ),
      ],
    );
  }

  //recommendations

  Widget _buildRecommendationsList() {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 8,
        itemBuilder: (context, index) {
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'The book of art',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Author Name',
                  style: TextStyle(fontSize: 12, color: secondaryColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
