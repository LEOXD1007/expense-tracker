import 'entry_type.dart';

class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.amountCents,
    required this.type,
    required this.categoryId,
    required this.occurredOn,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int amountCents;
  final EntryType type;
  final String categoryId;

  /// Local calendar date. The time component is ignored.
  final DateTime occurredOn;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  LedgerEntry copyWith({
    int? amountCents,
    EntryType? type,
    String? categoryId,
    DateTime? occurredOn,
    String? note,
    bool clearNote = false,
    DateTime? updatedAt,
  }) {
    return LedgerEntry(
      id: id,
      amountCents: amountCents ?? this.amountCents,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      occurredOn: occurredOn ?? this.occurredOn,
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
