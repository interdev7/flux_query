import 'dart:developer' as developer;

import '../flux_query_client.dart';
import '../src/flux_query_result.dart';
import '../types/flux_query_state.dart';
import '../src/flux_query_cache.dart';

/// A class representing a log entry for FluxQueryClient
class FluxQueryLogEntry {
  /// The timestamp of the log entry
  final DateTime timestamp;

  /// The message of the log entry
  final String message;

  /// The level of the log entry
  final LogLevel level;
  FluxQueryLogEntry(this.timestamp, this.message, this.level);
}

class FluxQueryLoggerMemory {
  static final FluxQueryLoggerMemory _instance = FluxQueryLoggerMemory._internal();
  factory FluxQueryLoggerMemory() => _instance;
  FluxQueryLoggerMemory._internal();

  final int maxEntries = 100;
  final List<FluxQueryLogEntry> _logs = [];

  List<FluxQueryLogEntry> get logs => List.unmodifiable(_logs);

  void add(LogLevel level, String message) {
    _logs.add(FluxQueryLogEntry(DateTime.now(), message, level));
    if (_logs.length > maxEntries) {
      _logs.removeAt(0);
    }
  }

  void clear() => _logs.clear();
}

/// Extension methods for FluxQueryClient that add logging functionality
extension FluxQueryLoggerExtension on FluxQueryClient {
  /// Log all query operations to the console
  FluxQueryClient withLogging({bool logQueries = true, bool logInvalidations = true, bool logErrors = true, LogLevel minLevel = LogLevel.info}) {
    // Create a proxy logger that wraps the original methods
    return _LoggingQueryClient(this, logQueries: logQueries, logInvalidations: logInvalidations, logErrors: logErrors, minLevel: minLevel);
  }
}

/// A wrapper around FluxQueryClient that adds logging functionality
class _LoggingQueryClient implements FluxQueryClient {
  final FluxQueryClient _client;
  final bool _logQueries;
  final bool _logInvalidations;
  final bool _logErrors;
  final LogLevel _minLevel;

  _LoggingQueryClient(this._client, {required bool logQueries, required bool logInvalidations, required bool logErrors, required LogLevel minLevel})
    : _logQueries = logQueries,
      _logInvalidations = logInvalidations,
      _logErrors = logErrors,
      _minLevel = minLevel;

  @override
  FluxQueryCache get cache => _client.cache;

  @override
  void setDefaultRefetchStrategy(dynamic strategy) {
    _client.setDefaultRefetchStrategy(strategy);
  }

  @override
  Future<FluxQueryResult<T>> query<T>({required String key, required Future<T> Function() fetcher, Duration? staleTime, Duration? cacheTime, dynamic refetchStrategy}) async {
    if (_logQueries) {
      _log(LogLevel.info, 'Executing query: $key');
    }

    try {
      final result = await _client.query<T>(key: key, fetcher: fetcher, staleTime: staleTime, cacheTime: cacheTime, refetchStrategy: refetchStrategy);

      if (_logQueries) {
        if (result.hasError && _logErrors) {
          _log(LogLevel.error, 'Query error for $key: ${result.error}');
        } else {
          _log(LogLevel.info, 'Query completed for $key${result.isStale ? ' (stale)' : ''}');
        }
      }

      return result;
    } catch (e) {
      if (_logQueries && _logErrors) {
        _log(LogLevel.error, 'Query exception for $key: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> invalidateQuery<T>(String key) async {
    if (_logInvalidations) {
      _log(LogLevel.info, 'Invalidating query: $key');
    }
    return _client.invalidateQuery<T>(key);
  }

  @override
  Stream<FluxQueryState<T>> watchQuery<T>(String key) {
    if (_logQueries) {
      _log(LogLevel.info, 'Watching query: $key');
    }
    return _client.watchQuery<T>(key);
  }

  @override
  void dispose() {
    _log(LogLevel.info, 'Disposing query client');
    _client.dispose();
  }

  /// Log a message with the given level
  void _log(LogLevel level, String message) {
    if (level.value <= _minLevel.value) {
      final now = DateTime.now();
      final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      developer.log('[$timeString] FlutterQuery: $message', name: 'FlutterQuery', level: level.value);
      FluxQueryLoggerMemory().add(level, message);
    }
  }
}

/// Log levels used by the query logger
enum LogLevel {
  /// Detailed debugging information
  debug(800),

  /// General information messages
  info(500),

  /// Warning messages
  warning(300),

  /// Error messages
  error(200);

  /// The numeric value of this log level
  final int value;

  /// Creates a new LogLevel with the given value
  const LogLevel(this.value);
}
