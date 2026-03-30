import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../providers/project_provider.dart';
import '../../../../core/errors/api_exception.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AddFileBottomSheet
//
// Responsibilities:
//   1. Let the user enter a title
//   2. Open the system file picker (PDF, DOC, DOCX, PNG, JPG)
//   3. Upload via AddItemNotifier.addFileItem()
//   4. Close on success / show SnackBar on error
//
// Usage:
//   AddFileBottomSheet.show(context, projectId);
// ─────────────────────────────────────────────────────────────────────────────

class AddFileBottomSheet extends ConsumerStatefulWidget {
  final String projectId;

  const AddFileBottomSheet._({required this.projectId});

  static Future<void> show(BuildContext context, String projectId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddFileBottomSheet._(projectId: projectId),
    );
  }

  @override
  ConsumerState<AddFileBottomSheet> createState() => _AddFileBottomSheetState();
}

class _AddFileBottomSheetState extends ConsumerState<AddFileBottomSheet> {
  final _titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Picked file state
  PlatformFile? _pickedFile;
  bool _isUploading = false;
  String? _serverError;

  // Allowed extensions
  static const _allowedExtensions = [
    'pdf',
    'doc',
    'docx',
    'png',
    'jpg',
    'jpeg'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // ── File picker ────────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: false, // don't load bytes into memory — use path for upload
      withReadStream: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFile = result.files.first;
        // Pre-fill title with filename (without extension) if title is empty
        if (_titleController.text.trim().isEmpty) {
          _titleController.text = p.basenameWithoutExtension(_pickedFile!.name);
        }
      });
    }
  }

  // ── Upload ─────────────────────────────────────────────────────────────────

  Future<void> _upload() async {
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;
    if (_pickedFile == null) return; // guard — button is disabled anyway

    final filePath = _pickedFile!.path;
    if (filePath == null) {
      setState(() => _serverError = 'Could not access file path. Try again.');
      return;
    }

    setState(() => _isUploading = true);

    try {
      await ref.read(addItemProvider(widget.projectId).notifier).addFileItem(
            title: _titleController.text.trim(),
            filePath: filePath,
            fileName: _pickedFile!.name,
          );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isUploading = false;
        _serverError =
            e is ApiException ? e.message : 'Upload failed. Please try again.';
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final canUpload = _pickedFile != null && !_isUploading;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ──────────────────────────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ──────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.upload_file_rounded,
                      color: Color(0xFFFF6F00), size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Upload File',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Title field ──────────────────────────────────────────────────
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Q1 Report',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── File picker button ───────────────────────────────────────────
            InkWell(
              onTap: _isUploading ? null : _pickFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: theme.colorScheme.surface,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                            : 'Choose file (PDF, DOC, PNG, JPG)',
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
                    if (_pickedFile != null)
                      TextButton(
                        onPressed: _isUploading
                            ? null
                            : () => setState(() => _pickedFile = null),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 32),
                        ),
                        child: Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── File size hint ───────────────────────────────────────────────
            if (_pickedFile?.size != null && _pickedFile!.size > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  _formatBytes(_pickedFile!.size),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ),

            // ── Server error ─────────────────────────────────────────────────
            if (_serverError != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.error_outline, size: 14, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _serverError!,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // ── Action buttons ───────────────────────────────────────────────
            Row(
              children: [
                TextButton(
                  onPressed:
                      _isUploading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canUpload ? _upload : null,
                    icon: _isUploading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.upload_rounded, size: 18),
                    label: Text(_isUploading ? 'Uploading…' : 'Upload'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
