import 'package:flutter/widgets.dart';

import '../flux_query_client.dart';
import '../flux_query_provider.dart';

/// Convenience widget for creating and providing a [FluxQueryClient] instance
class FlutterQueryProvider extends StatefulWidget {
  /// The child widget
  final Widget child;

  /// Optional function to create a custom [FluxQueryClient]
  final FluxQueryClient Function()? clientBuilder;

  /// Creates a new FlutterQueryProvider
  const FlutterQueryProvider({super.key, required this.child, this.clientBuilder});

  @override
  State<FlutterQueryProvider> createState() => _FlutterQueryProviderState();
}

class _FlutterQueryProviderState extends State<FlutterQueryProvider> {
  late final FluxQueryClient _client;

  @override
  void initState() {
    super.initState();
    _client = widget.clientBuilder?.call() ?? FluxQueryClient();
  }

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FluxQueryProvider(client: _client, child: widget.child);
  }
}

/// Hooks for using queries in functional components
class FluxQueryHooks {
  /// Get the FluxQueryClient from the nearest ancestor FluxQueryProvider
  static FluxQueryClient useQueryClient(BuildContext context) {
    return FluxQueryProvider.of(context);
  }
}
