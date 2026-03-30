class User {
  final String id;
  final String email;
  final String name;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.createdAt,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^ email.hashCode ^ name.hashCode ^ createdAt.hashCode;
  }
}
