import 'package:flutter/material.dart';
import '../library/filter_screen.dart';
import 'package:e_library/design/colors.dart';
import '../../models/book_filter_model.dart';

class LibrarySearchBar extends StatefulWidget {
  final void Function(String query) onSearch;
  final TextEditingController? controller;

  final BookFilterModel currentFilter;
  final void Function(BookFilterModel newFilter) onFilterApplied;

  const LibrarySearchBar({
    super.key,
    required this.onSearch,
    this.controller,
    required this.currentFilter,
    required this.onFilterApplied,
  });

  @override
  State<LibrarySearchBar> createState() => _LibrarySearchBarState();
}

class _LibrarySearchBarState extends State<LibrarySearchBar> {
  // Используем внутренний контроллер, если внешний не передан
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    // Инициализация контроллера: используем внешний, если он есть, иначе внутренний
    _searchController = widget.controller ?? TextEditingController();

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
    // Если контроллер был внутренним, его нужно утилизировать.
    if (widget.controller == null) {
      _searchController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: widget.onSearch,

            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              hintText: 'Search',
              hintStyle: const TextStyle(
                color: Colors.grey,
                letterSpacing: 0,
                fontSize: 15,
              ),

              // 🛠️ Логика кнопки "Очистить"
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        // ! ИСПРАВЛЕНО: ТОЛЬКО ОЧИЩЕНИЕ
                        _searchController.clear();
                        widget.onSearch(
                          '',
                        ); // Уведомляем родителя о пустой строке
                      },
                    )
                  : null,

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
                borderSide: const BorderSide(color: primaryColor, width: 1.0),
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
          onPressed: () async {
            // ! ИСПРАВЛЕНО: Ждем результат BookFilterModel из FilterScreen
            final BookFilterModel? newFilter =
                await Navigator.push<BookFilterModel>(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FilterScreen(initialFilter: widget.currentFilter),
                  ),
                );

            // Если результат получен, передаем его родителю
            if (newFilter != null) {
              widget.onFilterApplied(newFilter);
            }
          },
          // ⚠️ Если 'assets/icons/filter.jpg' не работает, замените на Icon(Icons.filter_list)
          icon: Image.asset('assets/icons/filter.jpg', width: 40, height: 40),
        ),
      ],
    );
  }
}
