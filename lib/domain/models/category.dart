import 'entry_type.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.iconKey,
    required this.colorValue,
    required this.isBuiltin,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final EntryType type;
  final String iconKey;
  final int colorValue;
  final bool isBuiltin;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category copyWith({
    String? name,
    String? iconKey,
    int? colorValue,
    int? sortOrder,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      type: type,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      isBuiltin: isBuiltin,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
