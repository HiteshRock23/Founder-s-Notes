import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/item.dart';

class ItemTile extends StatelessWidget {
  final Item item;

  const ItemTile({
    super.key,
    required this.item,
  });

  Future<void> _handleTap(BuildContext context) async {
    if (item.type == ItemType.link) {
      final rawUrl = item.url;
      if (rawUrl == null || rawUrl.isEmpty) {
        _showSnackBar(context, 'No URL saved for this link.');
        return;
      }

      final uri = Uri.tryParse(rawUrl);
      if (uri == null) {
        _showSnackBar(context, 'Invalid URL.');
        return;
      }

      final canOpen = await canLaunchUrl(uri);
      if (canOpen) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          _showSnackBar(context, 'Could not open: $rawUrl');
        }
      }
    } else {
      // Notes and files — detail view coming soon
      _showSnackBar(context, 'Detail view coming soon!');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _ItemTypeIcon(type: item.type),
        title: Text(
          item.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: item.subtitle.isNotEmpty
            ? Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              )
            : null,
        trailing: _ItemTypeTrailing(type: item.type),
        onTap: () => _handleTap(context),
      ),
    );
  }
}

// ── Supporting Widgets ─────────────────────────────────────────────────────

class _ItemTypeIcon extends StatelessWidget {
  final ItemType type;
  const _ItemTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, bg) = switch (type) {
      ItemType.note => (Icons.description_outlined, const Color(0xFFE8F5E9)),
      ItemType.link => (Icons.public, const Color(0xFFE3F2FD)),
      ItemType.file => (Icons.insert_drive_file_outlined, const Color(0xFFFFF3E0)),
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: const Color(0xFF2196F3), size: 22),
    );
  }
}

class _ItemTypeTrailing extends StatelessWidget {
  final ItemType type;
  const _ItemTypeTrailing({required this.type});

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      ItemType.note => Icons.chevron_right,
      ItemType.link => Icons.open_in_new,
      ItemType.file => Icons.download_outlined,
    };
    return Icon(icon, color: Colors.grey[400], size: 18);
  }
}
