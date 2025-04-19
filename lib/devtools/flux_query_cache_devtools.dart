import 'package:flutter/material.dart';
import '../flux_query_client.dart';
import '../extensions/flux_query_logger.dart';

class FluxQueryCacheDevTools extends StatefulWidget {
  final FluxQueryClient client;
  const FluxQueryCacheDevTools({required this.client, super.key});

  @override
  State<FluxQueryCacheDevTools> createState() => _FluxQueryCacheDevToolsState();
}

class _FluxQueryCacheDevToolsState extends State<FluxQueryCacheDevTools> {
  Map<String, dynamic> _cache = {};
  List<FluxQueryLogEntry> _logs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cache = await widget.client.cache.getAllKeysAndStates();
    setState(() {
      _cache = cache;
      _logs = FluxQueryLoggerMemory().logs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: ListView(
          children: [
            const ListTile(title: Text('Query Cache DevTools', style: TextStyle(fontWeight: FontWeight.bold))),
            ListTile(title: const Text('Refresh'), leading: const Icon(Icons.refresh), onTap: _load),
            ExpansionTile(title: const Text('Cached Keys'), children: _cache.entries.map((e) => ListTile(title: Text(e.key), subtitle: Text('isStale: ${(e.value as dynamic).isStale}'))).toList()),
            ExpansionTile(title: const Text('Logs'), children: _logs.reversed.map((log) => ListTile(title: Text(log.message), subtitle: Text('${log.level} — ${log.timestamp}'))).toList()),
            ListTile(
              title: const Text('Clear logs'),
              leading: const Icon(Icons.delete),
              onTap: () {
                FluxQueryLoggerMemory().clear();
                setState(() => _logs = []);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Показывает DevTools как overlay поверх всего приложения
void showDevToolsOverlay(BuildContext context, FluxQueryClient client) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder:
        (ctx) => Stack(
          children: [
            Positioned.fill(child: GestureDetector(onTap: () => entry.remove(), child: Container(color: Colors.black54))),
            Center(
              child: FractionallySizedBox(
                widthFactor: 0.95,
                heightFactor: 0.85,
                child: Material(elevation: 8, borderRadius: BorderRadius.circular(16), clipBehavior: Clip.antiAlias, child: FluxQueryCacheDevTools(client: client)),
              ),
            ),
          ],
        ),
  );
  overlay.insert(entry);
}
