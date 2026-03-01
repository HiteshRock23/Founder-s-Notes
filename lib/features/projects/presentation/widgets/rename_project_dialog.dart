import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/project.dart';
import '../providers/project_provider.dart';
import '../../../../core/errors/api_exception.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RenameProjectDialog
//
// An AlertDialog that lets the user edit the project's name.
// All mutation logic stays in ProjectsNotifier — this widget only:
//   1. Captures input
//   2. Validates locally (non-empty)
//   3. Calls notifier.renameProject()
//   4. Pops on success, or shows an inline error message on failure
//
// Usage:
//   RenameProjectDialog.show(context, ref, project);
// ─────────────────────────────────────────────────────────────────────────────

class RenameProjectDialog extends ConsumerStatefulWidget {
  final Project project;

  const RenameProjectDialog._({required this.project});

  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // prevent accidental dismiss while saving
      builder: (_) => RenameProjectDialog._(project: project),
    );
  }

  @override
  ConsumerState<RenameProjectDialog> createState() =>
      _RenameProjectDialogState();
}

class _RenameProjectDialogState extends ConsumerState<RenameProjectDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.project.name);
    // Select all text so the user can immediately overwrite.
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.project.name.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;

    final newName = _controller.text.trim();
    if (newName == widget.project.name) {
      // Nothing changed — dismiss without a network call.
      if (mounted) Navigator.of(context).pop();
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(projectsListProvider.notifier)
          .renameProject(widget.project.id, newName);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isSaving = false;
        _serverError = e is ApiException
            ? e.message
            : 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Rename Project',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Project name',
                hintText: 'e.g. Growth Strategy',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Project name cannot be empty';
                }
                if (v.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
              onFieldSubmitted: (_) => _isSaving ? null : _save(),
            ),
            if (_serverError != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.error_outline,
                      size: 14, color: theme.colorScheme.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _serverError!,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          style: FilledButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSaving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
