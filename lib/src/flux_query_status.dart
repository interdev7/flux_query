/// A simple enum to represent the status of a query.
enum FluxQueryStatus {
  /// The query is idle and has not been executed yet.
  idle,

  /// The query is currently being executed.
  loading,

  /// The query has been executed successfully.
  success,

  /// The query has failed with an error.
  error,
}
