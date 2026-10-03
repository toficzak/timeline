import 'package:flutter/material.dart';

import 'timeline.dart';
import 'timeline_repository.dart';

typedef TimelineNameOperation = Future<Timeline> Function(String name);

/// The shared name form used when creating and renaming a timeline.
class TimelineNameDialog extends StatefulWidget {
  const TimelineNameDialog({
    required this.operation,
    this.initialTimeline,
    super.key,
  });

  final Timeline? initialTimeline;
  final TimelineNameOperation operation;

  @override
  State<TimelineNameDialog> createState() => _TimelineNameDialogState();
}

class _TimelineNameDialogState extends State<TimelineNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialTimeline?.name ?? '',
  );
  late final FocusNode _focusNode = FocusNode();
  String? _validationError;
  String? _operationError;
  bool _pending = false;

  bool get _editing => widget.initialTimeline != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _messageFor(Object error) {
    if (error is TimelineRepositoryFailure) return error.message;
    return 'Unable to save timeline. Please try again.';
  }

  Future<void> _save() async {
    final String name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() {
        _validationError = 'Timeline name cannot be empty.';
        _operationError = null;
      });
      return;
    }

    setState(() {
      _validationError = null;
      _operationError = null;
      _pending = true;
    });
    try {
      final Timeline saved = await widget.operation(name);
      if (mounted) Navigator.of(context).pop(saved);
    } catch (error) {
      if (mounted) {
        setState(() {
          _pending = false;
          _operationError = _messageFor(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(_editing ? 'Edit timeline' : 'Create timeline'),
    content: SizedBox(
      width: 360,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: !_pending,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _pending ? null : _save(),
        decoration: InputDecoration(
          labelText: 'Timeline name',
          errorText: _validationError,
          helperText: _operationError,
          helperStyle: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: _pending ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _pending ? null : _save,
        child: _pending
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(_editing ? 'Save' : 'Create'),
      ),
    ],
  );
}
