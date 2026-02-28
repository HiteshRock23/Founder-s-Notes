import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/item.dart';
import '../providers/project_provider.dart';
import '../widgets/project_header.dart';
import '../widgets/item_tile.dart';
import '../widgets/tab_bar_widget.dart';
import '../../../../shared/widgets/floating_add_button.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import 'add_item_bottom_sheet.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final Project project;

  const ProjectDetailScreen({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(projectItemsProvider(project.id));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(project.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: () {},
            ),
          ],
        ),
        body: itemsAsync.when(
          data: (items) => Column(
            children: [
              ProjectHeader(project: project),
              const TabBarWidget(),
              Expanded(
                child: TabBarView(
                  children: [
                    _ItemsListView(items: items), // All
                    _ItemsListView(
                      items: items.where((i) => i.type == ItemType.note).toList(),
                    ), // Notes
                    _ItemsListView(
                      items: items.where((i) => i.type == ItemType.link).toList(),
                    ), // Links
                    _ItemsListView(
                      items: items.where((i) => i.type == ItemType.file).toList(),
                    ), // Files
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
        bottomNavigationBar: const BottomNavBar(),
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
