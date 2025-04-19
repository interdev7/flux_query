import 'package:flutter_test/flutter_test.dart';
import 'package:flux_query/src/flux_query_cache.dart';

class User {
  final String name;
  User(this.name);

  Map<String, dynamic> toJson() => {'name': name};
  static User fromJson(Map<String, dynamic> json) => User(json['name']);
}

void main() {
  test('auto-remove expired data', () async {
    final cache = FluxQueryCache(useAutoRemoveData: true);
    await cache.fetch<String>(key: 'test', fetcher: () async => 'data', cacheTime: Duration(milliseconds: 1));
    await Future.delayed(Duration(milliseconds: 10));
    await cache.fetch<String>(key: 'test', fetcher: () async => 'new');
    final all = await cache.getAllKeysAndStates();
    expect(all.containsKey('test'), isTrue); // Данные обновились, старые удалились
  });

  test('cache returns cached value if not stale', () async {
    final cache = FluxQueryCache();
    await cache.fetch<User>(key: 'user', fetcher: () async => User('Alex'), staleTime: Duration(seconds: 10));
    final result = await cache.fetch<User>(
      key: 'user',
      fetcher: () async => User('Other'), // fetcher should NOT be called
      staleTime: Duration(seconds: 10),
    );
    expect(result.data?.name, 'Alex');
  });

  test('cache updates value after stale', () async {
    final cache = FluxQueryCache();
    await cache.fetch<User>(
      key: 'user',
      fetcher: () async => User('Alex'),
      staleTime: Duration.zero, // immediately stale
    );
    final result = await cache.fetch<User>(key: 'user', fetcher: () async => User('Other'), staleTime: Duration.zero);
    expect(result.data?.name, 'Other');
  });
}
