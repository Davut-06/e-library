import 'package:e_library/design/colors.dart';
import 'package:flutter/material.dart';
// ! Убедитесь, что вы импортируете вашу модель фильтра и API сервис
import '../../models/book_filter_model.dart';
// Предположим, что BookCategory и FilterOption определены в book_models.dart
import '../../models/book_models.dart';
import '../../services/api_services.dart';

// Enum для типа книги остается
enum BookType { book, ebook, magazine, newspaper }

// --- ГЛАВНЫЙ ВИДЖЕТ ---

class FilterScreen extends StatefulWidget {
  final BookFilterModel initialFilter;

  const FilterScreen({super.key, required this.initialFilter});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final ApiService _apiService = ApiService();

  // Рабочая копия модели для изменений
  late BookFilterModel _currentFilter;
  // Исходная копия для сброса
  late final BookFilterModel _originalFilter;

  // --- ДАННЫЕ, ЗАГРУЖАЕМЫЕ С API ---
  List<FilterOption> _authors = [];
  List<BookCategory> _categories = [];
  List<FilterOption> _genres = [];
  List<FilterOption> _subjects = [];
  bool _isLoadingFilters = true;

  // --- СТАТИЧЕСКИЕ ДАННЫЕ (для языка) ---
  final List<FilterOption> _languages = [
    // В API могут быть коды, а не названия. Здесь пример:
    FilterOption(id: 1, name: 'Русский'),
    FilterOption(id: 2, name: 'Туркменский'),
    FilterOption(id: 3, name: 'Английский'),
  ];

  // Контроллеры для полей года
  late final TextEditingController _yearStartController;
  late final TextEditingController _yearEndController;

  @override
  void initState() {
    super.initState();

    // Инициализация моделей: copyWith гарантирует, что мы работаем с новой копией
    _currentFilter = widget.initialFilter.copyWith();
    _originalFilter = widget.initialFilter.copyWith();

    // Инициализация контроллеров года (используем yearStart/yearEnd)
    _yearStartController = TextEditingController(
      text: _currentFilter.yearStart?.toString() ?? '',
    );
    _yearEndController = TextEditingController(
      text: _currentFilter.yearEnd?.toString() ?? '',
    );

    _loadDynamicFilters();
  }

  // Метод для загрузки динамических опций фильтрации
  Future<void> _loadDynamicFilters() async {
    setState(() {
      _isLoadingFilters = true;
    });

    try {
      final results = await Future.wait([
        _apiService.fetchAuthors(),
        _apiService.fetchAllCategories(),
        _apiService.fetchGenres(),
        _apiService.fetchSubjects(),
      ]);

      setState(() {
        _authors = results[0] as List<FilterOption>;
        _categories = results[1] as List<BookCategory>;
        _genres = results[2] as List<FilterOption>;
        _subjects = results[3] as List<FilterOption>;
        _isLoadingFilters = false;
      });
    } catch (e) {
      debugPrint('Failed to load filter options: $e');
      setState(() {
        _isLoadingFilters = false;
      });
      // Можно показать ошибку пользователю
    }
  }

  // --- ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ---

