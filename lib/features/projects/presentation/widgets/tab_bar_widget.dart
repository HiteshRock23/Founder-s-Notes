import 'package:flutter/material.dart';

class TabBarWidget extends StatelessWidget {
  const TabBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabBar(
      tabs: [
        Tab(text: 'All'),
        Tab(text: 'Notes'),
        Tab(text: 'Links'),
        Tab(text: 'Files'),
      ],
      isScrollable: false,
    );
  }
}
