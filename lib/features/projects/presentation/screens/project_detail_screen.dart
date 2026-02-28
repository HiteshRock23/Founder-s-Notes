import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/item.dart';
import '../providers/project_provider.dart';
import '../widgets/project_header.dart';
import '../widgets/item_tile.dart';
import '../widgets/tab_bar_widget.dart';
import '../widgets/rename_project_dialog.dart';
import '../../../../shared/widgets/floating_add_button.dart';
import '../../../../core/errors/api_exception.dart';
import 'add_item_bottom_sheet.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final Project project;

  const ProjectDetailScreen({
    super.key,
    required this.project,
  });

  // ── Menu actions ───────────────────────────────────────────────────────────

  void _onMenuSelected(
    BuildContext context,
    WidgetRef ref,
    String value,
  ) {
    switch (value) {
      case 'rename':
        RenameProjectDialog.show(context, ref, project);
      case 'delete':
        _showDeleteConfirmation(context, ref);
    }
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Project?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will permanently delete "${project.name}" and all its notes and links. This cannot be undone.',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    await _deleteProject(context, ref);
  }

  Future<void> _deleteProject(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(projectsListProvider.notifier)
          .deleteProject(project.id);

      if (context.mounted) {
        // Pop back to ProjectsScreen — the project no longer exists.
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${project.name}" deleted'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final msg = e is ApiException
            ? e.message
            : 'Failed to delete project. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the projects list so the AppBar title re-renders if renamed.
    final projects = ref.watch(projectsListProvider).valueOrNull ?? [];
    final liveProject = projects.cast<Project?>().firstWhere(
          (p) => p?.id == project.id,
          orElse: () => null,
        ) ??
        project;

    final itemsAsync = ref.watch(projectItemsProvider(project.id));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(liveProject.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) => _onMenuSelected(context, ref, value),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: Colors.black87),
                      SizedBox(width: 10),
                      Text('Rename'),
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
        body: itemsAsync.when(
          data: (items) => Column(
            children: [
              ProjectHeader(project: liveProject),
              const TabBarWidget(),
              Expanded(
                child: TabBarView(
                  children: [
                    _ItemsListView(items: items),
                    _ItemsListView(
                      items: items
                          .where((i) => i.type == ItemType.note)
                          .toList(),
                    ),
                    _ItemsListView(
                      items: items
                          .where((i) => i.type == ItemType.link)
                          .toList(),
                    ),
                    _ItemsListView(
                      items: items
                          .where((i) => i.type == ItemType.file)
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
        floatingActionButton: FloatingAddButton(
          onPressed: () {
            debugPrint('FAB pressed — projectId: ${project.id}');
            AddItemBottomSheet.show(context, project.id);
          },
        ),
      ),
    );
  }
}

class _ItemsListView extends StatelessWidget {
  final List<Item> items;

  const _ItemsListView({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No items found',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 80),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ItemTile(item: items[index]);
      },
    );
  }
}
