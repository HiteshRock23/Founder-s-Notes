import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/item.dart';
import '../providers/project_provider.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../core/errors/api_exception.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EditItemBottomSheet
//
// Pre-filled sheet for editing an existing note, link, or file item.
// File items can only have their title changed (not re-upload from here).
//
// Usage:
//   EditItemBottomSheet.show(context, item, projectId);
// ─────────────────────────────────────────────────────────────────────────────

class EditItemBottomSheet extends ConsumerStatefulWidget {
  final Item item;
  final String projectId;

  const EditItemBottomSheet._({required this.item, required this.projectId});

  static Future<void> show(
      BuildContext context, Item item, String projectId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          EditItemBottomSheet._(item: item, projectId: projectId),
    );
  }

  @override
  ConsumerState<EditItemBottomSheet> createState() =>
      _EditItemBottomSheetState();
}

class _EditItemBottomSheetState extends ConsumerState<EditItemBottomSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _urlController;
  late final TextEditingController _descriptionController;

  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _serverError;

  Item get _item => widget.item;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: _item.title);
    _contentController = TextEditingController(text: _item.content ?? '');
    _urlController = TextEditingController(text: _item.url ?? '');
    _descriptionController =
        TextEditingController(text: _item.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(addItemProvider(widget.projectId).notifier)
          .editItem(
            itemId: _item.id,
            title: _titleController.text.trim(),
            content: _item.type == ItemType.note
                ? _contentController.text.trim()
                : null,
            url: _item.type == ItemType.link
                ? _urlController.text.trim()
                : null,
            description: _item.type == ItemType.link
                ? _descriptionController.text.trim()
                : null,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _serverError = e is ApiException ? e.message : e.toString();
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Handle ───────────────────────────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ───────────────────────────────────────────────────────
            Row(
              children: [
                Icon(_typeIcon, color: _typeColor, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Edit $_typeName',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Title (all types) ─────────────────────────────────────────────
            AppTextField(
              label: 'Title',
              hintText: 'Title',
              controller: _titleController,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Title is required';
                if (v.trim().length < 2) return 'At least 2 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Note-specific ─────────────────────────────────────────────────
            if (_item.type == ItemType.note) ...[
              AppTextField(
                label: 'Content (optional)',
                hintText: 'Write your note here…',
                controller: _contentController,
              ),
            ],

            // ── Link-specific ─────────────────────────────────────────────────
            if (_item.type == ItemType.link) ...[
              AppTextField(
                label: 'URL',
                hintText: 'https://example.com',
                controller: _urlController,
                keyboardType: TextInputType.url,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'URL is required';
                  final uri = Uri.tryParse(v.trim());
                  if (uri == null || !uri.hasScheme) return 'Enter a valid URL';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Description (optional)',
                hintText: 'What is this link about?',
                controller: _descriptionController,
              ),
            ],

            // ── File-specific hint ────────────────────────────────────────────
            if (_item.type == ItemType.file) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Only the title can be changed here. To replace the file, delete this item and re-upload.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Server error ──────────────────────────────────────────────────
            if (_serverError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        size: 16,
                        color: theme.colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _serverError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // ── Action row ────────────────────────────────────────────────────
            Row(
              children: [
                TextButton(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _typeName {
    switch (_item.type) {
      case ItemType.note:
        return 'Note';
      case ItemType.link:
        return 'Link';
      case ItemType.file:
        return 'File';
    }
  }

  IconData get _typeIcon {
    switch (_item.type) {
      case ItemType.note:
        return Icons.notes_rounded;
      case ItemType.link:
        return Icons.link_rounded;
      case ItemType.file:
        return Icons.upload_file_rounded;
    }
  }

  Color get _typeColor {
    switch (_item.type) {
      case ItemType.note:
        return Colors.indigo;
      case ItemType.link:
        return Colors.teal;
      case ItemType.file:
        return Colors.orange;
    }
  }
}
