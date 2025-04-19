///
/// A class representing the result of a query.
/// It contains the data, error, and a flag indicating if the data is stale.
/// The `QueryResult` class is used to encapsulate the result of a query.
/// The `data` field contains the actual data returned by the query.
/// The `error` field contains any error that occurred during the query.
/// The `isStale` field indicates if the data is stale.
/// The `hasData` field indicates if the query returned any data.
/// The `hasError` field indicates if the query returned an error.
///
class FluxQueryResult<T> {
  ///
  /// The data returned by the query.
  /// It can be null if there was an error or if the data is stale.
  /// The `data` field is of type `T`, which can be any type.
  ///
  final T? data;

  ///
  /// The error returned by the query.
  /// It can be null if there was no error.
  ///
  final Object? error;

  ///
  /// A flag indicating if the data is stale.
  /// It is true if the data is stale and false if the data is fresh.
  ///
  final bool isStale;

  FluxQueryResult({this.data, this.error, this.isStale = false});

  ///
  /// A flag indicating if the query returned any data.
  ///
  bool get hasData => data != null;

  ///
  /// A flag indicating if the query returned an error.
  /// It is true if there was an error and false if there was no error.
  ///
  bool get hasError => error != null;
}
