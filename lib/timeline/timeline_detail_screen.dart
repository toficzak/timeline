import 'package:flutter/material.dart';

import 'timeline.dart';
import 'timeline_repository.dart';

/// Presents the entries belonging to one timeline.
class TimelineDetailScreen extends StatefulWidget {
  const TimelineDetailScreen({
    required this.repository,
    required this.timeline,
    super.key,
  });

  final TimelineRepository repository;
  final Timeline timeline;

  @override
  State<TimelineDetailScreen> createState() => _TimelineDetailScreenState();
}

class _TimelineDetailScreenState extends State<TimelineDetailScreen> {
  late Future<List<TimelineEntry>> _entries;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void didUpdateWidget(covariant TimelineDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.timeline.id != widget.timeline.id) {
      _loadEntries();
    }
  }

  void _loadEntries() {
    _entries = widget.repository.listEntries(widget.timeline.id).then((entries) {
      final List<TimelineEntry> sorted = List<TimelineEntry>.of(entries)
        ..sort((first, second) => first.createdAt.compareTo(second.createdAt));
      return sorted;
    });
    if (mounted) setState(() {});
  }

  String _errorMessage(Object error) {
    if (error is TimelineRepositoryFailure) return error.message;
    return 'Unable to load entries. Please try again.';
  }

  List<Widget> _entrySections(
    BuildContext context,
    List<TimelineEntry> entries,
  ) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );
    final List<Widget> sections = <Widget>[];
    DateTime? currentDay;

    for (final TimelineEntry entry in entries) {
      final DateTime localDate = entry.createdAt.toLocal();
      final DateTime day = DateTime(
        localDate.year,
        localDate.month,
        localDate.day,
      );
      if (currentDay != day) {
        currentDay = day;
        sections.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              localizations.formatMediumDate(day),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        );
      }
      sections.add(
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(entry.description),
            ),
          ),
        ),
      );
    }
    return sections;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.timeline.name)),
    // The entry form is introduced in Phase 2. Keeping the affordance visible
    // here gives empty timelines a stable action area without creating anything.
    floatingActionButton: const FloatingActionButton(
      onPressed: null,
      tooltip: 'Add entry',
      child: Icon(Icons.add),
    ),
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

        return ListView(children: _entrySections(context, entries));
      },
    ),
  );
}
