import 'package:flutter/material.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/domain/entities/item.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SearchResultTile
//
// Two named constructors produce two visually-distinct variants:
//   • SearchResultTile.forProject — folder icon, project name + description
//   • SearchResultTile.forItem   — type-specific icon, title + preview + project chip
//
// Both are simple StatelessWidgets — no state, no providers.
// Navigation is handled by the caller (SearchScreen) to keep this widget
// a pure display component.
// ─────────────────────────────────────────────────────────────────────────────

class SearchResultTile extends StatelessWidget {
  final IconData _icon;
  final Color _iconBg;
  final Color _iconColor;
  final String _title;
  final String _subtitle;
  final String? _chipLabel; // project name badge shown on item results
  final VoidCallback _onTap;

  const SearchResultTile._({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? chipLabel,
    required VoidCallback onTap,
  })  : _icon = icon,
        _iconBg = iconBg,
        _iconColor = iconColor,
        _title = title,
        _subtitle = subtitle,
        _chipLabel = chipLabel,
        _onTap = onTap;

  // ── Project variant ────────────────────────────────────────────────────────

  factory SearchResultTile.forProject({
    required Project project,
    required VoidCallback onTap,
  }) {
    return SearchResultTile._(
      icon: Icons.folder_rounded,
      iconBg: const Color(0xFFE8F5E9),
      iconColor: const Color(0xFF43A047),
      title: project.name,
      subtitle: project.description.isNotEmpty
          ? project.description
          : 'No description',
      onTap: onTap,
    );
  }

  // ── Item variant (note or link) ────────────────────────────────────────────

  factory SearchResultTile.forItem({
    required Item item,
    required String projectName,
    required VoidCallback onTap,
  }) {
    final isNote = item.type == ItemType.note;
    return SearchResultTile._(
      icon: isNote ? Icons.description_outlined : Icons.public_rounded,
      iconBg: isNote ? const Color(0xFFF3E5F5) : const Color(0xFFE3F2FD),
      iconColor: isNote ? const Color(0xFF8E24AA) : const Color(0xFF1E88E5),
      title: item.title,
      subtitle: isNote
          ? (item.content?.isNotEmpty == true ? item.content! : 'No content')
          : (item.description?.isNotEmpty == true
              ? item.description!
              : item.url ?? ''),
      chipLabel: projectName,
      onTap: onTap,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Icon badge ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: _iconColor, size: 20),
            ),
            const SizedBox(width: 12),

            // ── Text block ─────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      height: 1.4,
                    ),
                  ),

                  // ── Project chip (items only) ─────────────────────────
                  if (_chipLabel != null) ...[
                    const SizedBox(height: 6),
                    _ProjectChip(label: _chipLabel!),
                  ],
                ],
              ),
            ),

            // ── Chevron ────────────────────────────────────────────────────
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: Colors.grey[350], size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Private helpers ────────────────────────────────────────────────────────

class _ProjectChip extends StatelessWidget {
  final String label;
  const _ProjectChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_outlined, size: 10, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
