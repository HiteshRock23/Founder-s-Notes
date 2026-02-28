enum ItemType { note, link, file }

class Item {
  final String id;
  final String projectId;
  final ItemType type;
  final String title;

  // Note-specific
  final String? content;

  // Link-specific
  final String? url;
  final String? description;
  final String? favicon;

  // File-specific
  final String? fileUrl;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Item({
    required this.id,
    required this.projectId,
    required this.type,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.content,
    this.url,
    this.description,
    this.favicon,
    this.fileUrl,
  });

  /// Returns the most meaningful subtitle for display in a list tile.
  String get subtitle {
    switch (type) {
      case ItemType.note:
        return content ?? '';
      case ItemType.link:
        return description ?? url ?? '';
      case ItemType.file:
        return fileUrl != null ? 'Tap to view file' : '';
    }
  }
}
