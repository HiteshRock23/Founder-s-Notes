import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/item.dart';
import '../providers/project_provider.dart';
import 'edit_item_bottom_sheet.dart';
import 'package:mobile/features/projects/presentation/screens/note_editor_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ItemTile — displays one item in the project timeline.
//
// • Tap    → open link / file in external app / snackbar for notes
// • Long press → action sheet with Edit and Delete options
// ─────────────────────────────────────────────────────────────────────────────

class ItemTile extends ConsumerWidget {
  final Item item;
  final String projectId;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;
  final VoidCallback? onLongPressToggle;

  const ItemTile({
    super.key,
    required this.item,
    required this.projectId,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionToggle,
    this.onLongPressToggle,
  });

  // ── Tap handler ────────────────────────────────────────────────────────────

  Future<void> _handleTap(BuildContext context) async {
    if (item.type == ItemType.link) {
      final rawUrl = item.url;
      if (rawUrl == null || rawUrl.isEmpty) {
        _showSnackBar(context, 'No URL saved for this link.');
        return;
      }
      final uri = Uri.tryParse(rawUrl);
      if (uri == null) {
        _showSnackBar(context, 'Invalid URL.');
        return;
      }
      final canOpen = await canLaunchUrl(uri);
      if (canOpen) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        _showSnackBar(context, 'Could not open: $rawUrl');
      }
    } else if (item.type == ItemType.file) {
      final fileUrl = item.fileUrl;
      if (fileUrl == null || fileUrl.isEmpty) {
        _showSnackBar(context, 'File URL not available.');
        return;
      }
      final uri = Uri.tryParse(fileUrl);
      if (uri == null) {
        _showSnackBar(context, 'Invalid file URL.');
        return;
      }
      final canOpen = await canLaunchUrl(uri);
      if (canOpen) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        _showSnackBar(context, 'Could not open file.');
      }
    } else {
      // Notes — open full-screen Note Editor Screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => NoteEditorScreen(item: item),
        ),
      );
    }
  }

  // ── Delete confirmation dialog ─────────────────────────────────────────────

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.red.shade600, size: 24),
            const SizedBox(width: 8),
            const Text('Delete?'),
          ],
        ),
        content: Text(
          'Delete "${item.title}"?\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await _doDelete(context, ref);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _doDelete(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(addItemProvider(projectId).notifier)
          .deleteItem(item.id);
      if (context.mounted) {
        _showSnackBar(context, '$_typeName deleted.');
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Delete failed: ${e.toString()}');
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String get _typeName {
    switch (item.type) {
      case ItemType.note:
        return 'Note';
      case ItemType.link:
        return 'Link';
      case ItemType.file:
        return 'File';
    }
  }



  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.withValues(alpha: 0.12),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isSelectionMode) {
            onSelectionToggle?.call();
          } else {
            _handleTap(context);
          }
        },
        onLongPress: () {
          if (!isSelectionMode) {
            onLongPressToggle?.call();
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _ItemTypeIcon(type: item.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (item.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isSelectionMode)
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.blue : Colors.grey[400],
                )
              else
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.black54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      EditItemBottomSheet.show(context, item, projectId);
                    } else if (value == 'delete') {
                      _confirmDelete(context, ref);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: Colors.black87),
                          SizedBox(width: 10),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: Colors.red[600]),
                          const SizedBox(width: 10),
                          Text(
                            'Delete',
                            style: TextStyle(color: Colors.red[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Supporting Widgets ─────────────────────────────────────────────────────

class _ItemTypeIcon extends StatelessWidget {
  final ItemType type;
  const _ItemTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, bg) = switch (type) {
      ItemType.note => (Icons.description_outlined, const Color(0xFFE8F5E9)),
      ItemType.link => (Icons.public, const Color(0xFFE3F2FD)),
      ItemType.file =>
        (Icons.insert_drive_file_outlined, const Color(0xFFFFF3E0)),
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: const Color(0xFF2196F3), size: 22),
    );
  }
}
