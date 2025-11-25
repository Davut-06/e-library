import 'package:flutter/material.dart';
// import '../library/filter_screen.dart'; // ❌ УДАЛЕНО
import 'package:e_library/design/colors.dart';
// import '../../models/book_filter_model.dart'; // ❌ УДАЛЕНО

class LibrarySearchBar extends StatefulWidget {
  final void Function(String query) onSearch;
  final TextEditingController? controller;

  // ✅ НОВЫЙ ОБЯЗАТЕЛЬНЫЙ ПАРАМЕТР
  final VoidCallback onFilterPressed;

  // ❌ УДАЛЕНЫ СТАРЫЕ ПОЛЯ:
  // final BookFilterModel currentFilter;
  // final void Function(BookFilterModel newFilter) onFilterApplied;

  const LibrarySearchBar({
    super.key,
    required this.onSearch,
    this.controller,
    required this.onFilterPressed, // ✅ ДОБАВЛЕН
    // ❌ УДАЛЕНЫ
    // required this.currentFilter,
    // required this.onFilterApplied,
  });

  @override
  State<LibrarySearchBar> createState() => _LibrarySearchBarState();
}

class _LibrarySearchBarState extends State<LibrarySearchBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = widget.controller ?? TextEditingController();
    _searchController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onTextChanged);
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
          // ✅ ИСПРАВЛЕНИЕ: Вызываем переданный callback
          onPressed: widget.onFilterPressed,

          // ⚠️ Если 'assets/icons/filter.jpg' не работает, замените на Icon(Icons.filter_list)
          icon: Image.asset('assets/icons/filter.jpg', width: 40, height: 40),
        ),
      ],
    );
  }
}
