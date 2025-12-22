import 'dart:ui';

class Tag {
  final String id;
  final String name;
  final Color color;
  final DateTime updatedAt;

  Tag({
    required this.id,
    required this.name,
    required this.color,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) {
    if (other is! Tag) return false;
    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
