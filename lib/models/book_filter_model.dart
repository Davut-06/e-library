/// lib/models/book_filter_model.dart

class BookFilterModel {
  final List<String> genres;
  final int? yearFrom;
  final int? yearTo;
  final String? type;
  final String? authorName;
  final String? search;

  BookFilterModel({
    this.genres = const [],
    this.yearFrom,
    this.yearTo,
    this.type,
    this.authorName,
    this.search,
  });

  /// Преобразует модель фильтра в Map, готовый для передачи в Dio
  /// как queryParameters. Ключи должны соответствовать API (например, 'genre', 'year_from').
  Map<String, dynamic> toQueryParams() {
    final Map<String, dynamic> params = {};

    if (genres.isNotEmpty) {
      params['genre'] = genres.join(',');
    }
    if (yearFrom != null) {
      params['year_from'] = yearFrom!.toString();
    }
    if (yearTo != null) {
      params['year_to'] = yearTo!.toString();
    }
    if (type != null && type!.isNotEmpty) {
      params['type'] = type;
    }
    if (authorName != null && authorName!.isNotEmpty) {
      params['author'] = authorName;
    }
    if (search != null && search!.isNotEmpty) {
      params['search'] = search;
    }

    return params;
  }
}
