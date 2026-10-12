import 'package:flutter/material.dart';

import 'entry_photo_source.dart';
import 'timeline.dart';
import 'timeline_entries_screen.dart';
import 'timeline_name_dialog.dart';
import 'timeline_repository.dart';

/// Displays the locally stored timelines and supports naming operations.
class TimelineListScreen extends StatefulWidget {
  const TimelineListScreen({required this.repository, this.photoSource, super.key});

  final TimelineRepository repository;
  final EntryPhotoSource? photoSource;

  @override
  State<TimelineListScreen> createState() => _TimelineListScreenState();
}

class _TimelineListScreenState extends State<TimelineListScreen> {
  late Future<List<Timeline>> _timelines;
  bool _deletePending = false;

  @override
  void initState() {
    super.initState();
    _loadTimelines();
  }

  @override
  void didUpdateWidget(covariant TimelineListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) _loadTimelines();
  }

  void _loadTimelines() {
    _timelines = widget.repository.listTimelines().then((timelines) {
      final List<Timeline> sorted = List<Timeline>.of(timelines)
        ..sort((first, second) => first.id.compareTo(second.id));
      return sorted;
    });
    if (mounted) setState(() {});
  }

  String _errorMessage(Object error) {
    if (error is TimelineRepositoryFailure) return error.message;
    return 'Unable to load timelines. Please try again.';
  }

  String _deleteErrorMessage(Object error) {
    if (error is TimelineRepositoryFailure) return error.message;
    return 'Unable to delete timeline. Please try again.';
  }

  Future<void> _openNameDialog([Timeline? timeline]) async {
    final Timeline? saved = await showDialog<Timeline>(
      context: context,
      builder: (context) => TimelineNameDialog(
        initialTimeline: timeline,
        operation: (name) => timeline == null
            ? widget.repository.createTimeline(name)
            : widget.repository.updateTimeline(timeline.copyWith(name: name)),
      ),
    );
    if (saved != null && mounted) _loadTimelines();
  }

  Future<void> _confirmDelete(Timeline timeline) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _DeleteConfirmationDialog(
        timeline: timeline,
        onDelete: (dialogContext) async {
          if (_deletePending) return;
          setState(() => _deletePending = true);
          try {
            await widget.repository.deleteTimeline(timeline.id);
            if (mounted && dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
              _loadTimelines();
            }
          } finally {
            if (mounted) setState(() => _deletePending = false);
          }
        },
        errorMessage: _deleteErrorMessage,
      ),
    );
  }

  Widget _createAction() => Align(
    alignment: Alignment.centerRight,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: FilledButton.icon(
        onPressed: () => _openNameDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Timeline>>(
    future: _timelines,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Column(
          children: <Widget>[
            _createAction(),
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading timelines...'),
                  ],
                ),
              ),
            ),
          ],
        );
      }
      if (snapshot.hasError) {
        return Column(
          children: <Widget>[
            _createAction(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(_errorMessage(snapshot.error!)),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loadTimelines,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }

      final List<Timeline> timelines = snapshot.data ?? <Timeline>[];
      if (timelines.isEmpty) {
        return Column(
          children: <Widget>[
            _createAction(),
            const Expanded(child: Center(child: Text('No timelines yet.'))),
          ],
        );
      }

      return Column(
        children: <Widget>[
          _createAction(),
          Expanded(
            child: ListView.builder(
              itemCount: timelines.length,
              itemBuilder: (context, index) {
                final Timeline timeline = timelines[index];
                return ListTile(
                  title: Text(timeline.name),
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (context) => TimelineEntriesScreen(
                          timeline: timeline,
                          repository: widget.repository,
                          photoSource: widget.photoSource,
                        ),
                      ),
                    );
                  },
                  trailing: PopupMenuButton<_TimelineAction>(
                    enabled: !_deletePending,
                    tooltip: 'Actions for ${timeline.name}',
                    onSelected: (action) {
                      switch (action) {
                        case _TimelineAction.edit:
                          _openNameDialog(timeline);
                        case _TimelineAction.delete:
                          _confirmDelete(timeline);
                      }
                    },
                    itemBuilder: (context) =>
                        const <PopupMenuEntry<_TimelineAction>>[
                          PopupMenuItem<_TimelineAction>(
                            value: _TimelineAction.edit,
                            child: Text('Edit'),
                          ),
                          PopupMenuItem<_TimelineAction>(
                            value: _TimelineAction.delete,
                            child: Text('Delete'),
                          ),
                        ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}

enum _TimelineAction { edit, delete }

class _DeleteConfirmationDialog extends StatefulWidget {
  const _DeleteConfirmationDialog({
    required this.timeline,
    required this.onDelete,
    required this.errorMessage,
  });

  final Timeline timeline;
  final Future<void> Function(BuildContext dialogContext) onDelete;
  final String Function(Object error) errorMessage;

  @override
  State<_DeleteConfirmationDialog> createState() =>
      _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<_DeleteConfirmationDialog> {
  bool _pending = false;
  String? _error;

  Future<void> _delete() async {
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      await widget.onDelete(context);
    } catch (error) {
      if (mounted) setState(() => _error = widget.errorMessage(error));
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Delete timeline'),
    content: SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Delete "${widget.timeline.name}"?'),
          const SizedBox(height: 12),
          const Text(
            'Its associated entries will also be deleted. This cannot be undone.',
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: _pending ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _pending ? null : _delete,
        child: _pending
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Delete'),
      ),
    ],
  );
}
