import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_provider.dart';
import '../../../../core/providers/selection_provider.dart';
import '../../domain/entities/project.dart';
import '../widgets/project_card.dart';
import '../../../../shared/widgets/floating_add_button.dart';
import '../widgets/rename_project_dialog.dart';
import 'project_detail_screen.dart';
import 'create_project_sheet.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final projectsAsync = ref.watch(projectsListProvider);
    final selectionState = ref.watch(projectSelectionProvider);
    final selectionNotifier = ref.read(projectSelectionProvider.notifier);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: selectionState.isSelectionMode
            ? AppBar(
                backgroundColor: const Color(0xFFE3F2FD),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => selectionNotifier.clearSelection(),
                ),
                title: Text('${selectionState.selectedIds.length} Selected'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _showDeleteConfirmation(context, ref, selectionState.selectedIds);
                    },
                  ),
                ],
              )
            : AppBar(
                title: const Text(
                  'Projects',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search, size: 28),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 28),
                    onPressed: () {},
                  ),
                ],
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'All'),
                    Tab(text: 'Starred'),
                  ],
                  indicatorColor: Colors.black87,
                  labelColor: Colors.black87,
                  unselectedLabelColor: Colors.grey,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.tab,
                ),
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                titleSpacing: 20,
              ),
        body: projectsAsync.when(
          data: (projects) {
            final starredProjects = projects.where((p) => p.isStarred).toList();

            return TabBarView(
              children: [
                _buildProjectList(context, ref, projects),
                _buildProjectList(context, ref, starredProjects, isStarredTab: true),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    '$err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(projectsListProvider.notifier).loadProjects(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingAddButton(
          onPressed: () => CreateProjectSheet.show(context),
        ),
      ),
    );
  }

  Widget _buildProjectList(BuildContext context, WidgetRef ref, List<Project> projects, {bool isStarredTab = false}) {
    if (projects.isEmpty) {
      return _buildEmptyState(context, isStarredTab: isStarredTab);
    }

    final selectionState = ref.watch(projectSelectionProvider);
    final selectionNotifier = ref.read(projectSelectionProvider.notifier);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        final isSelected = selectionState.selectedIds.contains(project.id);

        return ProjectCard(
          project: project,
          isSelectionMode: selectionState.isSelectionMode,
          isSelected: isSelected,
          onTap: () {
            if (selectionState.isSelectionMode) {
              selectionNotifier.toggleSelection(project.id);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjectDetailScreen(project: project),
                ),
              );
            }
          },
          onLongPress: () {
            if (!selectionState.isSelectionMode) {
              selectionNotifier.toggleSelection(project.id);
            }
          },
          onToggleStar: () {
            ref.read(projectsListProvider.notifier).toggleStar(project.id, !project.isStarred);
          },
          onRename: () {
            RenameProjectDialog.show(context, ref, project);
          },
          onDelete: () {
            _showSingleDeleteConfirmation(context, ref, project);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, {bool isStarredTab = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isStarredTab ? Icons.star_border : Icons.folder_open,
            size: 72,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            isStarredTab ? 'No starred projects' : 'No projects yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isStarredTab ? 'Star projects to see them here' : 'Tap + to create your first project',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Set<String> selectedIds) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Projects'),
        content: Text('Are you sure you want to delete ${selectedIds.length} project(s)? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(projectsListProvider.notifier).deleteMultiple(selectedIds.toList());
              ref.read(projectSelectionProvider.notifier).clearSelection();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSingleDeleteConfirmation(BuildContext context, WidgetRef ref, Project project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "${project.name}"?\n\nThis will permanently delete all enclosed items and cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(projectsListProvider.notifier).deleteProject(project.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
