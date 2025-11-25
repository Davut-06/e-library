class BookFilterModel {
  // --- ПОЛЯ (Не изменены) ---
  final List<int> genreIds;
  final int? authorId;
  final int? subjectId;
  final String? languageId;
  final String? type;
  final int? yearStart;
  final int? yearEnd;
  final String? search;
  final int? categoryId;
  final String? categorySlug;
  final int? excludeId;
  final int? page;
  final int? limit;
  final int? offset;

  const BookFilterModel({
    this.genreIds = const [],
    this.authorId,
    this.subjectId,
    this.languageId,
    this.type,
    this.yearStart,
    this.yearEnd,
    this.search,
    this.categoryId,
    this.categorySlug,
    this.excludeId,
    this.page,
    this.limit,
    this.offset,
  });

  /// 🛠️ Создает копию модели с возможностью замены только нужных полей.
  BookFilterModel copyWith({
    List<int>? genreIds,
    int? authorId,
    int? subjectId,
    String? languageId,
    String? type,
    int? yearStart,
    int? yearEnd,
    String? search,
    int? categoryId,
    String? categorySlug,
    int? excludeId,
    int? page,
    int? limit,
    int? offset,
  }) {
    return BookFilterModel(
      genreIds: genreIds ?? this.genreIds,
      authorId: authorId ?? this.authorId,
      subjectId: subjectId ?? this.subjectId,
      languageId: languageId ?? this.languageId,
      type: type ?? this.type,
      yearStart: yearStart ?? this.yearStart,
      yearEnd: yearEnd ?? this.yearEnd,
      search: search ?? this.search,
      categoryId: categoryId ?? this.categoryId,
      categorySlug: categorySlug ?? this.categorySlug,
      excludeId: excludeId ?? this.excludeId,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  // ******************************************************
  // ✅ ИСПРАВЛЕНИЕ: Добавлен именованный параметр 'ignoreSearch'
  // ******************************************************
  /// Проверяет, активен ли какой-либо фильтр, кроме пагинации.
  /// Если [ignoreSearch] true, то поле 'search' игнорируется.
  bool isFilterActive({bool ignoreSearch = false}) {
    // Логика проверки всех фильтров, кроме пагинации
    final bool otherFiltersActive =
        genreIds.isNotEmpty ||
        authorId != null ||
        subjectId != null ||
        languageId?.isNotEmpty == true ||
        type?.isNotEmpty == true ||
        yearStart != null ||
        yearEnd != null ||
        categoryId != null ||
        categorySlug?.isNotEmpty == true;

    if (ignoreSearch) {
      return otherFiltersActive;
    } else {
      // Учитываем и текстовый поиск, и другие фильтры
      return (search?.isNotEmpty == true) || otherFiltersActive;
    }
  }

  /// Преобразует модель фильтра в Map, готовый для передачи в Dio
  /// как queryParameters.
  Map<String, dynamic> toQueryParams() {
    final Map<String, dynamic> params = {};
    if (offset != null) {
      params['offset'] = offset.toString();
    }

    // --- 1. ПАГИНАЦИЯ ---
    if (page != null) {
      params['page'] = page!.toString();
    }
    if (limit != null) {
      params['limit'] = limit!.toString();
    }

    // --- 2. ПОИСК И ИСКЛЮЧЕНИЯ ---
    if (search?.isNotEmpty == true) {
      params['search'] = search;
    }
    if (excludeId != null) {
      params['exclude_id'] = excludeId!.toString();
    }

    // --- 3. КАТЕГОРИИ и ЖАНРЫ ---
    // Категория (ID)
    if (categoryId != null) {
      params['category_id'] = categoryId!.toString();
    }
    // Категория (Slug)
    if (categorySlug?.isNotEmpty == true) {
      params['category__slug'] = categorySlug;
    }
    // Жанры
    if (genreIds.isNotEmpty) {
      params['genre'] = genreIds.join(',');
    }

    // --- 4. НОВЫЕ ФИЛЬТРЫ ---
    // Автор и Предмет
    if (authorId != null) {
      params['author'] = authorId!.toString();
    }
    if (subjectId != null) {
      params['subject'] = subjectId!.toString();
    }

    // Язык
    if (languageId?.isNotEmpty == true) {
      params['language'] = languageId;
    }

    // --- 5. АТРИБУТЫ КНИГИ ---
    if (type?.isNotEmpty == true) {
      params['type'] = type;
    }
    if (yearStart != null) {
      params['year_from'] = yearStart!.toString();
    }
    if (yearEnd != null) {
      params['year_to'] = yearEnd!.toString();
    }

    // Очищаем от null-значений, которые Dio не должен обрабатывать
    params.removeWhere((k, v) => v == null);

    return params;
  }
}
