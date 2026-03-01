import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/item.dart';
import '../providers/project_provider.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final Item item;

  const NoteEditorScreen({super.key, required this.item});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _contentController = TextEditingController(text: widget.item.content ?? '');
    
    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {}); // Needed to evaluate _hasChanges for Save button state
  }

  bool get _hasChanges {
    final titleChanged = _titleController.text.trim() != widget.item.title;
    final fallbackContent = widget.item.content ?? '';
    final contentChanged = _contentController.text.trim() != fallbackContent;
    return titleChanged || contentChanged;
  }

  Future<void> _save() async {
    if (!_hasChanges) return;

    setState(() => _isSaving = true);

    try {
      final updatedItem = widget.item.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
      );

      // Invoke the StateNotifier method to update silently without refetching list
      await ref
          .read(projectItemsProvider(widget.item.projectId).notifier)
          .updateItem(updatedItem);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save note: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Requirements: Disable if nothing changed / empty title / is saving.
    final canSave = _hasChanges && !_isSaving && _titleController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit Note', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
               onPressed: canSave ? _save : null,
               style: TextButton.styleFrom(
                 foregroundColor: Colors.blue.shade700,
                 disabledForegroundColor: Colors.grey.shade400,
                 padding: const EdgeInsets.symmetric(horizontal: 16),
               ),
               child: const Text(
                 'Save',
                 style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
               ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: TextField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: 'Note Title',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Start typing...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: InputBorder.none,
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
