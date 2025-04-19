import 'dart:async';

import 'flux_query_result.dart';
import 'flux_cache_store.dart';

/// A function that fetches data. It can be a synchronous or asynchronous function.
/// The function should return a [Future] that resolves to the data type [T].
/// This function is used to fetch data when the cache is stale or empty.
typedef Fetcher<T> = Future<T> Function();

/// A class that manages the caching of query results.
/// It uses a [FluxCacheStore] to store the results and provides methods to fetch,
/// invalidate, and watch the results.
/// It also provides a way to handle stale data and errors.
/// The [FluxQueryCache] class is generic and can be used with any data type [T].
/// It provides a way to fetch data, invalidate the cache, and watch for changes
/// to the data.
///
/// Example:
///
/// ```dart
/// final cache = FluxQueryCache();
/// final dio = Dio();
/// final store = DioCacheStore(dio: dio);
/// final result = await cache.fetch<String>(
///   key: 'example',
///   fetcher: () async => dio.get('https://example.com').then((response) => response.data),
///   staleTime: Duration(seconds: 10),
///   cacheTime: Duration(minutes: 5),
/// );
///
/// final stream = cache.watch<String>('example');
///
/// stream.listen((result) {
///   if (result.isStale) {
///     print('Data is stale: ${result.data}');
///   } else {
///     print('Data is fresh: ${result.data}');
///   }
/// });
/// ```
class FluxQueryCache {
  final FluxCacheStore _store;
  final _controllers = <String, StreamController<FluxQueryResult>>{};
  final bool useAutoRemoveData;

  FluxQueryCache({FluxCacheStore? store, this.useAutoRemoveData = false}) : _store = store ?? InMemoryStore();

  InMemoryStore? get _inMemoryStore => _store is InMemoryStore ? _store : null;

  void _autoRemoveExpired() {
    if (!useAutoRemoveData) return;
    final store = _inMemoryStore;
    if (store != null) {
      final now = DateTime.now();
      final keysToRemove = <String>[];
      for (final entry in store.store.entries) {
        final expiresAt = entry.value.expiresAt;
        if (expiresAt != null && now.isAfter(expiresAt)) {
          keysToRemove.add(entry.key);
        }
      }
      for (final key in keysToRemove) {
        store.store.remove(key);
      }
    }
  }

  /// Fetches data for the given key using the provided fetcher function.
  /// If the data is already in the cache and is not stale, it will return
  /// the cached data. If the data is stale or not present, it will call
  /// the fetcher function to get fresh data.
  /// The fetcher function should return a [Future] that resolves to the data type [T].
  /// The [staleTime] and [cacheTime] parameters control how long the data
  /// is considered fresh and how long it is cached, respectively.
  /// The [staleTime] parameter controls how long the data is considered fresh.
  /// If the data is older than this time, it will be considered stale.
  /// The [cacheTime] parameter controls how long the data is cached.
  /// If the data is older than this time, it will be removed from the cache.
  /// The [staleTime] and [cacheTime] parameters are optional.
  /// If not provided, the default values will be used.
  ///
  /// Example:
  /// ```dart
  /// final cache = FluxQueryCache();
  /// final result = await cache.fetch<String>(
  ///   key: 'example',
  ///   fetcher: () async => 'Hello, World!',
  ///   staleTime: Duration(seconds: 10),
  ///   cacheTime: Duration(minutes: 5),
  /// );
  /// ```
  ///
  Future<FluxQueryResult<T>> fetch<T>({required String key, required Fetcher<T> fetcher, Duration? staleTime, Duration? cacheTime}) async {
    if (useAutoRemoveData) _autoRemoveExpired();
    final entry = await _store.read<T>(key);
    final now = DateTime.now();

    final isStale = entry != null && entry.staleAt != null && now.isAfter(entry.staleAt!);
    final isExpired = entry == null;

    if (!isExpired && !isStale) {
      // Directly use data from cache
      final result = FluxQueryResult<T>(data: entry.data, isStale: false);
      _emit<T>(key, result);
      return result;
    }

    try {
      final fresh = await fetcher();
      await _store.write(key, fresh, staleTime: staleTime, cacheTime: cacheTime);
      final result = FluxQueryResult<T>(data: fresh, isStale: false);
      _emit<T>(key, result);
      return result;
    } catch (e) {
      final result = entry != null ? FluxQueryResult<T>(data: entry.data, isStale: true, error: e) : FluxQueryResult<T>(error: e);
      _emit<T>(key, result);
      return result;
    }
  }

  ///
  /// Invalidates the cache for the given key.
  /// This will remove the entry from the cache and mark it as stale.
  /// The next time the data is fetched, it will be considered stale and
  /// a new fetch will be triggered.
  ///
  /// Example:
  /// ```dart
  /// await cache.invalidate<String>('test');
  /// ```
  ///
  /// This will remove the entry for 'test' from the cache and mark it as stale.
  ///
  Future<void> invalidate<T>(String key) async {
    if (useAutoRemoveData) _autoRemoveExpired();
    await _store.remove(key);
    _emit<T>(key, FluxQueryResult<T>(isStale: true));
  }

  /// Watches the cache for changes to the given key.
  /// This will return a stream that emits the current state of the cache
  /// for the given key. The stream will emit a new value whenever the
  /// cache is updated or invalidated.
  /// The stream will emit a [FluxQueryResult] object that contains the current
  /// state of the cache for the given key.
  /// The [FluxQueryResult] object will contain the data, whether it is stale,
  /// and any error that occurred during the fetch.
  ///
  /// Example:
  /// ```dart
  /// final stream = cache.watch<String>('example');
  /// stream.listen((result) {
  ///   if (result.isStale) {
  ///     print('Data is stale: ${result.data}');
  ///   } else {
  ///     print('Data is fresh: ${result.data}');
  ///   }
  /// });
  /// ```
  ///
  Stream<FluxQueryResult<T>> watch<T>(String key) {
    return _controllers.putIfAbsent(key, () => StreamController<FluxQueryResult<T>>.broadcast()).stream as Stream<FluxQueryResult<T>>;
  }

  /// Emits a new value to the stream for the given key.
  /// This will notify all listeners of the stream about the new value.
  void _emit<T>(String key, FluxQueryResult<T> result) {
    if (_controllers.containsKey(key) && !_controllers[key]!.isClosed) {
      _controllers[key]!.add(result);
    }
  }

  /// Closes all stream controllers and clears the cache.
  /// This will remove all entries from the cache and close all streams.
  /// The streams will no longer emit any values after this method is called.
  /// This is useful for cleaning up resources when the cache is no longer needed.
  ///
  /// Example:
  ///
  /// ```dart
  /// cache.dispose();
  /// ```
  ///
  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }

  /// Returns all keys and their current states (for DevTools)
  Future<Map<String, FluxQueryResult>> getAllKeysAndStates() async {
    final result = <String, FluxQueryResult>{};
    final store = _inMemoryStore;
    if (store != null) {
      for (final entry in store.store.entries) {
        // Use dynamic data type for DevTools, since we don't know the exact type here
        // and don't have deserializers available
        result[entry.key] = FluxQueryResult(data: entry.value.data, isStale: entry.value.staleAt != null && DateTime.now().isAfter(entry.value.staleAt!));
      }
    }
    return result;
  }

  /// Public method to manually update cache for a key (for optimistic/manual updates)
  void setData<T>(String key, T data, {bool isStale = false}) {
    _emit<T>(key, FluxQueryResult<T>(data: data, isStale: isStale));
  }
}
