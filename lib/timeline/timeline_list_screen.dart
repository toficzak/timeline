import 'package:flutter/material.dart';

import 'timeline.dart';
import 'timeline_repository.dart';

/// Displays the locally stored timelines without adding navigation or editing.
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

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Timeline>>(
    future: _timelines,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading timelines...'),
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
                onPressed: _loadTimelines,
                child: const Text('Try again'),
              ),
            ],
          ),
        );
      }

      final List<Timeline> timelines = snapshot.data ?? <Timeline>[];
      if (timelines.isEmpty) {
        return const Center(child: Text('No timelines yet.'));
      }

      return ListView.builder(
        itemCount: timelines.length,
        itemBuilder: (context, index) =>
            ListTile(title: Text(timelines[index].name)),
      );
    },
  );
}
