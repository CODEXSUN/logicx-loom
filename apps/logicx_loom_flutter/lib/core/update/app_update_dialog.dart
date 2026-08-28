import 'package:flutter/material.dart';

import 'app_update_service.dart';

class AppUpdateDialog extends StatefulWidget {
  const AppUpdateDialog({
    required this.update,
    required this.service,
    super.key,
  });

  final AppUpdate update;
  final AppUpdateService service;

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  double? _progress;
  String? _error;

  Future<void> _install() async {
    setState(() {
      _error = null;
      _progress = 0;
    });
    try {
      await widget.service.downloadAndInstall(
        widget.update,
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress.clamp(0, 1));
        },
      );
    } on AppUpdateException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted)
        setState(() => _error = 'The update could not be installed.');
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('LogicX Loom ${widget.update.version} is available'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.update.notes.isNotEmpty)
          ...widget.update.notes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• $note'),
            ),
          ),
        if (_progress != null) ...[
          const SizedBox(height: 14),
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 8),
          Text('${((_progress ?? 0) * 100).round()}% downloaded'),
        ],
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    ),
    actions: [
      if (!widget.update.required)
        TextButton(
          onPressed: _progress == null ? () => Navigator.pop(context) : null,
          child: const Text('Later'),
        ),
      FilledButton(
        onPressed: _progress == null || _error != null ? _install : null,
        child: Text(_error == null ? 'Update' : 'Retry'),
      ),
    ],
  );
}
