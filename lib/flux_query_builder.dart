import 'package:flutter/widgets.dart';
import 'dart:async';

import 'flux_query_client.dart';
import 'models/flux_query_data.dart';
import 'types/flux_query_state.dart';
import 'flux_query_provider.dart';

/// A function that builds a widget based on the current query state
typedef FluxQueryWidgetBuilder<T> = Widget Function(BuildContext context, FluxQueryData<T> queryData);

/// FluxQueryBuilder is a widget that executes and watches a query,
/// then builds a widget based on the query state.
class FluxQueryBuilder<T> extends StatefulWidget {
  /// The unique key for this query
  final String queryKey;

  /// The function that fetches the data
  final Future<T> Function() queryFn;

  /// The function that builds the widget based on the query state
  final FluxQueryWidgetBuilder<T> builder;

  /// Whether to refetch the data when the widget is initialized
  final bool enabled;

  /// How long the data stays fresh
  final Duration? staleTime;

  /// How long the data stays in the cache
  final Duration? cacheTime;

  /// How often to refetch data automatically (polling)
  final Duration? pollInterval;

  /// Creates a new FluxQueryBuilder
  const FluxQueryBuilder({super.key, required this.queryKey, required this.queryFn, required this.builder, this.enabled = true, this.staleTime, this.cacheTime, this.pollInterval});

  @override
  State<FluxQueryBuilder<T>> createState() => _FluxQueryBuilderState<T>();
}

class _FluxQueryBuilderState<T> extends State<FluxQueryBuilder<T>> {
  late FluxQueryClient _client;
  FluxQueryData<T>? _queryData;
  Timer? _pollTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _client = FluxQueryProvider.of(context);
    _setupQuery();
    _setupPolling();
  }

  @override
  void didUpdateWidget(FluxQueryBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.queryKey != widget.queryKey || oldWidget.enabled != widget.enabled) {
      _setupQuery();
      _setupPolling();
    }
  }

  void _setupQuery() {
    if (!widget.enabled) return;

    // Initialize with a loading state if needed
    _queryData ??= FluxQueryData<T>(key: widget.queryKey, state: FluxQueryState<T>(key: widget.queryKey, isLoading: true), refetch: _refetch);

    // Setup query stream subscription
    _client.watchQuery<T>(widget.queryKey).listen((state) {
      if (mounted) {
        setState(() {
          _queryData = FluxQueryData<T>(key: widget.queryKey, state: state, refetch: _refetch);
        });
      }
    });

    // Execute the query
    _executeQuery();
  }

  Future<void> _executeQuery() async {
    if (!widget.enabled) return;

    await _client.query<T>(key: widget.queryKey, fetcher: widget.queryFn, staleTime: widget.staleTime, cacheTime: widget.cacheTime);
  }

  Future<void> _refetch() async {
    if (!widget.enabled) return;

    await _client.invalidateQuery(widget.queryKey);
    return _executeQuery();
  }

  void _setupPolling() {
    _pollTimer?.cancel();
    if (widget.pollInterval != null && widget.enabled) {
      _pollTimer = Timer.periodic(widget.pollInterval!, (_) => _executeQuery());
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_queryData == null) {
      return const SizedBox.shrink();
    }

    return widget.builder(context, _queryData!);
  }
}
