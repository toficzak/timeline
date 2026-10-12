import 'dart:io';

import 'package:flutter/material.dart';

import 'entry_photo_source.dart';
import 'timeline.dart';
import 'timeline_entry_form_screen.dart';
import 'timeline_repository.dart';

/// Displays the entries belonging to one timeline.
class TimelineEntriesScreen extends StatefulWidget {
  TimelineEntriesScreen({
    required this.timeline,
    required this.repository,
    EntryPhotoSource? photoSource,
    super.key,
  }) : photoSource = photoSource ?? ImagePickerEntryPhotoSource();

  final Timeline timeline;
  final TimelineRepository repository;
  final EntryPhotoSource photoSource;

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

  Future<void> _openForm() async {
    final TimelineEntry? created = await Navigator.of(context).push<TimelineEntry>(
      MaterialPageRoute<TimelineEntry>(
        builder: (context) => TimelineEntryFormScreen(
          timeline: widget.timeline,
          repository: widget.repository,
          photoSource: widget.photoSource,
        ),
      ),
    );
    if (created != null && mounted) _loadEntries();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.timeline.name),
      actions: <Widget>[
        IconButton(
          onPressed: _openForm,
          icon: const Icon(Icons.add),
          tooltip: 'Add entry',
        ),
      ],
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
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('No entries yet.'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _openForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Add entry'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: FilledButton.icon(
                  onPressed: _openForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Add entry'),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final TimelineEntry entry = entries[index];
                  return _EntryTile(
                    entry: entry,
                    repository: widget.repository,
                  );
                },
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.repository});

  final TimelineEntry entry;
  final TimelineRepository repository;

  @override
  Widget build(BuildContext context) => ListTile(
    title: entry.description.isEmpty ? null : Text(entry.description),
    subtitle: Text(entry.createdAt.toLocal().toString()),
    isThreeLine: entry.description.isNotEmpty,
    leading: entry.photoPath == null
        ? null
        : FutureBuilder<File>(
            future: repository.resolvePhoto(entry.photoPath!),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Image.file(
                  snapshot.data!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image),
                );
              }
              return const Icon(Icons.image_not_supported);
            },
          ),
  );
}
