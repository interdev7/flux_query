import 'dart:async';

import 'src/flux_query_cache.dart';
import 'src/flux_query_result.dart';
import 'strategies/refetch_strategy.dart';
import 'types/flux_query_state.dart';

/// FluxQueryClient is the central class that manages all queries and mutations.
/// It provides methods to create, execute, and manage queries and mutations.
class FluxQueryClient {
  /// The cache instance used by this client
  final FluxQueryCache cache;

  /// Default strategy for refetching queries
  RefetchStrategy _defaultRefetchStrategy = RefetchStrategy.staleWhileRevalidate;

  /// Stream controllers for active queries
  final _queryControllers = <String, StreamController<FluxQueryState>>{};

  /// Create a new FluxQueryClient with an optional cache instance
  FluxQueryClient({FluxQueryCache? cache}) : cache = cache ?? FluxQueryCache();

  /// Set the default refetch strategy for all queries
  void setDefaultRefetchStrategy(RefetchStrategy strategy) {
    _defaultRefetchStrategy = strategy;
  }

  /// Execute a query with the given key and fetcher
  /// Returns a Future that resolves to the query result
  Future<FluxQueryResult<T>> query<T>({required String key, required Future<T> Function() fetcher, Duration? staleTime, Duration? cacheTime, RefetchStrategy? refetchStrategy}) async {
    final strategy = refetchStrategy ?? _defaultRefetchStrategy;

    // Get current state
    final currentState = FluxQueryState<T>(key: key, isLoading: true);

    _emitState(key, currentState);

    try {
      final result = await cache.fetch<T>(key: key, fetcher: fetcher, staleTime: staleTime, cacheTime: cacheTime);

      final newState = FluxQueryState<T>(key: key, data: result.data, error: result.error, isLoading: false, isStale: result.isStale);

      _emitState(key, newState);

      // Handle refetch according to strategy
      if (result.isStale && strategy == RefetchStrategy.staleWhileRevalidate) {
        // Schedule a background fetch
        _refetchInBackground(key, fetcher, staleTime, cacheTime);
      }

      return result;
    } catch (error) {
      final errorState = FluxQueryState<T>(key: key, error: error, isLoading: false);

      _emitState(key, errorState);
      return FluxQueryResult<T>(error: error);
    }
  }

  /// Refetch data in the background
  Future<void> _refetchInBackground<T>(String key, Future<T> Function() fetcher, Duration? staleTime, Duration? cacheTime) async {
    try {
      await cache.fetch<T>(key: key, fetcher: fetcher, staleTime: staleTime, cacheTime: cacheTime);
    } catch (_) {
      // Errors are already handled in the QueryResult
    }
  }

  /// Invalidate a query by key
  Future<void> invalidateQuery<T>(String key) async {
    await cache.invalidate<T>(key);
  }

  /// Get a stream of query states for a specific key
  Stream<FluxQueryState<T>> watchQuery<T>(String key) {
    if (!_queryControllers.containsKey(key)) {
      _queryControllers[key] = StreamController<FluxQueryState<T>>.broadcast();

      // Subscribe to cache changes
      cache.watch<T>(key).listen((result) {
        final state = FluxQueryState<T>(key: key, data: result.data, error: result.error, isLoading: false, isStale: result.isStale);

        _emitState(key, state);
      });
    }

    return _queryControllers[key]!.stream as Stream<FluxQueryState<T>>;
  }

  /// Emit a new state for a query
  void _emitState<T>(String key, FluxQueryState<T> state) {
    if (_queryControllers.containsKey(key) && !_queryControllers[key]!.isClosed) {
      _queryControllers[key]!.add(state);
    }
  }

  /// Dispose the client and all associated resources
  void dispose() {
    for (final controller in _queryControllers.values) {
      controller.close();
    }
    _queryControllers.clear();
    cache.dispose();
  }
}
