import 'package:flutter/material.dart';

import 'timeline.dart';
import 'timeline_repository.dart';

/// Displays the entries belonging to one timeline.
class TimelineEntriesScreen extends StatefulWidget {
  const TimelineEntriesScreen({
    required this.timeline,
    required this.repository,
    super.key,
  });

  final Timeline timeline;
  final TimelineRepository repository;

  @override
  State<TimelineEntriesScreen> createState() => _TimelineEntriesScreenState();
}

class _TimelineEntriesScreenState extends State<TimelineEntriesScreen> {
  late Future<List<TimelineEntry>> _entries;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  void _loadEntries() {
    _entries = widget.repository.listEntries(widget.timeline.id).then((
      entries,
    ) {
      final List<TimelineEntry> selected =
          entries
              .where((entry) => entry.timelineId == widget.timeline.id)
              .toList()
            ..sort(
              (first, second) => first.createdAt.compareTo(second.createdAt),
            );
      return selected;
    });
    if (mounted) setState(() {});
  }

  String _errorMessage(Object error) {
    if (error is TimelineRepositoryFailure) return error.message;
    return 'Unable to load entries. Please try again.';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.timeline.name)),
    body: FutureBuilder<List<TimelineEntry>>(
      future: _entries,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading entries...'),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(_errorMessage(snapshot.error!)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadEntries,
                  child: const Text('Try again'),
                ),
              ],
            ),
          );
        }

        final List<TimelineEntry> entries = snapshot.data ?? <TimelineEntry>[];
        if (entries.isEmpty) {
          return const Center(child: Text('No entries yet.'));
        }

        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final TimelineEntry entry = entries[index];
            return ListTile(
              title: Text(entry.description),
              subtitle: Text(entry.createdAt.toLocal().toString()),
            );
          },
        );
      },
    ),
  );
}
