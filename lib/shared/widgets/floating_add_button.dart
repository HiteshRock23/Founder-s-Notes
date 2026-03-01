import 'package:flutter/material.dart';

class FloatingAddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const FloatingAddButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: theme.colorScheme.primary,
      elevation: 4,
      shape: const CircleBorder(),
      child: Icon(
        Icons.add,
        color: theme.colorScheme.onPrimary,
        size: 32,
      ),
    );
  }
}
