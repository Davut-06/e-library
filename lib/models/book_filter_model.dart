/// lib/models/book_filter_model.dart

class BookFilterModel {
  final List<String> genres;
  final int? yearFrom;
  final int? yearTo;
  final String? type;
  final String? authorName;
  final String? search;
  final int? categoryId;
  final String? categorySlug;
  final int? excludeId; // 💡 ID книги для исключения из списка
  final int? page; // 💡 Номер страницы для пагинации
  final int? limit; // 💡 НОВОЕ: Максимальное количество элементов на странице

  BookFilterModel({
    this.genres = const [],
    this.yearFrom,
    this.yearTo,
    this.type,
    this.authorName,
    this.search,
    this.categoryId,
    this.categorySlug,
    this.excludeId,
    this.page,
    this.limit, // 💡 Добавляем в конструктор
  });

  /// Преобразует модель фильтра в Map, готовый для передачи в Dio
  /// как queryParameters.
  Map<String, dynamic> toQueryParams() {
    final Map<String, dynamic> params = {};

    // --- 1. ПАГИНАЦИЯ И СМЕЩЕНИЕ ---
    if (page != null) {
      params['page'] = page.toString();
    }
    if (limit != null) {
      // Это позволяет переопределить лимит по умолчанию (например, 20)
      params['limit'] = limit.toString();
    }

    // --- 2. ПОИСК И ИСКЛЮЧЕНИЯ ---
    if (search != null && search!.isNotEmpty) {
      params['search'] = search;
    }
    if (excludeId != null) {
      // 👈 Предполагаем, что API использует 'exclude_id'
      params['exclude_id'] = excludeId.toString();
    }

    // --- 3. КАТЕГОРИИ ---
    if (categoryId != null) {
      params['category'] = categoryId.toString();
    }
    if (categorySlug != null && categorySlug!.isNotEmpty) {
      // 👈 Предполагаем, что API использует 'category__slug'
      params['category__slug'] = categorySlug;
    }
    if (genres.isNotEmpty) {
      // Жанры объединяются через запятую
      params['genre'] = genres.join(',');
    }

    // --- 4. АТРИБУТЫ КНИГИ ---
    if (authorName != null && authorName!.isNotEmpty) {
      params['author'] = authorName;
    }
    if (type != null && type!.isNotEmpty) {
      params['type'] = type;
    }
    if (yearFrom != null) {
      params['year_from'] = yearFrom!.toString();
    }
    if (yearTo != null) {
      params['year_to'] = yearTo!.toString();
    }

    return params;
  }
}
