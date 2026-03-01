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

  Item copyWith({
    String? id,
    String? projectId,
    ItemType? type,
    String? title,
    String? content,
    String? url,
    String? description,
    String? favicon,
    String? fileUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      url: url ?? this.url,
      description: description ?? this.description,
      favicon: favicon ?? this.favicon,
      fileUrl: fileUrl ?? this.fileUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
