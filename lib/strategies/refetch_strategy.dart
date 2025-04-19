/// RefetchStrategy defines different strategies for refetching stale data.
enum RefetchStrategy {
  /// Always fetch fresh data, ignoring cached data
  alwaysFetch,

  /// Show stale data immediately while refetching in background
  staleWhileRevalidate,

  /// Show stale data and don't automatically refetch
  staleOnly,

  /// Only fetch if no data exists
  fetchIfEmpty,

  /// Never refetch, always use cached data
  cacheOnly,
}

/// Extension methods for RefetchStrategy
extension RefetchStrategyExtension on RefetchStrategy {
  /// Whether this strategy requires an immediate fetch
  bool get requiresImmediateFetch {
    return this == RefetchStrategy.alwaysFetch;
  }

  /// Whether this strategy allows displaying stale data
  bool get allowsStaleData {
    return this == RefetchStrategy.staleWhileRevalidate || this == RefetchStrategy.staleOnly || this == RefetchStrategy.cacheOnly;
  }

  /// Whether this strategy triggers background revalidation
  bool get triggersBackgroundRevalidation {
    return this == RefetchStrategy.staleWhileRevalidate;
  }
}