  BookType? _getTypeFromString(String? type) {
    if (type == null) return null;
    try {
      return BookType.values.firstWhere(
        (e) => e.toString().split('.').last == type.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  String? _getStringFromType(BookType? type) {
    if (type == null) return null;
    return type.toString().split('.').last;
  }

  // Метод для сброса фильтров
  void _resetFilters() {
    setState(() {
      // Сброс к исходному состоянию, сохраняя базовые параметры (например, categorySlug)
      _currentFilter = BookFilterModel(
        categorySlug: _originalFilter.categorySlug,
        limit: _originalFilter.limit,
      );
      _yearStartController.clear();
      _yearEndController.clear();
      // Тип книги тоже сбрасываем
      _currentFilter = _currentFilter.copyWith(type: null);
    });
  }

  // Метод для применения фильтров и возврата модели
  void _applyFilters() {
    // 1. Обновляем модель из контроллеров
    final int? yearStart = int.tryParse(_yearStartController.text.trim());
    final int? yearEnd = int.tryParse(_yearEndController.text.trim());

    // 2. Создаем финальную модель
    final newFilter = _currentFilter.copyWith(
      yearStart: yearStart,
      yearEnd: yearEnd,
      // Остальные поля (authorId, subjectId, languageCode)
      // обновляются через setState в Dropdown виджетах.
    );

    // 3. Возвращаем модель на предыдущий экран
    Navigator.pop(context, newFilter);
  }

  @override
  void dispose() {
    _yearStartController.dispose();
    _yearEndController.dispose();
    super.dispose();
  }

  // --- ВИДЖЕТЫ ДЛЯ НОВЫХ ФИЛЬТРОВ ---

  Widget _buildDropdownFilter<T>({
    required String title,
    required List<T> items,
    required int? currentValueId,
    required Function(int? newValueId) onChanged,
    required String Function(T item) displayMapper,
  }) {
    final dropdownItems = items
        .map((item) {
          final int? id = (item is FilterOption)
              ? item.id
              : (item is BookCategory)
              ? item.id
              : null;

          if (id == null) return null;

          return DropdownMenuItem<int>(
            value: id,
            child: Text(displayMapper(item)),
          );
        })
        .where((item) => item != null)
        .toList()
        .cast<DropdownMenuItem<int>>();

    // Опция "Все"
    dropdownItems.insert(
      0,
      const DropdownMenuItem(value: null, child: Text('Все')),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: secondaryColor,
            ),
          ),
          DropdownButtonFormField<int>(
            value: currentValueId,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: searchColor),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            ),
            items: dropdownItems,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // --- ОСНОВНОЙ BUILD МЕТОД ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // ... (App Bar как у вас)
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Filter',
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
            child: _isLoadingFilters
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // 1. НОВЫЙ ФИЛЬТР: АВТОР
                      _buildDropdownFilter<FilterOption>(
                        title: 'Author',
                        items: _authors,
                        currentValueId: _currentFilter.authorId,
                        onChanged: (id) => setState(
                          () => _currentFilter = _currentFilter.copyWith(
                            authorId: id,
                          ),
                        ),
                        displayMapper: (item) => item.name,
                      ),

                      // 2. НОВЫЙ ФИЛЬТР: КАТЕГОРИЯ
                      _buildDropdownFilter<BookCategory>(
                        title: 'Category',
                        items: _categories,
                        currentValueId: _currentFilter.categoryId,
                        onChanged: (id) => setState(
                          () => _currentFilter = _currentFilter.copyWith(
                            categoryId: id,
                          ),
                        ),
                        displayMapper: (item) => item.name,
                      ),

                      // 3. НОВЫЙ ФИЛЬТР: ПРЕДМЕТ
                      _buildDropdownFilter<FilterOption>(
                        title: 'Subject',
                        items: _subjects,
                        currentValueId: _currentFilter.subjectId,
                        onChanged: (id) => setState(
                          () => _currentFilter = _currentFilter.copyWith(
                            subjectId: id,
                          ),
                        ),
                        displayMapper: (item) => item.name,
                      ),

                      // 4. НОВЫЙ ФИЛЬТР: ЯЗЫК
                      _buildDropdownFilter<FilterOption>(
                        title: 'Language',
                        items: _languages,
                        currentValueId:
                            _languages
                                    .firstWhere(
                                      (e) =>
                                          e.name == _currentFilter.languageId,
                                      orElse: () =>
                                          FilterOption(id: 0, name: ''),
                                    )
                                    .id ==
                                0
                            ? null
                            : _languages
                                  .firstWhere(
                                    (e) => e.name == _currentFilter.languageId,
                                  )
                                  .id,
                        onChanged: (id) {
                          final String? code = id != null
                              ? _languages.firstWhere((e) => e.id == id).name
                              : null;
                          setState(
                            () => _currentFilter = _currentFilter.copyWith(
                              languageId: code,
                            ),
                          );
                        },
                        displayMapper: (item) => item.name,
                      ),

                      // 5. ОБНОВЛЕННЫЙ ФИЛЬТР: ЖАНР (Используем ID, но пока оставим Checkbox для множественного выбора)
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: Text(
                          'Genre (Multi-Select)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: secondaryColor,
                          ),
                        ),
                      ),
                      // !!! ВАЖНО: Ниже используется List<String> (_selectedGenres) вместо List<int> (genreIds).
                      // Для корректной работы с API (жанры по ID) вам нужно будет переделать _buildCheckboxTile
                      // так, чтобы он работал с _currentFilter.genreIds (List<int>).
                      ..._genres
                          .map(
                            (genre) =>
                                _buildGenreCheckboxTile(genre.name, genre.id),
                          )
                          .toList(),
                      const SizedBox(height: 20),

                      // 6. Секция YEAR (Используем yearStart/yearEnd)
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
                              controller: _yearStartController,
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _yearEndController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'To',
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
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 7. Секция TYPE
                      const Text(
                        'Type',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: secondaryColor,
                        ),
                      ),
                      // Передаем тип книги из модели в RadioListTile
                      ...BookType.values.map(
                        (type) => _buildRadioTile(
                          type,
                          _getStringFromType(type) ?? 'Unknown',
                        ),
                      ),
                    ],
                  ),
          ),

          // 8. Кнопки
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

  // --- ОБНОВЛЕННЫЕ ЧЕКБОКСЫ (Жанры по ID) ---
  Widget _buildGenreCheckboxTile(String title, int id) {
    const Color activeColor = Color(0xFF5D87FF);
    const Color inactiveBorderColor = Color(0xFFC8D7F1);
    final bool isChecked = _currentFilter.genreIds.contains(id);

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
          final List<int> newGenreIds = List.from(_currentFilter.genreIds);
          if (val == true) {
            newGenreIds.add(id);
          } else {
            newGenreIds.remove(id);
          }
          // Обновляем модель
          _currentFilter = _currentFilter.copyWith(genreIds: newGenreIds);
        });
      },
      // ... (стили остаются прежними)
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

  // --- ОБНОВЛЕННЫЕ РАДИОКНОПКИ (Тип книги) ---
  Widget _buildRadioTile(BookType value, String title) {
    // Получаем текущий выбранный тип книги из модели
    final BookType? currentSelectedType = _getTypeFromString(
      _currentFilter.type,
    );

    return RadioListTile<BookType>(
      title: Text(
        title,
        style: const TextStyle(
          color: secondaryColor,
          fontWeight: FontWeight.w400,
        ),
      ),
      value: value,
      groupValue: currentSelectedType,
      onChanged: (BookType? val) {
        setState(() {
          final String? typeString = _getStringFromType(val);
          // Обновляем модель
          _currentFilter = _currentFilter.copyWith(type: typeString);
        });
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      activeColor: const Color(0xFF5D87FF),
    );
  }
}
