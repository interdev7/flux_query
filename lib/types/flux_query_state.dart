/// QueryState represents the current state of a query.
/// It includes data, error, loading state, and staleness information.
class FluxQueryState<T> {
  /// The unique key for this query
  final String key;

  /// The data returned by the query
  final T? data;

  /// Any error that occurred during the query
  final Object? error;

  /// Whether the query is currently loading
  final bool isLoading;

  /// Whether the data is considered stale
  final bool isStale;

  /// Creates a new QueryState instance
  FluxQueryState({required this.key, this.data, this.error, this.isLoading = false, this.isStale = false});

  /// Whether the query has data
  bool get hasData => data != null;

  /// Whether the query has encountered an error
  bool get hasError => error != null;

  /// Create a copy of this state with the given fields replaced
  FluxQueryState<T> copyWith({String? key, T? data, Object? error, bool? isLoading, bool? isStale}) {
    return FluxQueryState<T>(key: key ?? this.key, data: data ?? this.data, error: error ?? this.error, isLoading: isLoading ?? this.isLoading, isStale: isStale ?? this.isStale);
  }
}
