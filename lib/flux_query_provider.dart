import 'package:flutter/material.dart';

import 'devtools/flux_query_cache_devtools.dart';
import 'flux_query_client.dart';

/// FluxQueryProvider provides a [FluxQueryClient] instance to the widget tree.
/// It should be placed at the root of your application's widget tree.
class FluxQueryProvider extends StatelessWidget {
  /// The [FluxQueryClient] instance to provide to descendants
  final FluxQueryClient client;

  /// Child widget
  final Widget child;

  /// Show DevTools-button
  final bool showDevTools;

  /// Creates a new FluxQueryProvider with the given client and child
  const FluxQueryProvider({super.key, required this.client, required this.child, this.showDevTools = false});

  /// Get the [FluxQueryClient] instance from the nearest ancestor [FluxQueryProvider]
  static FluxQueryClient of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<_QueryProviderInherited>();
    assert(provider != null, 'No FluxQueryProvider found in context');
    return provider!.client;
  }

  /// Get the [FluxQueryClient] instance without registering for rebuilds
  static FluxQueryClient? maybeOf(BuildContext context) {
    final provider = context.getElementForInheritedWidgetOfExactType<_QueryProviderInherited>()?.widget as _QueryProviderInherited?;
    return provider?.client;
  }

  @override
  Widget build(BuildContext context) {
    Widget content = _QueryProviderInherited(client: client, child: child);
    if (showDevTools) {
      content = Stack(children: [content, Positioned(right: 16, bottom: 16, child: _DevToolsFAB(client: client))]);
    }
    return content;
  }
}

class _QueryProviderInherited extends InheritedWidget {
  final FluxQueryClient client;
  const _QueryProviderInherited({required this.client, required super.child});

  @override
  bool updateShouldNotify(_QueryProviderInherited oldWidget) => client != oldWidget.client;
}

class _DevToolsFAB extends StatelessWidget {
  final FluxQueryClient client;
  const _DevToolsFAB({required this.client});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(mini: true, onPressed: () => showDevToolsOverlay(context, client), tooltip: 'Show FluxQueryCache DevTools', child: const Icon(Icons.developer_mode));
  }
}
