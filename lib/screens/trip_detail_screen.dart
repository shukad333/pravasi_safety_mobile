import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/safety_repository.dart';
import '../models/safety_info.dart';
import '../models/trip.dart';
import 'settings_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late Future<CachedSafetyInfo> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<CachedSafetyInfo> _load({bool refresh = false}) =>
      context.read<SafetyRepository>().get(widget.trip.destinationCode,
          forceRefresh: refresh);

  void _reload({bool refresh = false}) {
    final next = _load(refresh: refresh);
    setState(() {
      _future = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dest = widget.trip.destination;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${dest.flag}  ${dest.name}'),
          actions: [
            IconButton(
              tooltip: 'Refresh from source',
              icon: const Icon(Icons.refresh),
              onPressed: () => _reload(refresh: true),
            ),
          ],
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.block), text: "Don't carry"),
            Tab(icon: Icon(Icons.warning_amber), text: 'Restricted'),
            Tab(icon: Icon(Icons.check_circle_outline), text: 'Carry'),
          ]),
        ),
        body: FutureBuilder<CachedSafetyInfo>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const _Loading();
            }
            if (snap.hasError) {
              return _Error(
                message: snap.error.toString(),
                onRetry: () => _reload(),
              );
            }
            final cached = snap.data!;
            final info = cached.info;
            return Column(
              children: [
                _SummaryBanner(cached: cached),
                Expanded(
                  child: TabBarView(children: [
                    _ItemList(
                      items: info.prohibited,
                      icon: Icons.block,
                      color: Theme.of(context).colorScheme.error,
                      empty: 'No specific prohibited items listed.',
                    ),
                    _ItemList(
                      items: info.restricted,
                      icon: Icons.warning_amber,
                      color: Colors.orange,
                      empty: 'No restricted items listed.',
                    ),
                    _ItemList(
                      items: info.recommended,
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                      empty: 'No recommendations listed.',
                      footer: info.tips.isEmpty ? null : _Tips(tips: info.tips),
                    ),
                  ]),
                ),
                if (info.disclaimer.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Text(info.disclaimer,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final CachedSafetyInfo cached;
  const _SummaryBanner({required this.cached});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cached.info.summary),
          const SizedBox(height: 6),
          Text(
            'Saved on device · updated ${DateFormat.yMMMd().format(cached.fetchedAt)}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  final List<GuidanceItem> items;
  final IconData icon;
  final Color color;
  final String empty;
  final Widget? footer;

  const _ItemList({
    required this.items,
    required this.icon,
    required this.color,
    required this.empty,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && footer == null) {
      return Center(child: Text(empty));
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final i in items)
          Card(
            child: ListTile(
              leading: Icon(icon, color: color),
              title: Text(i.item),
              subtitle: Text(i.details),
            ),
          ),
        if (footer != null) footer!,
      ],
    );
  }
}

class _Tips extends StatelessWidget {
  final List<String> tips;
  const _Tips({required this.tips});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.lightbulb_outline),
              const SizedBox(width: 8),
              Text('Tips', style: Theme.of(context).textTheme.titleMedium),
            ]),
            const SizedBox(height: 8),
            for (final t in tips)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('• $t'),
              ),
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking customs rules…'),
            SizedBox(height: 4),
            Text('First lookup can take up to a minute.'),
          ],
        ),
      );
}

class _Error extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _Error({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final needsKey = message.contains('API key');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (needsKey)
              FilledButton(
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const SettingsScreen()));
                  onRetry();
                },
                child: const Text('Open Settings'),
              )
            else
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
