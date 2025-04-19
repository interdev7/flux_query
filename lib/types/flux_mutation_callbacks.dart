/// Callback for when a mutation is successful
typedef OnMutationSuccess<TData, TVariables> = void Function(
  TData data,
  TVariables variables,
);

/// Callback for when a mutation encounters an error
typedef OnMutationError<TVariables> = void Function(
  Object error,
  TVariables variables,
);

/// Callback for when a mutation is settled (either success or error)
typedef OnMutationSettled<TData, TVariables> = void Function(
  TData? data,
  Object? error,
  TVariables variables,
);

/// A set of callbacks for a mutation
class MutationCallbacks<TData, TVariables> {
  /// Called when the mutation is successful
  final OnMutationSuccess<TData, TVariables>? onSuccess;

  /// Called when the mutation encounters an error
  final OnMutationError<TVariables>? onError;

  /// Called when the mutation is settled (either success or error)
  final OnMutationSettled<TData, TVariables>? onSettled;

  /// Creates a new set of mutation callbacks
  MutationCallbacks({
    this.onSuccess,
    this.onError,
    this.onSettled,
  });
}
