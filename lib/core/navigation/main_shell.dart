import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/projects/presentation/screens/projects_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/starred/presentation/screens/starred_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Navigation index provider
//
// Lifted into Riverpod so that any widget tree node can read or mutate the
// active tab without prop-drilling (e.g. a deep-link handler or a push
// notification handler can call `ref.read(shellIndexProvider.notifier).state = 2`).
// ─────────────────────────────────────────────────────────────────────────────

final shellIndexProvider = StateProvider<int>((ref) => 0);

// ─────────────────────────────────────────────────────────────────────────────
// MainShell
//
// Responsibilities:
//   • Own the IndexedStack — one stack frame per root tab.
//   • Render the BottomNavigationBar and forward taps to shellIndexProvider.
//   • NO business logic. NO provider mutations beyond index switching.
//
// Why IndexedStack instead of replacing the widget tree on each tap?
//   • Each child is built once and kept alive in the widget tree.
//   • Scroll position, loaded data, and provider subscriptions survive tab switches.
//   • There are no unnecessary network refetches when the user returns to a tab.
// ─────────────────────────────────────────────────────────────────────────────

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  /// Ordered to match BottomNavigationBar item positions.
  static const List<Widget> _screens = [
    ProjectsScreen(), // index 0
    SearchScreen(),   // index 1
    StarredScreen(),  // index 2
    SettingsScreen(), // index 3
  ];

  static const List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.folder_outlined),
      activeIcon: Icon(Icons.folder),
      label: 'Projects',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.search_outlined),
      activeIcon: Icon(Icons.search),
      label: 'Search',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.star_border_rounded),
      activeIcon: Icon(Icons.star_rounded),
      label: 'Starred',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings_outlined),
      activeIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentIndex = ref.watch(shellIndexProvider);

    return Scaffold(
      // The body is an IndexedStack: all children stay mounted (alive),
      // only the active index is visible. This preserves scroll position,
      // provider state, and already-loaded data across tab switches.
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) =>
            ref.read(shellIndexProvider.notifier).state = index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2196F3),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 8,
        items: _navItems,
      ),
    );
  }
}
