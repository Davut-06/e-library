import 'package:e_library/design/colors.dart';
import 'package:flutter/material.dart';
// ! Убедитесь, что вы импортируете вашу модель фильтра
import '../../models/book_filter_model.dart';
//import 'package:e_library/models/book_filter_model.dart';

// Определим возможные типы для радио-кнопок
enum BookType { book, ebook, magazine, newspaper }

class FilterScreen extends StatefulWidget {
  // 1. Принимаем текущий фильтр в конструктор
  final BookFilterModel initialFilter;

  // Тип возвращаемого значения: BookFilterModel
  const FilterScreen({super.key, required this.initialFilter});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  // State для Жанров (список, который будет содержать выбранные жанры)
  final List<String> _selectedGenres = [];

  // Controllers для полей года
  late final TextEditingController _yearFromController;
  late final TextEditingController _yearToController;

  // State для Типа (только один тип может быть выбран)
  BookType? _selectedType;

  @override
  void initState() {
    super.initState();
    // Инициализация из переданной модели
    _selectedGenres.addAll(widget.initialFilter.genres);
    _selectedType = _getTypeFromString(widget.initialFilter.type);

    // Инициализация контроллеров года
    _yearFromController = TextEditingController(
      text: widget.initialFilter.yearFrom?.toString() ?? '',
    );
    _yearToController = TextEditingController(
      text: widget.initialFilter.yearTo?.toString() ?? '',
    );
  }

  // Вспомогательный метод для преобразования String в Enum
  BookType? _getTypeFromString(String? type) {
    if (type == null) return null;
    try {
      return BookType.values.firstWhere(
        (e) => e.toString().split('.').last == type.toLowerCase(),
      );
    } catch (e) {
      return null; // Если тип не найден
    }
  }

  // Вспомогательный метод для преобразования Enum обратно в String для API
  String? _getStringFromType(BookType? type) {
    if (type == null) return null;
    return type.toString().split('.').last;
  }

  // Метод для сброса фильтров
  void _resetFilters() {
    setState(() {
      _selectedGenres.clear();
      _yearFromController.clear();
      _yearToController.clear();
      _selectedType = null;
    });
  }

  // Метод для применения фильтров и возврата модели
  void _applyFilters() {
    // Парсим года, очищая поля от лишних пробелов, если они есть
    final int? yearFrom = int.tryParse(_yearFromController.text.trim());
    final int? yearTo = int.tryParse(_yearToController.text.trim());

    // Создаем новую модель
    final newFilter = BookFilterModel(
      genres: List.from(_selectedGenres),
      yearFrom: yearFrom,
      yearTo: yearTo,
      type: _getStringFromType(_selectedType),
    );

    // Возвращаем модель на предыдущий экран
    Navigator.pop(context, newFilter);
  }

  @override
  void dispose() {
    _yearFromController.dispose();
    _yearToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Filter',
          selectionColor: secondaryColor,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // 1. Секция GENRE
                const Text(
                  'Genre',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: secondaryColor,
                  ),
                ),
                _buildCheckboxTile('Romance'),
                _buildCheckboxTile('Horror'),
                _buildCheckboxTile('Action'),
                _buildCheckboxTile('Detective'),
                const SizedBox(height: 20),

                // 2. Секция YEAR
                const Text(
                  'Year',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: secondaryColor,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _yearFromController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'From',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: searchColor),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '—',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: TextField(
                        controller: _yearToController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'To',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                            borderSide: BorderSide(color: searchColor),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. Секция TYPE
                const Text(
                  'Type',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: secondaryColor,
                  ),
                ),
                _buildRadioTile(BookType.book, 'Book'),
                _buildRadioTile(BookType.ebook, 'E-book'),
                _buildRadioTile(BookType.magazine, 'Magazine'),
                _buildRadioTile(BookType.newspaper, 'Newspaper'),
              ],
            ),
          ),

          // 4. Кнопки
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile(String title) {
    const Color activeColor = Color(0xFF5D87FF);
    const Color inactiveBorderColor = Color(0xFFC8D7F1);
    final bool isChecked = _selectedGenres.contains(title);

    return CheckboxListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: secondaryColor,
          fontWeight: FontWeight.w400,
        ),
      ),
      value: isChecked,
      onChanged: (val) {
        setState(() {
          if (val == true) {
            _selectedGenres.add(title);
          } else {
            _selectedGenres.remove(title);
          }
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
      fillColor: WidgetStateProperty.resolveWith<Color>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.selected)) return activeColor;
        return Colors.transparent;
      }),
      checkboxShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: isChecked ? activeColor : inactiveBorderColor,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
    );
  }

  Widget _buildRadioTile(BookType value, String title) {
    return RadioListTile<BookType>(
      title: Text(
        title,
        style: const TextStyle(
          color: secondaryColor,
          fontWeight: FontWeight.w400,
        ),
      ),
      value: value,
      groupValue: _selectedType,
      onChanged: (BookType? val) {
        setState(() {
          _selectedType = val;
        });
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      activeColor: const Color(0xFF5D87FF),
    );
  }
}
