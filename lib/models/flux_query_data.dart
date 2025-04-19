import '../types/flux_query_state.dart';

/// QueryData is a class that encapsulates query information and results.
/// It provides a way to track the state of a query and access its result.
class FluxQueryData<T> {
  /// The unique key for this query
  final String key;

  /// The current state of the query
  final FluxQueryState<T> state;

  /// The function used to refetch the query data
  final Future<void> Function() refetch;

  /// Creates a new QueryData instance
  FluxQueryData({required this.key, required this.state, required this.refetch});

  /// Create a copy of this data with the given fields replaced
  FluxQueryData<T> copyWith({String? key, FluxQueryState<T>? state, Future<void> Function()? refetch}) {
    return FluxQueryData<T>(key: key ?? this.key, state: state ?? this.state, refetch: refetch ?? this.refetch);
  }

  /// Access the data from the state
  T? get data => state.data;

  /// Access the error from the state
  Object? get error => state.error;

  /// Check if the query is loading
  bool get isLoading => state.isLoading;

  /// Check if the data is stale
  bool get isStale => state.isStale;

  /// Check if the query has data
  bool get hasData => state.hasData;

  /// Check if the query has encountered an error
  bool get hasError => state.hasError;
}
