# Flux Query

[![Pub Version](https://img.shields.io/pub/v/flux_query.svg)](https://pub.dev/packages/flux_query)
[![License](https://img.shields.io/github/license/interdev7/flux_query)](https://github.com/interdev7/flux_query/blob/main/LICENSE)
[![Build](https://img.shields.io/github/actions/workflow/status/interdev7/flux_query/build.yml)](https://github.com/interdev7/flux_query/actions)
[![Stars](https://img.shields.io/github/stars/interdev7/flux_query?style=social)](https://github.com/interdev7/flux_query)

A powerful and flexible library for caching data in Flutter applications with minimal overhead.

## Key Advantages

### 🚀 Performance

- **Instant UI:** returns cached data while fetching new data
- **Efficient network traffic:** automatically eliminates redundant requests
- **Minimal overhead:** lightweight architecture without heavy dependencies
- **Fast cache reactions:** uses optimized streams to instantly propagate cache changes to UI

### 🧩 Ease of Use

- **Intuitive API:** familiar API inspired by React Query and SWR
- **Minimal boilerplate:** just a few lines of code for a complete caching solution
- **Predictable data lifecycle:** clear rules for managing data staleness and updates

### 💪 Flexibility

- **Support for various data types:** works with any data — from primitives to complex models
- **Custom staleness time:** flexible configuration for when data is considered stale
- **Various caching strategies:** customizable cache time-to-live (TTL)
- **Optional automatic cleanup:** removal of expired data to optimize memory usage

### 🛠️ Advanced Features

- **Automatic polling:** periodically update data in the background
- **Built-in DevTools:** visual cache inspector for debugging and development
- **Change subscription mechanism:** reactive UI updates via Stream API
- **Optimistic updates:** instant UI response before network requests complete

### 🔋 Reliability

- **Error handling out of the box:** built-in recovery mechanism for failures
- **Return stale data on errors:** always something to display to the user
- **Customizable offline policy:** data access without network connectivity

## Quick Start

```dart
// 1. Create a FluxQueryClient
final client = FluxQueryClient();

// 2. Wrap your app in FluxQueryProvider
FluxQueryProvider(
  client: client,
  child: MyApp(),
)

// 3. Use in widgets
FluxQueryBuilder<User>(
  queryKey: 'user-profile',
  queryFn: () => fetchUserProfile(),
  builder: (context, query) {
    if (query.state.isLoading) return CircularProgressIndicator();
    return Text(query.state.data?.name ?? 'No data');
  },
)
```

## Additional Features

### Polling

```dart
FluxQueryBuilder<LiveData>(
  queryKey: 'live-updates',
  queryFn: () => fetchLiveData(),
  pollInterval: Duration(seconds: 30), // Automatic refetch every 30 seconds
  builder: (context, query) => LiveDataWidget(data: query.state.data),
)
```

### DevTools

```dart
// Activate DevTools button
FluxQueryProvider(
  client: client,
  showDevTools: true, // Adds a floating button to open DevTools
  child: MyApp(),
)

// Or call manually
showDevToolsOverlay(context, client);
```

### Automatic Memory Cleanup

```dart
// Enable automatic removal of expired data
final cache = FluxQueryCache(useAutoRemoveData: true);
final client = FluxQueryClient(cache: cache);
```

## Features

- 🧠 **Smart Caching**: Cache API responses with configurable staleness and expiration times
- 🔄 **Background Refetching**: Automatically refetch stale data while showing cached results
- 🎣 **Simple API**: Easy-to-use hooks and builders for fetching and displaying data
- 🧩 **Mutations**: First-class mutation support with optimistic updates
- 🔌 **Framework Agnostic**: Works with any state management solution
- 🧪 **Framework Integrations**: Built-in integrations for Provider, Riverpod, and Bloc

## Installation

```yaml
dependencies:
  flux_query: ^0.0.1
```

## Basic Usage

### Setup

First, add the `FluxQueryProvider` at the root of your application:

```dart
void main() {
  runApp(
    FluxQueryProvider(
      client: FluxQueryClient(),
      child: MyApp(),
    ),
  );
}
```

### Fetching Data

Use the `FluxQueryBuilder` to fetch and cache data:

```dart
FluxQueryBuilder<User>(
  queryKey: 'user-profile',
  queryFn: () => fetchUserProfile(),
  builder: (context, query) {
    if (query.isLoading) {
      return CircularProgressIndicator();
    }
    
    if (query.hasError) {
      return Text('Error: ${query.error}');
    }
    
    return UserProfileWidget(user: query.data!);
  },
)
```

### Mutations

Use the `MutationBuilder` to update data:

```dart
MutationBuilder<User, UpdateUserParams>(
  mutationFn: (params) => updateUser(params),
  builder: (context, mutation) {
    return ElevatedButton(
      onPressed: mutation.isLoading
          ? null
          : () => mutation.mutate(UpdateUserParams(name: 'New Name')),
      child: mutation.isLoading
          ? CircularProgressIndicator()
          : Text('Update Profile'),
    );
  },
)
```

## FluxQueryStore with SharedPreferences

You can use your own persistent cache store. Here is an example using SharedPreferences:

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flux_query/src/cache_store.dart';

class SharedPrefsStore implements FluxCacheStore {
  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  @override
  Future<void> write<T>(String key, T data, {Duration? staleTime, Duration? cacheTime}) async {
    final prefs = await _prefs;
    final now = DateTime.now();
    final encoded = jsonEncode({
      'data': data,
      'timestamp': now.toIso8601String(),
      'staleAt': staleTime != null ? now.add(staleTime).toIso8601String() : null,
      'expiresAt': cacheTime != null ? now.add(cacheTime).toIso8601String() : null,
    });
    await prefs.setString(key, encoded);
  }

  @override
  Future<FluxCacheEntry<T>?> read<T>(String key) async {
    final prefs = await _prefs;
    final raw = prefs.getString(key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    final now = DateTime.now();
    final expiresAt = decoded['expiresAt'] != null ? DateTime.parse(decoded['expiresAt']) : null;
    if (expiresAt != null && now.isAfter(expiresAt)) {
      await remove(key);
      return null;
    }
    return FluxCacheEntry<T>(
      data: decoded['data'],
      timestamp: DateTime.parse(decoded['timestamp']),
      staleAt: decoded['staleAt'] != null ? DateTime.parse(decoded['staleAt']) : null,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<void> remove(String key) async {
    final prefs = await _prefs;
    await prefs.remove(key);
  }
}

// Usage:
final cache = FluxQueryCache(store: SharedPrefsStore());
final client = FluxQueryClient(cache: cache);
```

## InMemoryStore (Default Cache)

By default, `FluxQueryCache` uses an in-memory cache (InMemoryStore), which is fast and suitable for most use cases where you don't need persistence between app launches.

**Usage:**

```dart
final cache = FluxQueryCache(); // Uses InMemoryStore by default
final client = FluxQueryClient(cache: cache);
```

You can also explicitly use it:

```dart
import 'package:flux_query/src/flux_cache_store.dart';

final cache = FluxQueryCache(store: InMemoryStore());
```

If you want persistence, see the SharedPreferences example below.

## FluxQueryBuilder vs MutationBuilder

**FluxQueryBuilder** and **MutationBuilder** are widgets for working with asynchronous data, but they serve different purposes:

| Feature                | FluxQueryBuilder                                 | MutationBuilder                                 |
|------------------------|----------------------------------------------|-------------------------------------------------|
| Purpose                | Fetching and caching data (GET)              | Mutating data (POST/PUT/DELETE)                 |
| State management       | Tracks loading, error, stale, data           | Tracks loading, error, data                     |
| Auto refetch           | Yes (stale-while-revalidate, polling, etc.)  | No                                              |
| Cache subscription     | Yes (reactive, updates UI on cache change)   | No (imperative, only on mutate)                 |
| Optimistic update      | No                                           | Yes (via callbacks)                             |
| Typical use            | List/profile loading, infinite scroll        | Form submit, add/remove/update item             |
| Main params            | queryKey, queryFn, builder, staleTime, ...   | mutationFn, builder, callbacks                  |
| Triggers               | On mount, on key change, on refetch          | Only when mutate() is called                    |
| Example HTTP method    | GET                                          | POST, PUT, DELETE                               |

### FluxQueryBuilder Example

```dart
FluxQueryBuilder<User>(
  queryKey: 'user-profile',
  queryFn: () => fetchUserProfile(),
  builder: (context, query) {
    if (query.isLoading) return CircularProgressIndicator();
    if (query.hasError) return Text('Error: ${query.error}');
    return UserProfileWidget(user: query.data!);
  },
)
```

### MutationBuilder Example

```dart
MutationBuilder<User, UpdateUserParams>(
  mutationFn: (params) => updateUser(params),
  builder: (context, mutation) {
    return ElevatedButton(
      onPressed: mutation.isLoading
          ? null
          : () => mutation.mutate(UpdateUserParams(name: 'New Name')),
      child: mutation.isLoading
          ? CircularProgressIndicator()
          : Text('Update Profile'),
    );
  },
)
```

### MutationBuilder with Callbacks Example

```dart
MutationBuilder<User, UpdateUserParams>(
  mutationFn: (params) => updateUser(params),
  callbacks: MutationCallbacks<User, UpdateUserParams>(
    onSuccess: (data, variables) {
      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User updated!')),
      );
    },
    onError: (error, variables) {
      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    },
    onSettled: (data, error, variables) {
      // Always called after mutation (success or error)
      print('Mutation finished');
    },
  ),
  builder: (context, mutation) {
    return ElevatedButton(
      onPressed: mutation.isLoading
          ? null
          : () => mutation.mutate(UpdateUserParams(name: 'New Name')),
      child: mutation.isLoading
          ? CircularProgressIndicator()
          : Text('Update Profile'),
    );
  },
)
```

### Optimistic Update Example

```dart
MutationBuilder<Todo, String>(
  mutationFn: (title) async {
    // Immediately update UI (optimistic)
    final client = FluxQueryProvider.of(context);
    final oldTodos = client.cache.fetch<List<Todo>>(key: 'todos', fetcher: () async => []);
    // Add optimistic todo
    client.cache.setData<List<Todo>>('todos', [...(oldTodos.data ?? []), Todo(title: title, ...)], isStale: false);
    // Simulate network call
    final newTodo = await addTodoToServer(title);
    return newTodo;
  },
  callbacks: MutationCallbacks<Todo, String>(
    onSettled: (data, error, title) {
      // Refetch todos to ensure consistency
      final client = FluxQueryProvider.of(context);
      client.invalidateQuery<List<Todo>>('todos');
    },
  ),
  builder: (context, mutation) {
    // ...
  },
)
```

### Manual Cache Update After Mutation Example

```dart
MutationBuilder<User, UpdateUserParams>(
  mutationFn: (params) => updateUser(params),
  callbacks: MutationCallbacks<User, UpdateUserParams>(
    onSuccess: (updatedUser, variables) {
      final client = FluxQueryProvider.of(context);
      // Manually update the cache for the user profile
      client.cache.setData<User>('user-profile', updatedUser, isStale: false);
    },
  ),
  builder: (context, mutation) {
    // ...
  },
)
```

#### Why not combine them into a single *Builder?

These patterns are intentionally separated, as in React Query and TanStack Query, because:

- Fetching and mutating data have fundamentally different lifecycles and UI/UX patterns.
- FluxQueryBuilder is reactive, subscribes to cache, and can auto-refetch.
- MutationBuilder is imperative, only runs on demand, and is focused on side effects and error handling.
- Combining them would make the API more confusing and less predictable for developers.

**Conclusion:**
Keep them separate for clarity, best practices, and to match the expectations of developers familiar with modern query/mutation libraries.

## Advanced Usage

### Flux Query Client Options

```dart
final client = FluxQueryClient();

// Set default refetch strategy
client.setDefaultRefetchStrategy(RefetchStrategy.staleWhileRevalidate);

// Enable logging
final loggingClient = client.withLogging(
  logQueries: true,
  logInvalidations: true,
  logErrors: true,
  minLevel: LogLevel.info,
);
```

### Flux Query Options

```dart
FluxQueryBuilder<List<Post>>(
  queryKey: 'posts',
  queryFn: () => fetchPosts(),
  // Data stays fresh for 5 minutes
  staleTime: Duration(minutes: 5),
  // Data stays in cache for 1 hour
  cacheTime: Duration(hours: 1),
  // Disabled when condition is false
  enabled: isAuthenticated,
  builder: (context, query) {
    // ...
  },
)
```

### Invalidating Queries

```dart
// Get the client from context
final client = FluxQueryProvider.of(context);

// Manually invalidate a query
await client.invalidateQuery('posts');
```

### Framework Integrations

#### Riverpod

```dart
// Define a provider
final queryClientProvider = Provider<FluxQueryClient>((ref) {
  final client = FluxQueryClient();
  ref.onDispose(() => client.dispose());
  return client;
});

// Use in your widgets
final client = ref.watch(queryClientProvider);
```

#### Bloc

```dart
class PostsBloc extends Bloc<PostsEvent, PostsState> with FluxQueryClientMixin {
  PostsBloc(this.queryClient) : super(PostsInitial()) {
    on<PostsFetchRequested>(_onPostsFetchRequested);
  }

  @override
  final FluxQueryClient queryClient;
  
  Future<void> _onPostsFetchRequested(
    PostsFetchRequested event,
    Emitter<PostsState> emit,
  ) async {
    // Use queryClient to fetch data
    // ...
  }
}
```

## Cache Store Comparison & Recommendations

You can choose different cache stores depending on your needs:

| Store Type         | Persistence | Performance | Use Case                                      | Example Implementation         |
|--------------------|-------------|-------------|-----------------------------------------------|-------------------------------|
| InMemoryStore      | ❌ No       | 🚀 Fast      | Default, testing, short-lived data, UI cache  | `FluxQueryCache()`                |
| SharedPreferences  | ✅ Yes      | 🐢 Slower    | Simple key-value, small data, app settings     | See example below             |
| Hive/Isar/SQLite   | ✅ Yes      | 🚀 Fast      | Large/complex data, offline, advanced queries  | Implement your own CacheStore |

### Recommendations

- **Use `InMemoryStore`** (default) for most UI and short-lived data. Fastest, but data is lost on app restart.
- **Use `SharedPreferences`** for small, simple, persistent key-value data (e.g., tokens, flags, small lists).
- **Use `Hive`, `Isar`, or `SQLite`** for large, complex, or structured data, or if you need advanced queries and offline support. You need to implement a custom `FluxCacheStore` for these.
- For production apps with offline/restore requirements, prefer persistent stores.
- For prototyping, demos, or ephemeral data, `InMemoryStore` is usually enough.

**Tip:** You can swap cache stores at any time by passing your own `store` to `FluxQueryCache`:

```dart
final cache = FluxQueryCache(store: MyCustomStore());
```

## Hive/Isar CacheStore Example

You can implement a persistent cache store using Hive or Isar for advanced use cases:

### Hive Example

```dart
import 'package:hive/hive.dart';
import 'package:flux_query/src/flux_cache_store.dart';

class HiveCacheStore implements FluxCacheStore {
  final Box box;
  HiveCacheStore(this.box);

  @override
  Future<void> write<T>(String key, T data, {Duration? staleTime, Duration? cacheTime}) async {
    final now = DateTime.now();
    await box.put(key, {
      'data': data,
      'timestamp': now.toIso8601String(),
      'staleAt': staleTime != null ? now.add(staleTime).toIso8601String() : null,
      'expiresAt': cacheTime != null ? now.add(cacheTime).toIso8601String() : null,
    });
  }

  @override
  Future<FluxCacheEntry<T>?> read<T>(String key) async {
    final raw = box.get(key);
    if (raw == null) return null;
    final now = DateTime.now();
    final expiresAt = raw['expiresAt'] != null ? DateTime.parse(raw['expiresAt']) : null;
    if (expiresAt != null && now.isAfter(expiresAt)) {
      await remove(key);
      return null;
    }
    return FluxCacheEntry<T>(
      data: raw['data'],
      timestamp: DateTime.parse(raw['timestamp']),
      staleAt: raw['staleAt'] != null ? DateTime.parse(raw['staleAt']) : null,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<void> remove(String key) async {
    await box.delete(key);
  }
}

// Usage:
final box = await Hive.openBox('flux_query_cache');
final cache = FluxQueryCache(store: HiveCacheStore(box));
```

### Isar Example

```dart
import 'package:isar/isar.dart';
import 'package:flux_query/src/flux_cache_store.dart';

class IsarCacheEntry {
  late String key;
  late String data;
  late String timestamp;
  String? staleAt;
  String? expiresAt;
  // Add Isar annotations as needed
}

class IsarCacheStore implements FluxCacheStore {
  final Isar isar;
  IsarCacheStore(this.isar);

  @override
  Future<void> write<T>(String key, T data, {Duration? staleTime, Duration? cacheTime}) async {
    final now = DateTime.now();
    final entry = IsarCacheEntry()
      ..key = key
      ..data = data.toString() // serialize as needed
      ..timestamp = now.toIso8601String()
      ..staleAt = staleTime != null ? now.add(staleTime).toIso8601String() : null
      ..expiresAt = cacheTime != null ? now.add(cacheTime).toIso8601String() : null;
    await isar.writeTxn(() async {
      await isar.isarCacheEntrys.put(entry);
    });
  }

  @override
  Future<FluxCacheEntry<T>?> read<T>(String key) async {
    final entry = await isar.isarCacheEntrys.getByKey(key);
    if (entry == null) return null;
    final now = DateTime.now();
    final expiresAt = entry.expiresAt != null ? DateTime.parse(entry.expiresAt!) : null;
    if (expiresAt != null && now.isAfter(expiresAt)) {
      await remove(key);
      return null;
    }
    return FluxCacheEntry<T>(
      data: entry.data as T, // deserialize as needed
      timestamp: DateTime.parse(entry.timestamp),
      staleAt: entry.staleAt != null ? DateTime.parse(entry.staleAt!) : null,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<void> remove(String key) async {
    await isar.writeTxn(() async {
      await isar.isarCacheEntrys.deleteByKey(key);
    });
  }
}

// Usage:
final isar = await Isar.open([IsarCacheEntrySchema]);
final cache = FluxQueryCache(store: IsarCacheStore(isar));
```

## Comparison with Other Libraries

| Library                   | Query/Mutation | Caching | Persistence | UI Integration | Stale-While-Revalidate | Optimistic Update | Custom Store | Notes |
|---------------------------|:-------------:|:-------:|:-----------:|:--------------:|:----------------------:|:----------------:|:------------:|-------|
| **flux_query**   | ✅            | ✅      | ✅ (custom)  | ✅ (builders)   | ✅                    | ✅               | ✅           | Inspired by React Query, flexible |
| dio_cache_interceptor     | ❌            | ✅      | ✅           | ❌              | ❌                    | ❌               | ⚠️ (custom)  | For Dio only, HTTP-level         |
| flutter_cache_manager     | ❌            | ✅      | ✅           | ❌              | ❌                    | ❌               | ❌           | For files/images only            |
| riverpod_query            | ✅            | ✅      | ❌           | ✅ (hooks)      | ✅                    | ✅               | ❌           | Riverpod only, no persistence    |
| graphql_flutter           | ✅            | ✅      | ✅           | ✅              | ✅                    | ✅               | ⚠️           | For GraphQL, not REST            |

**Summary:**

- `flux_query` is the most flexible for REST, custom stores, and UI integration.
- Use `dio_cache_interceptor` for HTTP-level caching with Dio only.
- Use `flutter_cache_manager` for file/image caching.
- Use `riverpod_query` if you are already using Riverpod and don't need persistence.
- Use `graphql_flutter` for GraphQL APIs with advanced caching.

## How Flux Query Works Under the Hood

Flux Query implements a reactive architecture without using Flutter's StreamBuilder widget, while still providing instant UI updates when cache data changes. Here's a technical look at how it works:

### Three-Layer Reactive Architecture

1. **Cache Layer (`FluxQueryCache`)**:
   - Maintains a collection of `StreamController`s for each cache key
   - The `_emit<T>` method sends updates to these streams whenever data changes
   - Creates broadcast streams allowing multiple subscribers per key
   - Handles data storage, stale/fresh states, and expiration logic

2. **Client Layer (`FluxQueryClient`)**:
   - Bridges between cache and UI with method `watchQuery<T>`
   - Subscribes to cache streams and transforms `FluxQueryResult` to `FluxQueryState`
   - Manages loading states and error handling
   - Implements refetch strategies like stale-while-revalidate

3. **UI Layer (`FluxQueryBuilder`)**:
   - Uses `StatefulWidget` instead of `StreamBuilder`
   - Subscribes to streams through `listen()` and calls `setState()` when data updates
   - Manages widget lifecycle in relation to query subscriptions

### Subscription Management Code Instead of StreamBuilder

```dart
void _setupQuery() {
  // Initialize with loading state
  _queryData ??= FluxQueryData<T>(
    key: widget.queryKey, 
    state: FluxQueryState<T>(key: widget.queryKey, isLoading: true), 
    refetch: _refetch
  );

  // Subscribe to query stream
  _client.watchQuery<T>(widget.queryKey).listen((state) {
    if (mounted) {
      setState(() {
        _queryData = FluxQueryData<T>(
          key: widget.queryKey, 
          state: state, 
          refetch: _refetch
        );
      });
    }
  });

  // Execute the query
  _executeQuery();
}
```

### Automatic Subscription Lifecycle Management

- Subscription is created when widget mounts in `didChangeDependencies()`
- Subscription updates when query key changes in `didUpdateWidget()`
- Data refetching happens through `_executeQuery()`
- `FluxQueryClient` automatically closes all streams when `dispose()` is called

### Event Propagation System

- `FluxQueryCache._emit<T>` forwards updates to all subscribers
- `FluxQueryClient._emitState<T>` transforms and forwards state to all subscribers
- All streams use `broadcast()` to support multiple listeners
- Data flows from cache to client to UI components

### Client-Cache Communication

```dart
// Inside FluxQueryClient
Stream<FluxQueryState<T>> watchQuery<T>(String key) {
  if (!_queryControllers.containsKey(key)) {
    _queryControllers[key] = StreamController<FluxQueryState<T>>.broadcast();

    // Subscribe to cache changes
    cache.watch<T>(key).listen((result) {
      final state = FluxQueryState<T>(
        key: key, 
        data: result.data, 
        error: result.error, 
        isLoading: false, 
        isStale: result.isStale
      );

      _emitState(key, state);
    });
  }

  return _queryControllers[key]!.stream as Stream<FluxQueryState<T>>;
}
```

### Cache Event Distribution

```dart
// Inside FluxQueryCache
Stream<FluxQueryResult<T>> watch<T>(String key) {
  return _controllers.putIfAbsent(
    key, 
    () => StreamController<FluxQueryResult<T>>.broadcast()
  ).stream as Stream<FluxQueryResult<T>>;
}

void _emit<T>(String key, FluxQueryResult<T> result) {
  if (_controllers.containsKey(key) && !_controllers[key]!.isClosed) {
    _controllers[key]!.add(result);
  }
}
```

### Advantages Over Direct StreamBuilder Usage

1. **Cleaner Widget Code**: No need to manually manage stream subscriptions
2. **Unified Interface**: Single interface for all data states (loading, error, stable data, stale data)
3. **Unified Error Handling**: Consistent error handling instead of multiple checks in builder
4. **Library-Level Optimizations**: Optimized update and refetch mechanisms at the library level instead of widget level
5. **Dedicated Lifecycle Management**: Proper handling of widget lifecycle in relation to streams

By abstracting stream complexity, Flux Query provides all benefits of stream reactivity without exposing the complicated stream management to developers, resulting in a simpler, less error-prone API.

## 📃 License

MIT © 2025 — Created with ❤️ by [interdev7](https://github.com/interdev7)
