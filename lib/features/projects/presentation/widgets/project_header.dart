import 'package:flutter/material.dart';
import '../../domain/entities/project.dart';

class ProjectHeader extends StatelessWidget {
  final Project project;

  const ProjectHeader({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.star_rounded, // Placeholder for project icon
                size: 40,
                color: Color(0xFF2196F3),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            project.name,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Updated ${_formatDate(project.updatedAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
