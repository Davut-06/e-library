import 'package:flutter/material.dart';
import '../library/filter_screen.dart';
import 'package:e_library/design/colors.dart';

class LibrarySearchBar extends StatefulWidget {
  final void Function(String query) onSearch;
  final TextEditingController? controller;

  const LibrarySearchBar({super.key, required this.onSearch, this.controller});

  @override
  State<LibrarySearchBar> createState() => _LibrarySearchBarState();
}

class _LibrarySearchBarState extends State<LibrarySearchBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Слушаем изменения текста для показа/скрытия кнопки "Очистить"
    _searchController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    // Перестраивает виджет, чтобы обновить suffixIcon
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController, // 💡 Добавлен контроллер
            // 💡 Вызываем функцию поиска в LibraryScreen при изменении текста
            onChanged: widget.onSearch,

            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              hintText: 'Search',
              hintStyle: const TextStyle(
                color: Colors.grey,
                letterSpacing: 0,
                fontSize: 15,
              ),

              // 🛠️ Добавлена логика кнопки "Очистить"
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear(); // Очищаем поле
                        widget.onSearch(
                          '',
                        ); // Уведомляем родителя о пустой строке
                      },
                    )
                  : null, // Скрываем, если поле пустое

              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: searchColor, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: primaryColor,
                  width: 1.0,
                ), // Используем primaryColor
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey, width: 1.0),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FilterScreen()),
            );
          },
          // ⚠️ Если 'assets/icons/filter.jpg' не работает, замените на Icon(Icons.filter_list)
          icon: Image.asset('assets/icons/filter.jpg', width: 40, height: 40),
        ),
      ],
    );
  }
}
