import 'dart:io';

import 'package:flutter/material.dart';

import 'entry_photo_source.dart';
import 'timeline.dart';
import 'timeline_repository.dart';

/// Focused form for creating one entry in a selected timeline.
class TimelineEntryFormScreen extends StatefulWidget {
  const TimelineEntryFormScreen({
    required this.timeline,
    required this.repository,
    required this.photoSource,
    super.key,
  });

  final Timeline timeline;
  final TimelineRepository repository;
  final EntryPhotoSource photoSource;

  @override
  State<TimelineEntryFormScreen> createState() =>
      _TimelineEntryFormScreenState();
}

class _TimelineEntryFormScreenState extends State<TimelineEntryFormScreen> {
  late final DateTime _capturedAt = DateTime.now();
  late final TextEditingController _descriptionController =
      TextEditingController();

  File? _photo;
  String? _error;
  bool _pending = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String _sourceError(Object error) {
    if (error is TimelineRepositoryFailure) return error.message;
    return 'Unable to select a photo. Please try again.';
  }

  String _saveError(Object error) {
    if (error is TimelineRepositoryFailure) return error.message;
    return 'Unable to save entry. Please try again.';
  }

  Future<void> _pickFromGallery() async {
    if (_pending) return;
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      final File? selected = await widget.photoSource.pickFromGallery();
      if (mounted && selected != null) {
        setState(() => _photo = selected);
      }
    } catch (error) {
      if (mounted) setState(() => _error = _sourceError(error));
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  Future<void> _captureFromCamera() async {
    if (_pending) return;
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      final File captured = await widget.photoSource.captureFromCamera();
      if (mounted) setState(() => _photo = captured);
    } catch (error) {
      if (mounted) setState(() => _error = _sourceError(error));
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  Future<void> _save() async {
    if (_pending) return;
    setState(() {
      _pending = true;
      _error = null;
    });
    try {
      final TimelineEntry entry = await widget.repository.createEntry(
        timelineId: widget.timeline.id,
        description: _descriptionController.text.trim(),
        photo: _photo,
        createdAt: _capturedAt,
      );
      if (mounted) Navigator.of(context).pop(entry);
    } catch (error) {
      if (mounted) {
        setState(() {
          _pending = false;
          _error = _saveError(error);
        });
      }
    }
  }

  Widget _photoPreview() {
    if (_photo == null) {
      return const Center(child: Text('No photo selected'));
    }
    return Image.file(
      _photo!,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) =>
          const Center(child: Text('Photo selected')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );
    final DateTime localTime = _capturedAt.toLocal();

    return Scaffold(
      appBar: AppBar(title: Text('New entry · ${widget.timeline.name}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              localizations.formatFullDate(localTime),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              localizations.formatTimeOfDay(TimeOfDay.fromDateTime(localTime)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _photoPreview(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: _pending ? null : _captureFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                OutlinedButton.icon(
                  onPressed: _pending ? null : _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
                if (_photo != null)
                  TextButton(
                    onPressed: _pending
                        ? null
                        : () => setState(() {
                            _photo = null;
                            _error = null;
                          }),
                    child: const Text('Remove photo'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              enabled: !_pending,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: _pending
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _pending ? null : _save,
                  child: _pending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
