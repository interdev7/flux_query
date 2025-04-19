// This file provides integration with the Riverpod state management library.
// Note: To use this integration, you need to add the 'flutter_riverpod' package to your dependencies.

/// A provider for the FluxQueryClient
///
/// Example usage:
/// ```dart
/// // Define a provider for your FluxQueryClient
/// final queryClientProvider = Provider<FluxQueryClient>((ref) {
///   final client = FluxQueryClient();
///
///   // Dispose the client when the provider is disposed
///   ref.onDispose(() {
///     client.dispose();
///   });
///
///   return client;
/// });
///
/// // Use the client in your widgets
/// final Widget build(BuildContext context, WidgetRef ref) {
///   final client = ref.watch(queryClientProvider);
///   // ...
/// }
/// ```
///
/// This is a placeholder file to show the intended API.
/// For a full implementation, you would need to add the following imports:
/// ```dart
/// import 'package:flutter_riverpod/flutter_riverpod.dart';
/// import '../query_client.dart';
/// ```
class RiverpodIntegration {
  // This class is intentionally empty. It serves as a placeholder for
  // documentation and to provide a clear API for Riverpod integration.
}
