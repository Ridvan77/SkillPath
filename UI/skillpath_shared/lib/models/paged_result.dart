/// Generic container for paginated API responses.
///
/// The API returns paginated data in the shape:
/// ```json
/// {
///   "items": [...],
///   "page": 1,
///   "pageSize": 10,
///   "totalCount": 42,
///   "totalPages": 5,
///   "hasNextPage": true,
///   "hasPreviousPage": false
/// }
/// ```
class PagedResult<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PagedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  /// Creates a [PagedResult] from a JSON map.
  ///
  /// [fromJsonT] is a function that converts each item in the `items` array
  /// from a `Map<String, dynamic>` to an instance of [T].
  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PagedResult<T>(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => fromJsonT(e as Map<String, dynamic>))
              .toList() ??
          [],
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      totalCount: json['totalCount'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      hasNextPage: json['hasNextPage'] as bool? ?? false,
      hasPreviousPage: json['hasPreviousPage'] as bool? ?? false,
    );
  }

  /// Returns an empty [PagedResult] with no items.
  factory PagedResult.empty() {
    return PagedResult<T>(
      items: [],
      page: 1,
      pageSize: 10,
      totalCount: 0,
      totalPages: 0,
      hasNextPage: false,
      hasPreviousPage: false,
    );
  }
}
