import '../../domain/entities/item.dart';

class ItemModel extends Item {
  const ItemModel({
    required super.id,
    required super.projectId,
    required super.type,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
    super.content,
    super.url,
    super.description,
    super.favicon,
    super.fileUrl,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id']?.toString() ?? '',
      projectId: json['project']?.toString() ?? '',
      type: _typeFromString(json['type'] as String?),
      title: json['title'] as String? ?? '',
      content: json['content'] as String?,
      url: json['url'] as String?,
      description: json['description'] as String?,
      favicon: json['favicon'] as String?,
      fileUrl: json['file'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toCreateJson() {
    final body = <String, dynamic>{
      'project': projectId,
      'type': type.name,
      'title': title,
    };
    if (content != null) body['content'] = content;
    if (url != null) body['url'] = url;
    if (description != null) body['description'] = description;
    return body;
  }

  static ItemType _typeFromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'link':
        return ItemType.link;
      case 'file':
        return ItemType.file;
      case 'note':
      default:
        return ItemType.note;
    }
  }
}
