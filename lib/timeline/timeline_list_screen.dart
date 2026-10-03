import 'package:flutter/material.dart';

import 'timeline.dart';
import 'timeline_name_dialog.dart';
import 'timeline_repository.dart';

/// Displays the locally stored timelines and supports naming operations.
class TimelineListScreen extends StatefulWidget {
  const TimelineListScreen({required this.repository, super.key});

  final TimelineRepository repository;

  @override
  State<TimelineListScreen> createState() => _TimelineListScreenState();
}

class _TimelineListScreenState extends State<TimelineListScreen> {
  late Future<List<Timeline>> _timelines;

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
                  trailing: IconButton(
                    tooltip: 'Edit ${timeline.name}',
                    icon: const Icon(Icons.edit),
                    onPressed: () => _openNameDialog(timeline),
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
