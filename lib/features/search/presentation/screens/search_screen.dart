import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';
import '../widgets/search_result_tile.dart';
import '../../../projects/presentation/providers/project_provider.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/domain/entities/item.dart';
import '../../../projects/presentation/screens/project_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SearchScreen
//
// ConsumerStatefulWidget to own the TextEditingController + FocusNode
// lifecycle safely. All filtering logic lives in SearchNotifier — this
// widget only calls notifier methods and reads SearchState.
// ─────────────────────────────────────────────────────────────────────────────

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _openProject(BuildContext context, Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(project: project),
      ),
    );
  }

  /// For items, we look up the parent project and open its detail screen.
  void _openItemProject(BuildContext context, Item item) {
    final projects = ref.read(projectsListProvider).valueOrNull ?? [];
    final parent = projects.cast<Project?>().firstWhere(
          (p) => p?.id == item.projectId,
          orElse: () => null,
        );
    if (parent != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(project: parent),
        ),
      );
    }
  }

  // ── Search field ───────────────────────────────────────────────────────────

  void _onQueryChanged(String value) {
    ref.read(searchProvider.notifier).updateQuery(value);
  }

  void _onClear() {
    _controller.clear();
    ref.read(searchProvider.notifier).clearSearch();
    _focusNode.requestFocus();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final theme = Theme.of(context);

    return GestureDetector(
      // Dismiss keyboard when tapping outside the text field.
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // ── AppBar ─────────────────────────────────────────────────────
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              titleSpacing: 20,
              title: const Text(
                'Search',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(64),
                child: _SearchBar(
                  controller: _controller,
                  focusNode: _focusNode,
                  showClear: searchState.hasQuery,
                  onChanged: _onQueryChanged,
                  onClear: _onClear,
                ),
              ),
            ),

            // ── Body ───────────────────────────────────────────────────────
            if (!searchState.hasQuery)
              _IdleSliver()
            else if (searchState.isSearching)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (searchState.totalResults == 0)
              _NoResultsSliver(query: searchState.query)
            else ...[
              // Projects section
              if (searchState.filteredProjects.isNotEmpty) ...[
                _SectionHeaderSliver(
                  label: 'Projects',
                  count: searchState.filteredProjects.length,
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final p = searchState.filteredProjects[i];
                      return SearchResultTile.forProject(
                        project: p,
                        onTap: () => _openProject(context, p),
                      );
                    },
                    childCount: searchState.filteredProjects.length,
                  ),
                ),
              ],

              // Notes section
              if (searchState.filteredNotes.isNotEmpty) ...[
                _SectionHeaderSliver(
                  label: 'Notes',
                  count: searchState.filteredNotes.length,
                ),
                _ItemSectionSliver(
                  items: searchState.filteredNotes,
                  onTap: (item) => _openItemProject(context, item),
                ),
              ],

              // Links section
              if (searchState.filteredLinks.isNotEmpty) ...[
                _SectionHeaderSliver(
                  label: 'Links',
                  count: searchState.filteredLinks.length,
                ),
                _ItemSectionSliver(
                  items: searchState.filteredLinks,
                  onTap: (item) => _openItemProject(context, item),
                ),
              ],

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showClear;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.showClear,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        autofocus: false,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search projects, notes, links…',
          hintStyle: TextStyle(
              color: theme.colorScheme.onSurfaceVariant, fontSize: 15),
          prefixIcon: Icon(Icons.search,
              color: theme.colorScheme.onSurfaceVariant, size: 20),
          suffixIcon: showClear
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: theme.colorScheme.onSurfaceVariant,
                  onPressed: onClear,
                  tooltip: 'Clear',
                )
              : null,
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

/// Section header rendered as a Sliver.
class _SectionHeaderSliver extends StatelessWidget {
  final String label;
  final int count;

  const _SectionHeaderSliver({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
        child: Row(
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2196F3),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2196F3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sliver that builds a list of item result tiles, looking up the project name
/// by reading projectsListProvider directly (no extra network call).
class _ItemSectionSliver extends ConsumerWidget {
  final List<Item> items;
  final void Function(Item) onTap;

  const _ItemSectionSliver({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsListProvider).valueOrNull ?? [];

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final item = items[i];
          final projectName = projects
                  .cast<Project?>()
                  .firstWhere(
                    (p) => p?.id == item.projectId,
                    orElse: () => null,
                  )
                  ?.name ??
              'Unknown project';
          return SearchResultTile.forItem(
            item: item,
            projectName: projectName,
            onTap: () => onTap(item),
          );
        },
        childCount: items.length,
      ),
    );
  }
}

/// Shown when the user hasn't typed anything yet.
class _IdleSliver extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.manage_search_rounded,
                size: 80,
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 20),
            Text(
              'Search everything',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Projects, notes and links all in one place',
              style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when a search returns zero results.
class _NoResultsSliver extends StatelessWidget {
  final String query;
  const _NoResultsSliver({required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 72,
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 20),
            Text(
              'No results for "$query"',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different keyword',
              style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
