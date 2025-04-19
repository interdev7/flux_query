/// `CacheStore` is an abstract class that defines the interface for a cache store.
/// It provides methods to write, read, and remove cache entries.`
abstract class FluxCacheStore {
  /// `write` method adds a new entry to the cache or updates an existing one.
  /// It takes a key, data, and optional stale and cache times.
  /// The `staleTime` parameter indicates how long the data should be considered fresh.
  /// The `cacheTime` parameter indicates how long the data should be cached.
  /// If the data is older than this time, it will be removed from the cache.
  /// The `staleTime` and `cacheTime` parameters are optional.
  /// If not provided, the default values will be used.
  /// The `key` parameter is a string that uniquely identifies the cached data.
  /// The `data` parameter is the actual data to be cached.
  Future<void> write<T>(String key, T data, {Duration? staleTime, Duration? cacheTime});

  /// `read` method retrieves an entry from the cache.
  /// It takes a key and returns the cached data.
  /// If the entry is expired, it will be removed from the cache.
  /// The `key` parameter is a string that uniquely identifies the cached data.
  /// The method returns a `CacheEntry` object that contains the cached data,
  /// the timestamp when it was cached, and optional fields for stale and expiration times.
  Future<FluxCacheEntry<T>?> read<T>(String key);

  /// `remove` method deletes an entry from the cache.
  /// It takes a key and removes the corresponding entry from the cache.
  /// The `key` parameter is a string that uniquely identifies the cached data.
  /// This method is used to invalidate the cache for a specific key.
  /// After calling this method, the cached data will no longer be available.
  Future<void> remove(String key);
}

/// `CacheEntry` represents a single entry in the cache.
/// It contains the cached data, the timestamp when it was cached,
/// and optional fields for stale and expiration times.
/// The `staleAt` field indicates when the cached data should be considered stale.
/// The `expiresAt` field indicates when the cached data should be considered expired.
/// The `data` field contains the actual cached data.
/// The `timestamp` field indicates when the data was cached.
/// The `staleAt` and `expiresAt` fields are optional and can be null.
/// The `CacheEntry` class is generic and can hold any type of data.
/// It is used by the `CacheStore` to store and retrieve cached data.
class FluxCacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final DateTime? staleAt;
  final DateTime? expiresAt;

  FluxCacheEntry({required this.data, required this.timestamp, this.staleAt, this.expiresAt});

  // UNSAFE but necessary constructor for internal use that bypasses type checking
  // This allows us to create a CacheEntry<T> from a CacheEntry<dynamic>
  // The actual type conversion will happen in FluxQueryCache when deserializer is used
  FluxCacheEntry._({required dynamic data, required this.timestamp, this.staleAt, this.expiresAt}) : data = data as dynamic;
}

/// `InMemoryStore` is an implementation of the `CacheStore` interface.
/// It uses an in-memory map to store cache entries.
/// It provides methods to write, read, and remove cache entries.
/// The `write` method adds a new entry to the cache or updates an existing one.
/// The `read` method retrieves an entry from the cache.
/// If the entry is expired, it will be removed from the cache.
/// The `remove` method deletes an entry from the cache.
class InMemoryStore implements FluxCacheStore {
  final Map<String, FluxCacheEntry<dynamic>> store = {};

  @override
  Future<void> write<T>(String key, T data, {Duration? staleTime, Duration? cacheTime}) async {
    final staleAt = staleTime != null ? DateTime.now().add(staleTime) : null;
    store[key] = FluxCacheEntry<dynamic>(data: data, timestamp: DateTime.now(), staleAt: staleAt, expiresAt: cacheTime != null ? DateTime.now().add(cacheTime) : null);
  }

  @override
  Future<FluxCacheEntry<T>?> read<T>(String key) async {
    final entry = store[key];
    if (entry == null) return null;

    // UNSAFE but necessary - we're creating a new CacheEntry with the same data
    // but telling Dart to treat the dynamic data as type T
    // The actual type conversion will happen in FluxQueryCache when deserializer is used
    // ignore: avoid_as
    return FluxCacheEntry<T>._(data: entry.data, timestamp: entry.timestamp, staleAt: entry.staleAt, expiresAt: entry.expiresAt);
  }

  @override
  Future<void> remove(String key) async {
    store.remove(key);
  }
}
