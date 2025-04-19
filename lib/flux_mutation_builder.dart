import 'package:flutter/widgets.dart';

import 'types/flux_mutation_callbacks.dart';

/// A function that executes a mutation with variables
typedef MutationFunction<TData, TVariables> = Future<TData> Function(TVariables variables);

/// A function that builds a widget based on the mutation state
typedef MutationWidgetBuilder<TData, TVariables> = Widget Function(BuildContext context, MutationState<TData, TVariables> state);

/// The state of a mutation
class MutationState<TData, TVariables> {
  /// Whether the mutation is currently running
  final bool isLoading;

  /// The data returned by the mutation
  final TData? data;

  /// The error encountered during the mutation
  final Object? error;

  /// The function that executes the mutation
  final MutationFunction<TData, TVariables> mutate;

  /// Creates a new MutationState
  MutationState({this.isLoading = false, this.data, this.error, required this.mutate});

  /// Whether the mutation has data
  bool get hasData => data != null;

  /// Whether the mutation has encountered an error
  bool get hasError => error != null;
}

/// MutationBuilder is a widget that provides a mutation function
/// and builds a widget based on the mutation state.
class MutationBuilder<TData, TVariables> extends StatefulWidget {
  /// The function that performs the mutation
  final Future<TData> Function(TVariables variables) mutationFn;

  /// The function that builds the widget based on the mutation state
  final MutationWidgetBuilder<TData, TVariables> builder;

  /// Callbacks for success, error, and settled events
  final MutationCallbacks<TData, TVariables>? callbacks;

  /// Creates a new MutationBuilder
  const MutationBuilder({super.key, required this.mutationFn, required this.builder, this.callbacks});

  @override
  State<MutationBuilder<TData, TVariables>> createState() => _MutationBuilderState<TData, TVariables>();
}

class _MutationBuilderState<TData, TVariables> extends State<MutationBuilder<TData, TVariables>> {
  bool _isLoading = false;
  TData? _data;
  Object? _error;

  Future<TData> _mutate(TVariables variables) async {
    if (_isLoading) {
      throw Exception('Mutation is already in progress');
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await widget.mutationFn(variables);

      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }

      // Call success callback if provided
      widget.callbacks?.onSuccess?.call(data, variables);

      // Call settled callback if provided
      widget.callbacks?.onSettled?.call(data, null, variables);

      return data;
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      }

      // Call error callback if provided
      widget.callbacks?.onError?.call(error, variables);

      // Call settled callback if provided
      widget.callbacks?.onSettled?.call(null, error, variables);

      throw error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, MutationState<TData, TVariables>(isLoading: _isLoading, data: _data, error: _error, mutate: _mutate));
  }
}
