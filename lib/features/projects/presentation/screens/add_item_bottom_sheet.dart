import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../domain/entities/item.dart';
import '../providers/project_provider.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../core/errors/api_exception.dart';

/// Modal bottom sheet for adding a new item (Note or Link) to a project.
///
/// Usage:
/// ```dart
/// AddItemBottomSheet.show(context, projectId);
/// ```
class AddItemBottomSheet extends ConsumerStatefulWidget {
  final String projectId;

  const AddItemBottomSheet._({required this.projectId});

  /// Opens the sheet. [projectId] is passed directly — no global state needed.
  static Future<void> show(BuildContext context, String projectId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,       // lets sheet resize above keyboard
      backgroundColor: Colors.transparent,
      builder: (_) => AddItemBottomSheet._(projectId: projectId),
    );
  }

  @override
  ConsumerState<AddItemBottomSheet> createState() => _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends ConsumerState<AddItemBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _urlController = TextEditingController();
  final _descriptionController = TextEditingController();

  ItemType _selectedType = ItemType.note;
  bool _isSubmitting = false;
  String? _serverError;

  // File-type state
  PlatformFile? _pickedFile;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
      withData: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFile = result.files.first;
        if (_titleController.text.trim().isEmpty) {
          _titleController.text =
              p.basenameWithoutExtension(_pickedFile!.name);
        }
      });
    }
  }

  // ──────────────────────────────────────────────────────
  // Submit
  // ──────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      if (_selectedType == ItemType.file) {
        // File upload uses multipart FormData — different codepath.
        final filePath = _pickedFile?.path;
        if (filePath == null) {
          setState(() {
            _isSubmitting = false;
            _serverError = 'Could not access file path. Try again.';
          });
          return;
        }
        await ref
            .read(addItemProvider(widget.projectId).notifier)
            .addFileItem(
              title: _titleController.text.trim(),
              filePath: filePath,
              fileName: _pickedFile!.name,
            );
      } else {
        await ref.read(addItemProvider(widget.projectId).notifier).addItem(
              type: _selectedType,
              title: _titleController.text.trim(),
              content: _selectedType == ItemType.note
                  ? _contentController.text.trim().isEmpty
                      ? null
                      : _contentController.text.trim()
                  : null,
              url: _selectedType == ItemType.link
                  ? _urlController.text.trim()
                  : null,
              description: _selectedType == ItemType.link
                  ? _descriptionController.text.trim().isEmpty
                      ? null
                      : _descriptionController.text.trim()
                  : null,
            );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        if (e is ApiException) {
          _serverError = e.message.isNotEmpty
              ? e.message
              : 'Server error. Please try again.';
        } else {
          // Show real error in debug so we can identify root cause.
          _serverError = e.toString();
        }
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ──────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────


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
            // ── Drag handle ──────────────────────────────
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

            // ── Title ────────────────────────────────────
            Text(
              'Add Item',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Capture a note or a link into this project.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),

            // ── Type toggle chips ─────────────────────────
            _TypeChipRow(
              selected: _selectedType,
              onChanged: (type) => setState(() {
                _selectedType = type;
                _serverError = null;
              }),
            ),
            const SizedBox(height: 20),

            // ── Title field (always shown) ────────────────
            AppTextField(
              label: 'Title',
              hintText: _selectedType == ItemType.note
                  ? 'e.g. Key product insight'
                  : 'e.g. Stripe Docs',
              controller: _titleController,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Title is required';
                if (v.trim().length < 2) return 'Title must be at least 2 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Note-specific fields ──────────────────────
            if (_selectedType == ItemType.note) ...[
              AppTextField(
                label: 'Content (optional)',
                hintText: 'Write your note here…',
                controller: _contentController,
              ),
            ],

            // ── Link-specific fields ──────────────────────
            if (_selectedType == ItemType.link) ...[
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

            // ── File-specific section ─────────────────────
            if (_selectedType == ItemType.file) ...[
              InkWell(
                onTap: _isSubmitting ? null : _pickFile,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _pickedFile != null
                          ? const Color(0xFF2196F3)
                          : Colors.grey.shade300,
                      width: _pickedFile != null ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _pickedFile != null
                        ? const Color(0xFFE3F2FD)
                        : Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _pickedFile != null
                            ? Icons.check_circle_rounded
                            : Icons.attach_file_rounded,
                        color: _pickedFile != null
                            ? const Color(0xFF2196F3)
                            : Colors.grey[500],
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _pickedFile != null
                              ? _pickedFile!.name
                              : 'Choose file  (PDF, DOC, PNG, JPG)',
                          style: TextStyle(
                            fontSize: 14,
                            color: _pickedFile != null
                                ? const Color(0xFF1565C0)
                                : Colors.grey[500],
                            fontWeight: _pickedFile != null
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_pickedFile?.size != null && _pickedFile!.size > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    _formatBytes(_pickedFile!.size),
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ),
            ],

            // ── Server error ──────────────────────────────
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
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: theme.colorScheme.onErrorContainer,
                    ),
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

            // ── Submit button ─────────────────────────────
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isSubmitting
                    ? null
                    : (_selectedType == ItemType.file && _pickedFile == null)
                        ? null // disabled until file is picked
                        : _submit,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Text(
                        'Add Item',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Type Chip Row — private helper widget
// ──────────────────────────────────────────────────────────────────────────────

class _TypeChipRow extends StatelessWidget {
  final ItemType selected;
  final ValueChanged<ItemType> onChanged;

  const _TypeChipRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _chip(context, ItemType.note, Icons.notes_rounded, 'Note'),
        const SizedBox(width: 8),
        _chip(context, ItemType.link, Icons.link_rounded, 'Link'),
        const SizedBox(width: 8),
        _chip(context, ItemType.file, Icons.upload_file_rounded, 'File'),
      ],
    );
  }

  Widget _chip(
      BuildContext context, ItemType type, IconData icon, String label) {
    final theme = Theme.of(context);
    final isSelected = selected == type;

    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onChanged(type),
      selectedColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
