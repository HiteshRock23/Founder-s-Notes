import 'package:flutter/material.dart';

class FloatingAddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const FloatingAddButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: const Color(0xFF2196F3),
      elevation: 4,
      shape: const CircleBorder(),
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: 32,
      ),
    );
  }
}
