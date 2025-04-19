// ignore_for_file: unnecessary_type_check

import 'package:flux_query/flux_query_client.dart';
import 'package:flux_query/src/flux_query_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluxQueryCache', () {
    late FluxQueryCache cache;

    setUp(() {
      cache = FluxQueryCache();
    });

    test('fetch stores and returns data', () async {
      final result = await cache.fetch<String>(key: 'test', fetcher: () async => 'hello', staleTime: Duration(seconds: 1), cacheTime: Duration(seconds: 2));
      expect(result.data, 'hello');
      expect(result.isStale, false);
    });

    test('invalidate marks data as stale', () async {
      await cache.fetch<String>(key: 'test', fetcher: () async => 'hello');
      final stream = cache.watch<String>('test');
      expectLater(stream, emits(predicate((result) => result is dynamic && (result as dynamic).isStale == true)));
      await cache.invalidate<String>('test');
    });
  });

  group('FluxQueryClient', () {
    late FluxQueryClient client;

    setUp(() {
      client = FluxQueryClient();
    });

    test('query returns data', () async {
      final result = await client.query<String>(key: 'test', fetcher: () async => 'world');
      expect(result.data, 'world');
      expect(result.isStale, false);
    });

    test('invalidateQuery marks data as stale', () async {
      await client.query<String>(key: 'test', fetcher: () async => 'world');
      final stream = client.watchQuery<String>('test');
      expectLater(stream, emits(predicate((state) => state is dynamic && (state as dynamic).isStale == true)));
      await client.invalidateQuery<String>('test');
    });
  });
}
