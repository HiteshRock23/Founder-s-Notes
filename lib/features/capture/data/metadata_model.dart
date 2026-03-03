class MetadataModel {
  final String status;
  final String? title;
  final String? description;
  final String? favicon;
  final String? image;
  final String? domain;
  final String? finalUrl;
  final String? errorMessage;

  MetadataModel({
    required this.status,
    this.title,
    this.description,
    this.favicon,
    this.image,
    this.domain,
    this.finalUrl,
    this.errorMessage,
  });

  factory MetadataModel.fromJson(Map<String, dynamic> json) {
    return MetadataModel(
      status: json['status'] ?? 'error',
      title: json['title'],
      description: json['description'],
      favicon: json['favicon'],
      image: json['image'],
      domain: json['domain'],
      finalUrl: json['final_url'],
      errorMessage: json['error_message'],
    );
  }
}
