import 'package:e_library/design/colors.dart';
import 'package:flutter/material.dart';
import '../models/book_models.dart'; // Импортируем нашу модель Book

class BookCard extends StatelessWidget {
  final Book book; // Теперь карточка принимает полный объект Book

  const BookCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Использование Image.network для загрузки обложки по URL
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            book.thumbnailUrl, // URL обложки из модели
            height: 150,
            width: double
                .infinity, // Занимаем всю доступную ширину ячейки GridView
            fit: BoxFit.cover,

            // Лоадер во время загрузки изображения (показываем круговой индикатор)
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

            // Фоллбэк (заглушка), если изображение не найдено/не загрузилось
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 150,
                color: Colors.red.withOpacity(0.1),
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.red, size: 40),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // 2. Отображение названия книги
        Text(
          book.title, // Название книги
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: secondaryVariantColor,
            fontSize: 14,
          ),
        ),

        // 3. Отображение имени автора из вложенного объекта
        Text(
          book.author.name,
          style: const TextStyle(fontSize: 13, color: primaryColor),
        ),
      ],
    );
  }
}
