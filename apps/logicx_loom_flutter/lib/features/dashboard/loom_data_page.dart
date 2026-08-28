import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api/logicx_loom_api.dart';

class LoomDataPageView extends StatefulWidget {
  const LoomDataPageView({required this.api, required this.session, super.key});

  final LogicXLoomApi api;
  final UserSession session;

  @override
  State<LoomDataPageView> createState() => _LoomDataPageViewState();
}

class _LoomDataPageViewState extends State<LoomDataPageView> {
  Timer? _poller;
  List<LoomDataEvent> _events = [];
  String? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
    _poller = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final page = await widget.api.loomEvents(widget.session.accessToken);
      if (!mounted) return;
      setState(() {
        _events = page.items;
        _error = null;
        _loading = false;
      });
    } on LogicXLoomApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not synchronize Loom data.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _events.isEmpty) {
      return _SyncError(message: _error!, onRetry: _refresh);
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sensors, color: Color(0xFF305DDD)),
                      const SizedBox(width: 8),
                      Text(
                        'Live machine feed',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF305DDD),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Loom JSON data',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text('${_events.length} payloads synchronized'),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
          ),
          if (_events.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Waiting for machine JSON.')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              sliver: SliverList.separated(
                itemCount: _events.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _EventCard(event: _events[index]),
              ),
            ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final LoomDataEvent event;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    margin: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: const Color(0xFF305DDD),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Text(
                '#${event.id}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _eventTime(event.receivedAt),
                  style: const TextStyle(color: Color(0xFFDDE6FF)),
                ),
              ),
              Text(
                _bytes(event.contentBytes),
                style: const TextStyle(color: Color(0xFFDDE6FF)),
              ),
            ],
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: SelectableText(
            event.formattedPayload,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SyncError extends StatelessWidget {
  const _SyncError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

String _eventTime(DateTime value) =>
    value.toLocal().toString().split('.').first;
String _bytes(int value) =>
    value < 1024 ? '$value B' : '${(value / 1024).toStringAsFixed(1)} KB';
